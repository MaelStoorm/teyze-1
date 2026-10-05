# Fatma Teyze'yi Google Play'de yayınlama rehberi

Egemen için adım adım. Sıra önemli: anahtar → AAB → Play Console → dahili test → kapalı test (12 kişi, 14 gün) → üretim.

Bu klasördeki hazır malzemeler:

| Dosya | Play Console'da nereye |
|---|---|
| `aciklama.md` | Uygulama adı, kısa ve tam açıklama (TR + EN), kategori, içerik derecelendirmesi ve veri güvenliği cevapları |
| `ikon-512.png` | Uygulama simgesi (512x512) |
| `one-cikan-1024x500.png` | Öne çıkan grafik (feature graphic) |
| `ekran-1.png` … `ekran-8.png` | Telefon ekran görüntüleri (en fazla 8) |
| `../gizlilik.html` | Gizlilik politikası sayfası (GitHub Pages ile yayınlanır) |

Görselleri yeniden üretmek için: `python3 tools/make_store_art.py --shots <klasör>` (ayrıntı dosyanın başında).

---

## 1. Yükleme anahtarını (upload keystore) oluştur

Play'e yüklenen her AAB bu anahtarla imzalanır. Bir kez oluşturulur, yıllarca kullanılır.

```bash
keytool -genkeypair -v \
  -keystore ~/anahtarlar/teyze-upload.jks \
  -alias teyze-upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

- `keytool` JDK ile gelir (Godot'nun Android dışa aktarımı için zaten JDK 17 gerekiyor).
- Sorulan şifreyi güçlü seç. Ad/şirket sorularına "MaelStoorm Studios", ülke kodu `TR` yazılabilir.
- README'deki eski APK imzalama anahtarı (`--ksAlias teyze`) bundan ayrı kalsın; Play için yeni bir yükleme anahtarı kullan.

### Anahtarı güvende tut

- **Asla depoya koyma.** Dosyayı proje klasörünün dışında tut (yukarıdaki gibi `~/anahtarlar/`). Yine de kazara eklenmesin diye `.gitignore` dosyasına şu satırları eklemek iyi olur:
  ```
  *.jks
  *.keystore
  ```
- `.jks` dosyasını ve şifresini **iki ayrı yerde** yedekle (ör. şifre yöneticisi + şifreli bir USB/bulut klasörü).
- Kaybolursa dünya yıkılmaz: Play App Signing açık olduğu için Play Console'dan "yükleme anahtarını sıfırla" talebi açılabilir, ama birkaç gün sürer. Yine de kaybetmemek en iyisi.

---

## 2. Godot dışa aktarım ayarları (Project > Export > Android)

### Sürüm

- **Version > Code** (`version/code`): Play'e yüklenen her derlemede **bir artmalı**, asla geri gitmez. Şu an 8; Play'e ilk yükleme için ör. `10`.
- **Version > Name** (`version/name`): oyuncunun gördüğü sürüm, ör. `1.0`.
- **Package > Unique Name**: `com.maelstoorm.teyze`. Play'e ilk yüklemeden sonra **değiştirilemez**, şimdi karar ver.
- **Package > Name**: telefondaki simgenin altında görünen ad. Şu an "Teyze"; istersen "Fatma Teyze" yap.

### Release keystore alanları

**Keystore > Release** bölümüne:

- **Release**: `~/anahtarlar/teyze-upload.jks` dosyasının tam yolu
- **Release User**: `teyze-upload` (alias)
- **Release Password**: anahtar şifresi

Godot 4 bu üç değeri `export_presets.cfg`'ye değil `.godot/export_credentials.cfg`'ye yazar; `.godot/` zaten `.gitignore`'da, yani depoya gitmez. Komut satırından derlerken istersen ortam değişkeni de kullanabilirsin:

```bash
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=~/anahtarlar/teyze-upload.jks
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=teyze-upload
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD='...'
```

---

## 3. AAB derle (Play APK değil AAB ister)

Godot 4.3'te AAB, yalnızca **Gradle ile derleme** açıkken üretilebilir. Bunun için projeye Android derleme şablonu kurulur:

1. Godot'ta **Project > Install Android Build Template…** Bu, proje kökünde `android/` klasörünü oluşturur (`.gitignore`'da `/android/` zaten var).
2. Export ayarlarında:
   - **Gradle Build > Use Gradle Build**: açık
   - **Gradle Build > Export Format**: `Export AAB`
   - **Architectures**: `arm64-v8a` ve `armeabi-v7a` açık kalsın (Play 64 bit ister; arm64 zaten açık).
3. Editor Settings > Export > Android'de **Java SDK Path** (JDK 17) ve **Android SDK Path** dolu olmalı. Gradle ilk derlemede internetten bağımlılık indirir, biraz sürer.
4. Dışa aktar:
   ```bash
   godot --headless --export-release "Android" build/teyze.aab
   ```
   (Dosya adı `.aab` ile bitmeli. `build/` ve `*.aab` zaten `.gitignore`'da.)

### Hedef API ve 16 KB uyarısı (önemli)

- Play, yeni uygulamaların güncel bir Android sürümünü hedeflemesini ister (2025'ten beri en az API 35 / Android 15; her yıl Ağustos sonunda bir üst seviyeye çıkar). Godot 4.3 varsayılan olarak API 34 hedefler. Gradle derlemesinde **Gradle Build > Target SDK** alanına Play Console'un istediği değeri yaz (ve Android SDK Manager'dan o platformu kur). Yükleme sırasında Play Console hangi seviyeyi istediğini açıkça söyler.
- Play, Android 15+ hedefleyen uygulamalarda yerel (`.so`) kütüphanelerin **16 KB sayfa boyutunu** desteklemesini de ister. Godot 4.3'ün motor kütüphaneleri buna hazır olmayabilir. AAB'yi yükleyince Play Console "App bundle explorer"da veya yükleme sırasında uyarı verirse en kolay çözüm projeyi **Godot 4.5 veya üstüne** taşımaktır (4.5 hem API 35'i hem 16 KB'yi destekler). Önce 4.3 ile deneyip uyarıya bakmak yeterli.

---

## 4. Play Console'da uygulamayı oluştur

1. https://play.google.com/console > **Uygulama oluştur**
   - Uygulama adı: `Fatma Teyze: Mahalle Oyunu`
   - Varsayılan dil: Türkçe (tr-TR)
   - Uygulama mı oyun mu: **Oyun**
   - Ücretsiz mi ücretli mi: **Ücretsiz** (sonradan ücretliye çevrilemez; uygulama içi satın alma yine eklenebilir)
   - Beyanlar: geliştirici politikaları ve ABD ihracat yasaları kutuları
2. **Play App Signing**: ilk AAB yüklenirken varsayılan olarak "Google tarafından oluşturulan anahtar" seçilidir; böyle bırak. Google uygulamayı kendi uygulama imzalama anahtarıyla imzalar, sen yalnızca yükleme anahtarını (adım 1) tutarsın.

---

## 5. Önce dahili test (internal testing)

1. **Test > Dahili test > Yeni sürüm oluştur**, `build/teyze.aab`'yi yükle.
2. Sürüm notu (tr-TR), ör.: `İlk test sürümü: mahalle, pazar, bostan, tavla, çay ve Evim.`
3. **Testçiler** sekmesinde bir e-posta listesi oluştur (kendin + birkaç kişi, en fazla 100).
4. Paylaşılan katılım bağlantısıyla testçiler Play Store'dan yükler. Dahili test inceleme beklemeden dakikalar içinde açılır.
5. Kendi telefonunda kontrol et: simge, ad, yatay ekran, kaydın uygulama kapanınca korunması, yazı boyutu ayarı.

---

## 6. Mağaza girişi (Store listing)

**Büyüt > Mağazada görünüm > Ana mağaza girişi** (`aciklama.md`'den kopyala):

| Alan | Kaynak |
|---|---|
| Uygulama adı (30) | `aciklama.md` > Türkçe > Uygulama adı |
| Kısa açıklama (80) | `aciklama.md` > Türkçe > Kısa açıklama |
| Tam açıklama (4000) | `aciklama.md` > Türkçe > Tam açıklama |
| Uygulama simgesi | `ikon-512.png` |
| Öne çıkan grafik | `one-cikan-1024x500.png` |
| Telefon ekran görüntüleri | `ekran-1.png` … `ekran-8.png` (sırayla) |
| Tablet ekran görüntüleri | İsteğe bağlı; aynı dosyalar 7" ve 10" alanına da yüklenebilir |

İngilizce için: aynı sayfada **Çeviri ekle > English (United States) – en-US** ve `aciklama.md` > English bölümü.

**Mağaza ayarları** sayfasında: kategori **Gündelik (Casual)**, etiketler `aciklama.md`'deki liste, iletişim e-postası (zorunlu, herkese görünür) ve web sitesi.

---

## 7. Uygulama içeriği beyanları

**Politika ve programlar > Uygulama içeriği** altındaki her kart doldurulmadan üretime çıkılamaz:

- **Gizlilik politikası**: `https://maelstoorm.github.io/teyze-1/gizlilik.html` (önce adım 9'daki GitHub Pages'i aç ve bağlantının açıldığını kontrol et).
- **Reklamlar**: Hayır, reklam yok.
- **Uygulama erişimi**: Tüm işlevler kısıtlama olmadan kullanılabilir.
- **İçerik derecelendirmesi**: IARC anketi, cevaplar `aciklama.md` > İçerik derecelendirmesi. Tavla bahissiz bir masa oyunudur, kumar sorularına "Hayır".
- **Hedef kitle**: yaş grupları, `aciklama.md`'deki nota bak (13 altı seçilirse "Aileler" politikası devreye girer).
- **Veri güvenliği**: "Veri toplanıyor veya paylaşılıyor mu?" > **Hayır**. Ayrıntı `aciklama.md` > Veri güvenliği.
- Haber, sağlık, devlet, finans vb. diğer kartlar: Hayır.

