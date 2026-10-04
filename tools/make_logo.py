"""MaelStoorm Studios logosu ve açılış (boot splash) görseli.

Run: python3 tools/make_logo.py   (needs pillow)
Logo: lacivert bir daire içinde dönen bir girdap (maelstrom) ve köpük dalgaları.
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = Path(__file__).resolve().parent.parent / "assets" / "brand"
SS = 4
BG = (18, 30, 58)
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def emblem(size=512):
    s = size * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = s / 2
    r = s * 0.46
    d.ellipse((c - r, c - r, c + r, c + r), fill=(33, 78, 140, 255))
    d.ellipse((c - r * 0.93, c - r * 0.93, c + r * 0.93, c + r * 0.93), fill=(24, 54, 104, 255))
    # girdap kolları: içe doğru daralan spiral çizgiler
    arms = 4
    for a in range(arms):
        pts = []
        for i in range(220):
            t = i / 219
            ang = a * 2 * math.pi / arms + t * 2.1 * math.pi
            rad = r * 0.88 * (1 - t) ** 1.15
            pts.append((c + math.cos(ang) * rad, c + math.sin(ang) * rad, t))
        for i in range(len(pts) - 1):
            x0, y0, t = pts[i]
            x1, y1, _ = pts[i + 1]
            w = int((1 - t) * s * 0.035 + s * 0.004)
            col = (int(120 + 135 * t), int(200 + 55 * t), 255, 255)
            d.line((x0, y0, x1, y1), fill=col, width=w)
    d.ellipse((c - s * 0.035, c - s * 0.035, c + s * 0.035, c + s * 0.035), fill=(255, 255, 255, 255))
    # hafif parıltı
    glow = img.filter(ImageFilter.GaussianBlur(SS * 6))
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.alpha_composite(glow)
    out.alpha_composite(img)
    return out.resize((size, size), Image.LANCZOS)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    e = emblem(512)
    e.save(OUT / "logo.png")
    # Android açılış görseli: koyu zemin, ortada logo ve yazı
    w, h = 1080, 1920
    sp = Image.new("RGBA", (w, h), BG + (255,))
    em = e.resize((440, 440), Image.LANCZOS)
    sp.alpha_composite(em, ((w - 440) // 2, 640))
    d = ImageDraw.Draw(sp)
    f1 = ImageFont.truetype(FONT, 84)
    f2 = ImageFont.truetype(FONT, 46)
    for text, font, y, col in [("MaelStoorm", f1, 1130, (255, 255, 255)), ("STUDIOS", f2, 1240, (140, 200, 255))]:
        tw = d.textlength(text, font=font)
        d.text(((w - tw) / 2, y), text, font=font, fill=col)
    sp.convert("RGB").save(OUT / "splash.png")
    print("logo ->", OUT)


if __name__ == "__main__":
    main()
