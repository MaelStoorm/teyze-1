#!/usr/bin/env python3
"""Google Play mağaza görselleri: ikon, öne çıkan görsel ve ekran görüntüleri.

Kullanım (depo kökünden):
    python3 -m pip install pillow            # gerekirse
    # 1) Ekran görüntülerini al. Oyun telefonun saatine bakar: TZ'yi, yerel saat öğlen olacak
    #    ve yağmursuz bir gün denk gelecek şekilde ayarla (aşağıdaki değer bir örnek):
    TZ="UTC+11" xvfb-run -a -s "-screen 0 2300x1200x24" godot --resolution 2080x960 --path . -- --shots=/tmp/shots
    # 2) Görselleri üret:
    python3 tools/make_store_art.py --shots /tmp/shots [--godot /yol/godot] [--font /yol/font.ttf]

Çıktılar docs/store/ altına yazılır:
    ikon-512.png               512x512, köşeleri dolu (Play maskeyi kendisi uygular)
    one-cikan-1024x500.png     öne çıkan görsel (feature graphic)
    ekran-1.png .. ekran-8.png oyun görüntüsü + üstte kısa Türkçe başlık bandı. 2080x960 alınan
                               görüntü 2080x1080 olur (Play: kısa kenar >= 1080 önerilir, oran <= 2:1;
                               2080x960 tek başına 2:1 sınırını aşar, bant bunu düzeltir)

Yazı tipi: oyun Godot'nun gömülü varsayılan yazısını (Open Sans SemiBold) kullanır. --godot
verilirse (ya da PATH'te godot varsa) yazı tipi motor dosyasından çıkarılıp build/ altına
konur (fonttools + brotli gerekir). Olmazsa DejaVu Sans Bold kullanılır.
"""

from __future__ import annotations

import argparse
import math
import os
import shutil
import struct
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "store")
BRAND = os.path.join(ROOT, "assets", "brand")
FONT_CACHE = os.path.join(ROOT, "build", "store_fonts", "OpenSans-SemiBold.ttf")
FALLBACK_FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

# Sıcak, alaturka renkler (oyunun arayüzüyle uyumlu)
INK = (59, 42, 32)
CREAM = (255, 246, 228)
RED = (200, 69, 47)
ORANGE = (232, 128, 44)
SAFFRON = (245, 184, 66)
TEAL = (38, 120, 128)
GREEN = (79, 138, 91)

# Seçilen 8 ekran: (tur dosyası, başlık)
SHOTS = [
    ("2_gorev.png", "Fatma Teyze'nin işlerine yardım et"),
    ("0_mahalle.png", "Yaşayan, sıcacık bir mahalle"),
    ("2_pazar.png", "Pazarda listeyi tamamla"),
    ("2_bostan_hasat.png", "Bostanını ek, ertesi gün topla"),
    ("8_evim.png", "Kurabiyelerinle evini döşe"),
    ("8_tavla.png", "Ahmet Amca'yla bir el tavla"),
    ("8_cay.png", "Filiz Teyze'yle çay demle"),
    ("1_takvim_7.png", "Her gün hediye, 7. gün sürpriz"),
]


# --- yazı tipi -------------------------------------------------------------------

def _extract_godot_font(godot: str) -> str | None:
    """Godot ikili dosyasındaki gömülü WOFF2 yazılar arasından Open Sans SemiBold'u çıkarır."""
    try:
        from fontTools.ttLib import TTFont  # brotli de gerekir
    except ImportError:
        print("  fonttools yok, Godot yazısı çıkarılamadı (pip install fonttools brotli)")
        return None
    import io

    data = open(godot, "rb").read()
    i = 0
    while True:
        i = data.find(b"wOF2", i)
        if i < 0:
            return None
        length = struct.unpack(">I", data[i + 8:i + 12])[0]
        if 1000 < length < 5_000_000:
            try:
                font = TTFont(io.BytesIO(data[i:i + length]))
                if font["name"].getDebugName(4) == "Open Sans SemiBold":
                    font.flavor = None
                    cache_dir = os.path.dirname(FONT_CACHE)
                    os.makedirs(cache_dir, exist_ok=True)
                    # Godot bu klasörü içe aktarmasın (yoksa yazı tipi APK'ya girer)
                    open(os.path.join(cache_dir, ".gdignore"), "w").close()
                    font.save(FONT_CACHE)
                    return FONT_CACHE
            except Exception:
                pass
        i += 4


def find_font(arg_font: str | None, arg_godot: str | None) -> str:
    if arg_font:
        return arg_font
    if os.path.exists(FONT_CACHE):
        return FONT_CACHE
    godot = arg_godot or os.environ.get("GODOT") or shutil.which("godot")
    if godot and os.path.exists(godot):
        got = _extract_godot_font(godot)
        if got:
            return got
    return FALLBACK_FONT


# --- yardımcılar -----------------------------------------------------------------