---

## 8. Kapalı test: 12 testçi, 14 gün (yeni kişisel hesaplar için zorunlu)

13 Kasım 2023'ten sonra açılmış **kişisel** geliştirici hesaplarında üretime başvurmadan önce:

- Bir **kapalı test** (Test > Kapalı test) sürümü yayınlanmalı,
- **En az 12 testçi** teste katılmış (opt-in) olmalı,
- Bu 12 kişi **kesintisiz en az 14 gün** testte kalmalı.

Pratik ipuçları:

- 15-20 kişi davet et; biri çıkarsa sayı 12'nin altına düşmesin.
- Testçiler Google hesabıyla katılım bağlantısını açıp "Test kullanıcısı ol" demeli, sonra oyunu Play'den yüklemeli. Ara ara oynamaları ve geri bildirim vermeleri iyi olur; Google başvuruda test sırasında neler öğrendiğini ve neyi düzelttiğini sorar.
- Kapalı test sürümü Google incelemesinden geçer (birkaç saat ile birkaç gün).
- 14 gün dolunca **Kontrol paneli > Üretim erişimi için başvur**. Sorulara dürüstçe cevap ver (kaç testçi, nasıl geri bildirim aldın, ne değiştirdin).
- Onaydan sonra **Üretim > Yeni sürüm** ile aynı veya yeni bir AAB'yi (version code artırılmış) yayınla, ülke olarak Türkiye (ve istersen diğerleri) seç.

