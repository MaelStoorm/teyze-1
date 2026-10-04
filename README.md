# Teyze

Metroda, otobüste, iki durak arasında oynanan kısa görevli bir mahalle oyunu.
Fatma Teyze her gün sana küçük işler verir; her iş 1-3 dakikalık bir mini oyundur.

## Şu an oyunda olanlar (prototip)

- **Mahalle:** Teyzenin evi, komşu evi, pazar tezgahı. Teyzeye dokun, görevi al.
- **Pazar:** Teyzenin listesindeki ürünleri tezgahtan seç.
- **Komşuya Haber:** Teyzenin sözünü aklında tut, komşuya sırasıyla anlat.
- **Kayıp Kedi:** Pamuk saklandı; "miyav" ipuçlarıyla bul.
- Günde 3 görev, her görev 3 kurabiye. İlerleme telefona kaydedilir, internet gerekmez.
- Süre baskısı yok, yanlışta ceza yok, büyük yazı ve butonlar.

## Çalıştırma

1. [Godot 4.3](https://godotengine.org/download) indir.
2. Godot'ta "Import" ile bu klasördeki `project.godot` dosyasını aç.
3. F5 ile çalıştır. Ekran telefon gibi dikeydir (360x640).

## Geliştirme

- Sprite'lar `tools/make_sprites.py` içindeki ASCII çizimlerden üretilir:
  `python3 tools/make_sprites.py` (Pillow gerekir).
- Bir günü otomatik oynayan test: `godot --headless -s tools/flow_test.gd`
- Ekran görüntüleri: `godot -- --shots=/klasor/yolu`
- Yeni görev eklemek: `scripts/errands.gd` içine metni, `scripts/minigames/` içine mini oyunu ekle.

## Sıradaki adımlar

- Android dışa aktarma (APK) ayarları
- Ses ve müzik
- Kurabiyelerle teyzenin evini ve mahalleyi güzelleştirme
- Daha fazla görev türü
