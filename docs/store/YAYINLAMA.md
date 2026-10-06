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

## 1. Yükleme anahtarı (upload key)

Play'e yüklenen her AAB bu anahtarla imzalanır. 6 Ekim 2026'da oluşturuldu:

- Dosya: proje klasöründe `.keys/teyze-upload.jks` (PKCS12, RSA 4096, alias `teyze-upload`)
- Şifre: aynı klasörde `.keys/teyze-upload-BILGI.txt`
- Sertifika SHA-256: `42:2A:76:34:14:48:4D:C7:11:93:F5:B0:9C:C2:0A:70:CB:DF:CD:E7:38:A9:EC:18:3B:CE:3A:AC:C5:AD:D3:10`

### Anahtarı güvende tut

- **Asla depoya koyma.** `.gitignore` zaten `*.jks` ve `*.keystore` dosyalarını dışarıda tutar.
- `.jks` dosyasını ve şifresini **iki ayrı yerde** yedekle (ör. şifre yöneticisi + bilgisayarda şifreli bir klasör).
- Play App Signing açık olduğu için anahtar kaybolursa Play Console'dan "yükleme anahtarını sıfırla" talebi açılabilir, ama birkaç gün sürer.
- Eski `teyze-test.keystore` yalnızca elle kurulan APK'lar içindir; Play'de kullanılmaz.

---

## 2. Sürüm numarası

`export_presets.cfg` içinde:

- `version/code`: Play'e her yüklemede **bir artmalı**, asla geri gitmez. İlk Play yüklemesi `10` (1.0).
- `version/name`: oyuncunun gördüğü sürüm, ör. `1.0`.
- `package/unique_name`: `com.maelstoorm.teyze`. Play'e ilk yüklemeden sonra **değiştirilemez**.

---

## 3. AAB'yi al ve imzala (Play APK değil AAB ister)

Proje **Godot 4.5.2** kullanır. Play'in iki şartı için:

- **16 KB sayfa boyutu**: Godot 4.5'in Android kütüphaneleri 16 KB hizalıdır (4.3'ünkiler değildi).
- **Hedef API 36** (Android 16): 31 Ağustos 2026'dan beri yeni uygulamalar ve güncellemeler için zorunlu. `export_presets.cfg` içinde `gradle_build/target_sdk="36"` (en düşük sürüm `gradle_build/min_sdk="24"`, Android 7.0). Ağustos 2027'de muhtemelen 37 istenecek: o zaman bu değeri `37` yap.

AAB'yi GitHub derler, bilgisayarda Godot ya da Android SDK gerekmez:

- `main` dalına her gönderimde **Actions > Android sürümü** iş akışı (`.github/workflows/android.yml`) oyunu Godot'nun Gradle derlemesiyle dışa aktarır (arm64-v8a + armeabi-v7a) ve `tools/aab_denetle.py` ile paket adını, sürüm kodunu, SDK sürümlerini ve 16 KB hizalamayı kontrol eder.
- Sonuç **`builds`** dalına konur: `fatma-teyze-unsigned.aab` (imzasız) ve hangi commit'ten üretildiğini yazan `commit.txt`. Derleme bozulursa aynı dala `build-log.txt` yazılır.
- Elle çalıştırmak için: **Actions > Android sürümü > Run workflow**.

İndir ve yükleme anahtarıyla imzala (Java'daki `jarsigner` yeter):

```bash
# 1. İndir (ya da GitHub'da builds dalında dosyayı aç > "Download raw file")
curl -L -o fatma-teyze-unsigned.aab \
    https://github.com/MaelStoorm/teyze-1/raw/builds/fatma-teyze-unsigned.aab

# 2. İmzalı kopyayı hazırla ve yükleme anahtarıyla imzala (şifreyi sorar)
cp fatma-teyze-unsigned.aab fatma-teyze-10.aab
jarsigner -sigalg SHA256withRSA -digestalg SHA-256 \
    -keystore .keys/teyze-upload.jks fatma-teyze-10.aab teyze-upload

# 3. Kontrol: "jar verified." yazmalı
jarsigner -verify fatma-teyze-10.aab
```

Play Console'a `fatma-teyze-10.aab` yüklenir (dosya adındaki sayı sürüm kodudur, sadece düzen için).

Yerelde derlemek istersen: Godot 4.5.2 + export şablonları, Editor Settings'te Android SDK ve Java 17 yolu, **Project > Install Android Build Template**, sonra `godot --headless --export-release Android build/fatma-teyze-unsigned.aab`.

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

1. **Test > Dahili test > Yeni sürüm oluştur**, imzalı AAB'yi (ör. `fatma-teyze-10.aab`) yükle.
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

- **Gizlilik politikası**: `https://maelstoorm.github.io/teyze-1/gizlilik.html` (6 Ekim 2026'da açıldığı kontrol edildi).
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

- [ ] `teyze-upload.jks` ve şifresi iki yerde yedeklendi, depoda değil
- [ ] version code artırıldı, AAB `builds` dalından indirildi ve yükleme anahtarıyla imzalandı
- [x] GitHub Pages açık, gizlilik adresi çalışıyor
- [ ] Mağaza girişi (TR + EN), simge, öne çıkan grafik, 8 ekran görüntüsü yüklendi
- [ ] Uygulama içeriği kartlarının hepsi yeşil
- [ ] Dahili testte telefonda denendi
- [ ] Kapalı test: 12+ testçi, 14 gün
- [ ] Üretim erişimi başvurusu, ardından üretim sürümü