---

## 9. Gizlilik sayfası için GitHub Pages'i aç

1. GitHub'da `MaelStoorm/teyze-1` > **Settings > Pages**.
2. **Build and deployment > Source**: `GitHub Actions` (aynı ayar oyunun web sürümünü de yayınlar).
3. **Actions** sekmesinde "Web sürümü" iş akışı bitince şu adres açılmalı: https://maelstoorm.github.io/teyze-1/gizlilik.html
4. Bu adresi Play Console'daki gizlilik politikası alanına yapıştır.

Not: `docs/` altındaki dosyalar (mağaza klasörü hariç) aynı sitede herkese açık olur. Depo zaten herkese açık olduğu için sorun değil; gizli bir şey (anahtar, şifre) bu klasöre asla konmamalı.

---

## Kısa kontrol listesi

- [ ] `teyze-upload.jks` oluşturuldu, iki yerde yedeklendi, depoda değil
- [ ] Export: Gradle build açık, format AAB, release keystore dolu, version code artırıldı
- [ ] Hedef API Play'in istediği seviyede; 16 KB uyarısı yok (yoksa Godot 4.5+)
- [ ] GitHub Pages açık, gizlilik adresi çalışıyor
- [ ] Mağaza girişi (TR + EN), simge, öne çıkan grafik, 8 ekran görüntüsü yüklendi
- [ ] Uygulama içeriği kartlarının hepsi yeşil
- [ ] Dahili testte telefonda denendi
- [ ] Kapalı test: 12+ testçi, 14 gün
- [ ] Üretim erişimi başvurusu, ardından üretim sürümü
