"""Oyun simgesi: güneşli turuncu zeminde Fatma Teyze'nin 3D portresi.

Run: python3 tools/make_app_icon.py   (needs pillow)
Önce portre çizilmeli: godot --path . -s tools/render_portrait.gd
Çıktılar: icon.png (512), assets/brand/icon_fg.png ve icon_bg.png (Android
uyarlanabilir simge, 432).
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
BRAND = ROOT / "assets" / "brand"


def background(size):
    img = Image.new("RGBA", (size, size))
    d = ImageDraw.Draw(img)
    top, bottom = (255, 214, 102), (247, 140, 64)
    for y in range(size):
        k = y / (size - 1)
        d.line((0, y, size, y), fill=tuple(int(a + (b - a) * k) for a, b in zip(top, bottom)) + (255,))
    # güneş ışınları
    rays = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rays)
    c = (size * 0.5, size * 0.42)
    for i in range(16):
        a0 = i * 2 * math.pi / 16
        a1 = a0 + math.pi / 16
        r = size * 1.2
        rd.polygon([c, (c[0] + math.cos(a0) * r, c[1] + math.sin(a0) * r), (c[0] + math.cos(a1) * r, c[1] + math.sin(a1) * r)], fill=(255, 255, 255, 38))
    img.alpha_composite(rays)
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((size * 0.18, size * 0.1, size * 0.82, size * 0.74), fill=(255, 250, 220, 120))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(size * 0.06)))
    return img


def portrait(size):
    p = Image.open(BRAND / "teyze_portre.png").convert("RGBA")
    p = p.crop((112, 0, 912, 800))  # baş ve omuzlar
    p = p.resize((size, size), Image.LANCZOS)
    # hafif koyu dış çizgi ve gölge, oyuncak gibi dursun
    alpha = p.split()[3]
    shadow = Image.new("RGBA", p.size, (90, 40, 20, 0))
    shadow.putalpha(alpha.filter(ImageFilter.GaussianBlur(size * 0.025)).point(lambda v: int(v * 0.5)))
    out = Image.new("RGBA", p.size, (0, 0, 0, 0))
    out.alpha_composite(shadow, (0, int(size * 0.02)))
    out.alpha_composite(p)
    return out


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, img.size[0] - 1, img.size[1] - 1), radius, fill=255)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def main():
    s = 512
    icon = background(s)
    face = portrait(int(s * 0.8))
    icon.alpha_composite(face, ((s - face.size[0]) // 2, int(s * 0.17)))
    cookie = Image.open(ROOT / "assets" / "icons" / "kurabiye.png").convert("RGBA").resize((int(s * 0.3),) * 2, Image.LANCZOS)
    icon.alpha_composite(cookie, (int(s * 0.66), int(s * 0.64)))
    rounded(icon, int(s * 0.2)).save(ROOT / "icon.png")
    # uyarlanabilir simge: ön plan güvenli alanda (ortadaki %66)
    a = 432
    background(a).save(BRAND / "icon_bg.png")
    fg = Image.new("RGBA", (a, a), (0, 0, 0, 0))
    f = portrait(int(a * 0.7))
    fg.alpha_composite(f, ((a - f.size[0]) // 2, int(a * 0.17)))
    fg.save(BRAND / "icon_fg.png")
    print("icon ->", ROOT / "icon.png")


if __name__ == "__main__":
    main()
