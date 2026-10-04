# Teyze

Metroda, otobüste, iki durak arasında oynanan kısa görevli bir mahalle oyunu.
Fatma Teyze her gün sana küçük işler verir; her iş 1-3 dakikalık bir mini oyundur.

## Şu an oyunda olanlar (prototip)

- **Mahalle (low-poly 3D):** Cumbalı teyze evi, komşu evi, pazar tezgahı, bank, ağaçlar. Teyzeye dokun, görevi al.
- **Pazar:** Teyzenin listesindeki ürünleri tezgahtan seç.
- **Komşuya Haber:** Teyzenin sözünü aklında tut, komşuya sırasıyla anlat.
- **Kayıp Kedi:** Pamuk saklandı; "miyav" ipuçlarıyla bul.
- **Yemek (Sv 2):** Tarifin malzemelerini tencereye koy, sonra dokunarak karıştır. Menemen, Mercimek Çorbası, Sütlaç.
- **Altın Günü (Sv 3):** Filiz, Miyase ve Hülya Teyze'ye (Sv 5'te Nermin Hanım da) uğra, sevdikleri ikramı ver, çeyrek altınlarını topla.
- **Seviyeler:** Her görev 10 tecrübe. Seviye atladıkça yeni görevler açılır, görevler biraz zorlaşır, Sv 4'te günde 4 görev olur.
- **Dükkan:** Kurabiyelerle kalıcı perkler: Pamuk'un Zili, Not Defteri, Pazar Filesi, Bakır Kepçe, Altın Kesesi, Teyzenin Duası, Dolu Takvim.
- Her görev 3 kurabiye (+ perkler). İlerleme telefona kaydedilir, internet gerekmez.
- Süre baskısı yok, yanlışta ceza yok, büyük yazı ve butonlar.

## Çalıştırma

1. [Godot 4.3](https://godotengine.org/download) indir.
2. Godot'ta "Import" ile bu klasördeki `project.godot` dosyasını aç.
3. F5 ile çalıştır. Ekran telefon gibi dikeydir (360x640).

## Geliştirme

- 3D modeller `scripts/models.gd` içinde Godot'nun hazır şekilleriyle kod ile kurulur; dış model dosyası yok.
- Görev ekranlarındaki ikonlar `tools/make_icons.py` ile çizilir: `python3 tools/make_icons.py` (Pillow gerekir).
- Altı günü otomatik oynayan test: `godot --headless -s tools/flow_test.gd`
- Ekran görüntüleri: `godot -- --shots=/klasor/yolu`
- Yeni görev eklemek: `scripts/errands.gd` içine metni, `scripts/minigames/` içine mini oyunu ekle.

## Sıradaki adımlar

- Android dışa aktarma (APK) ayarları
- Ses ve müzik
- Kurabiyelerle teyzenin evini ve mahalleyi güzelleştirme
- Gerçek parayla satın alma (Google Play hesabı onaylandıktan sonra)
- Daha fazla görev türü