def cover(im: Image.Image, w: int, h: int, focus_y: float = 0.5) -> Image.Image:
    """Görüntüyü w x h alanı tamamen kaplayacak şekilde ölçekleyip kırpar."""
    s = max(w / im.width, h / im.height)
    im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    x = (im.width - w) // 2
    y = round((im.height - h) * focus_y)
    return im.crop((x, y, x + w, y + h))


def outlined_text(d: ImageDraw.ImageDraw, xy, text, font, fill, stroke, width, anchor="la"):
    d.text(xy, text, font=font, fill=fill, stroke_width=width, stroke_fill=stroke, anchor=anchor)


def motif_strip(w: int, h: int) -> Image.Image:
    """Çini/kilim esintili tekrar eden şerit: krem zemin üstünde baklava ve noktalar."""
    strip = Image.new("RGBA", (w, h), RED + (255,))
    d = ImageDraw.Draw(strip)
    step = h * 2
    for i in range(-1, w // step + 2):
        cx = i * step + step // 2
        d.polygon([(cx, 2), (cx + h // 2 + 2, h // 2), (cx, h - 2), (cx - h // 2 - 2, h // 2)], fill=CREAM)
        d.polygon([(cx, h * 0.3), (cx + h * 0.22, h / 2), (cx, h * 0.7), (cx - h * 0.22, h / 2)], fill=TEAL)
        mx = cx + step // 2
        r = max(2, h // 7)
        d.ellipse((mx - r, h / 2 - r, mx + r, h / 2 + r), fill=SAFFRON)
    return strip


def sunburst(size: int, c1, c2, rays: int = 20) -> Image.Image:
    im = Image.new("RGBA", (size, size), c1 + (255,))
    d = ImageDraw.Draw(im)
    cx = cy = size / 2
    R = size
    for k in range(rays):
        a0 = 2 * math.pi * k / rays
        a1 = a0 + math.pi / rays
        d.polygon([(cx, cy), (cx + R * math.cos(a0), cy + R * math.sin(a0)),
                   (cx + R * math.cos(a1), cy + R * math.sin(a1))], fill=c2 + (255,))
    return im


def radial_mask(size: int, inner: float = 0.35) -> Image.Image:
    """Ortası opak, kenara doğru yumuşakça kaybolan dairesel maske."""
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    steps = 60
    for k in range(steps):
        t = k / steps
        r = size / 2 * (1 - t)
        v = 255 if (1 - t) <= inner else round(255 * (1 - ((1 - t) - inner) / (1 - inner)) ** 0.8)
        d.ellipse((size / 2 - r, size / 2 - r, size / 2 + r, size / 2 + r), fill=v)
    return m.filter(ImageFilter.GaussianBlur(size / 40))


# --- ikon ------------------------------------------------------------------------

def make_icon() -> None:
    """Play ikonu: tam kare, şeffaf köşe yok. Uygulama simgesinin köşeleri arka plan ışınlarıyla dolar."""
    bg = Image.open(os.path.join(BRAND, "icon_bg.png")).convert("RGBA").resize((512, 512), Image.LANCZOS)
    icon = Image.open(os.path.join(ROOT, "icon.png")).convert("RGBA").resize((512, 512), Image.LANCZOS)
    bg.alpha_composite(icon)
    bg.convert("RGB").save(os.path.join(OUT, "ikon-512.png"), optimize=True)


# --- öne çıkan görsel -------------------------------------------------------------

def make_feature(font_path: str, shots: str | None) -> None:
    W, H = 1024, 500
    src = None
    for name in ("2_evler.png", "0_mahalle.png", "7_aksam.png"):
        if shots and os.path.exists(os.path.join(shots, name)):
            src = os.path.join(shots, name)
            break
    if src:
        shot = Image.open(src).convert("RGB")
        # Üstteki gösterge ve alttaki düğmeler görünmesin: ekranın orta şeridini al
        sw, sh_ = shot.size
        shot = shot.crop((round(sw * 0.2), round(sh_ * 0.24), round(sw * 0.97), round(sh_ * 0.78)))
        base = cover(shot, W, H, 0.5).filter(ImageFilter.GaussianBlur(2.5))
    else:
        base = Image.new("RGB", (W, H), GREEN)
    canvas = base.convert("RGBA")

    # Soldan sağa sıcak turuncu perde: yazı okunsun, sağda mahalle görünsün
    grad = Image.new("RGBA", (W, H))
    gd = ImageDraw.Draw(grad)
    for x in range(W):
        t = x / W
        a = 235 if t < 0.42 else max(0, round(235 * (1 - (t - 0.42) / 0.38)))
        col = tuple(round(ORANGE[i] * (1 - t * 0.6) + SAFFRON[i] * t * 0.6) for i in range(3))
        gd.line([(x, 0), (x, H)], fill=col + (a,))
    canvas.alpha_composite(grad)

    # Teyzenin arkasında güneş ışınları (uygulama simgesindeki gibi)
    burst_size = 640
    burst = sunburst(burst_size, SAFFRON, (250, 206, 110))
    burst.putalpha(radial_mask(burst_size, 0.25).point(lambda v: round(v * 0.85)))
    canvas.alpha_composite(burst, (W - burst_size // 2 - 230, H // 2 - burst_size // 2 + 10))

    # Fatma Teyze portresi: alt kenara oturur
    por = Image.open(os.path.join(BRAND, "teyze_portre.png")).convert("RGBA")
    ph = 470
    por = por.resize((ph, ph), Image.LANCZOS)
    shadow = Image.new("RGBA", por.size, (0, 0, 0, 0))
    shadow.putalpha(por.getchannel("A").point(lambda v: v * 0.35))
    shadow = shadow.filter(ImageFilter.GaussianBlur(10))
    px, py = W - ph - 40, H - ph + 6
    canvas.alpha_composite(shadow, (px + 8, py + 6))
    canvas.alpha_composite(por, (px, py))

    # Alaturka şeritler
    strip_h = 16
    canvas.alpha_composite(motif_strip(W, strip_h), (0, H - strip_h))

    d = ImageDraw.Draw(canvas)
    title_font = ImageFont.truetype(font_path, 104)
    tag_font = ImageFont.truetype(font_path, 38)
    small_font = ImageFont.truetype(font_path, 22)

    tx = 56
    # yumuşak gölge
    sh = Image.new("RGBA", (W, H))
    sd = ImageDraw.Draw(sh)
    sd.text((tx + 4, 110 + 6), "Fatma", font=title_font, fill=(60, 25, 10, 150))
    sd.text((tx + 4, 222 + 6), "Teyze", font=title_font, fill=(60, 25, 10, 150))
    canvas.alpha_composite(sh.filter(ImageFilter.GaussianBlur(5)))
    outlined_text(d, (tx, 110), "Fatma", title_font, CREAM, INK, 7)
    outlined_text(d, (tx, 222), "Teyze", title_font, CREAM, INK, 7)

    # Slogan, koyu kahve hap içinde
    tag = "Mahallenin en tatlı işleri"
    tb = d.textbbox((0, 0), tag, font=tag_font)
    tw, th = tb[2] - tb[0], tb[3] - tb[1]
    pill = (tx - 2, 358, tx + tw + 36, 358 + th + 26)
    d.rounded_rectangle(pill, radius=(pill[3] - pill[1]) // 2, fill=INK)
    d.text((tx + 17, 358 + 13 - tb[1]), tag, font=tag_font, fill=CREAM)

    d.text((tx + 2, 60), "MaelStoorm Studios", font=small_font, fill=CREAM + (235,))

    canvas.convert("RGB").save(os.path.join(OUT, "one-cikan-1024x500.png"), optimize=True)


# --- ekran görüntüleri ------------------------------------------------------------

def make_screens(font_path: str, shots: str) -> None:
    """Oyun görüntüsünü bozmadan üstüne başlık bandı ekler.

    Band yüksekliği görüntü yüksekliğinin 1/8'i (en az 2:1 oranı sağlayacak kadar): 2080x960 tur
    görüntüsü 2080x1080 olur, 1560x720 olan 1560x810 olur.
    """
    for n, (name, caption) in enumerate(SHOTS, 1):
        path = os.path.join(shots, name)
        if not os.path.exists(path):
            print(f"  eksik: {name}, ekran-{n} atlandı")
            continue
        shot = Image.open(path).convert("RGB")
        sw, sh_ = shot.size
        band = max(round(sh_ / 8), math.ceil(sw / 2) - sh_)
        motif_h = max(8, band // 9)
        cap_font = ImageFont.truetype(font_path, round(band * 0.49))
        W, H = sw, sh_ + band
        im = Image.new("RGB", (W, H), CREAM)
        im.paste(shot, (0, band))
        im.paste(motif_strip(W, motif_h).convert("RGB"), (0, band - motif_h))
        d = ImageDraw.Draw(im)
        d.text((W // 2, (band - motif_h) // 2 + 2), caption, font=cap_font, fill=INK, anchor="mm")
        im.save(os.path.join(OUT, f"ekran-{n}.png"), optimize=True)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--shots", help="--shots ile alınmış ekran görüntüsü klasörü")
    ap.add_argument("--godot", help="Godot 4.3 ikili dosyası (yazı tipini çıkarmak için)")
    ap.add_argument("--font", help="Kullanılacak .ttf (verilmezse oyunun yazısı aranır)")
    args = ap.parse_args()

    os.makedirs(OUT, exist_ok=True)
    font = find_font(args.font, args.godot)
    print("yazı tipi:", font)
    make_icon()
    print("ikon-512.png")
    make_feature(font, args.shots)
    print("one-cikan-1024x500.png")
    if args.shots:
        make_screens(font, args.shots)
        print("ekran-1..8.png")
    else:
        print("--shots verilmedi, ekran görüntüleri atlandı")
    return 0


if __name__ == "__main__":
    sys.exit(main())
