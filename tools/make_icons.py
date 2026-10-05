"""Pürüzsüz, gölgeli ikonları üretir (assets/icons/*.png).

Run: python3 tools/make_icons.py   (needs Pillow)
Her ikon 4 kat büyük çizilip küçültülür; kenarlar yumuşak kalır.
Her şekil: koyu dış çizgi + yukarıdan aşağı açıktan koyuya dolgu + parlama.
"""
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parent.parent / "assets" / "icons"
SS = 4  # süper örnekleme
OUT_SCALE = 2  # telefonların yüksek çözünürlüklü ekranında keskin dursun diye 2x kaydet
INK = (59, 42, 30, 255)


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mix(c, t, k):
    return tuple(int(a + (b - a) * k) for a, b in zip(c, t))


class Icon:
    def __init__(self, w=128, h=128):
        self.w, self.h = w * SS, h * SS
        self.size = (w, h)
        self.img = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        self.outline = 5 * SS

    def s(self, v):
        return v * SS

    def mask(self, fn):
        m = Image.new("L", (self.w, self.h), 0)
        fn(ImageDraw.Draw(m), self.s)
        return m

    def shape(self, fn, color, outline=True, shade=True, gloss=True):
        color = hexc(color) if isinstance(color, str) else color
        m = self.mask(fn)
        if outline:
            k = self.outline * 2 + 1
            out = m.filter(ImageFilter.MaxFilter(k if k % 2 else k + 1))
            self.img.paste(Image.new("RGBA", self.img.size, INK), (0, 0), out)
        bbox = m.getbbox()
        if not bbox:
            return
        fill = Image.new("RGBA", self.img.size, color + (255,))
        if shade:
            top, bottom = bbox[1], bbox[3]
            grad = Image.new("RGBA", (1, self.h))
            for y in range(self.h):
                t = min(max((y - top) / max(bottom - top, 1), 0), 1)
                c = mix(color, (255, 255, 255), 0.22 * (1 - t)) if t < 0.5 else mix(color, (0, 0, 0), 0.22 * (t - 0.5) * 2)
                grad.putpixel((0, y), c + (255,))
            fill = grad.resize(self.img.size)
        self.img.paste(fill, (0, 0), m)
        if gloss:
            x0, y0, x1, y1 = bbox
            w, h = x1 - x0, y1 - y0
            g = Image.new("L", self.img.size, 0)
            ImageDraw.Draw(g).ellipse((x0 + w * 0.18, y0 + h * 0.1, x0 + w * 0.42, y0 + h * 0.28), fill=150)
            g = ImageChops.multiply(g, m).filter(ImageFilter.GaussianBlur(SS * 2))
            self.img.paste(Image.new("RGBA", self.img.size, (255, 255, 255, 255)), (0, 0), g)

    def line(self, pts, color, width):
        d = ImageDraw.Draw(self.img)
        d.line([(self.s(x), self.s(y)) for x, y in pts], fill=hexc(color) + (255,), width=self.s(width), joint="curve")

    def dot(self, x, y, r, color):
        d = ImageDraw.Draw(self.img)
        d.ellipse((self.s(x - r), self.s(y - r), self.s(x + r), self.s(y + r)), fill=hexc(color) + (255,))

    def save(self, name):
        # zemin gölgesi
        shadow = self.img.split()[3].filter(ImageFilter.GaussianBlur(SS * 3))
        base = Image.new("RGBA", self.img.size, (0, 0, 0, 0))
        base.paste(Image.new("RGBA", self.img.size, (0, 0, 0, 70)), (0, SS * 3), shadow)
        base.alpha_composite(self.img)
        base.resize((self.size[0] * OUT_SCALE, self.size[1] * OUT_SCALE), Image.LANCZOS).save(OUT / f"{name}.png")


def E(x0, y0, x1, y1):
    return lambda d, s: d.ellipse((s(x0), s(y0), s(x1), s(y1)), fill=255)


def R(x0, y0, x1, y1, r=8):
    return lambda d, s: d.rounded_rectangle((s(x0), s(y0), s(x1), s(y1)), radius=s(r), fill=255)


def P(*pts):
    return lambda d, s: d.polygon([(s(x), s(y)) for x, y in pts], fill=255)


ICONS = {}


def icon(name, w=128, h=128):
    def deco(fn):
        ICONS[name] = (fn, w, h)
        return fn
    return deco


@icon("domates")
def _(i):
    i.shape(E(16, 30, 112, 116), "#e04a35")
    i.shape(P((64, 22), (80, 40), (98, 34), (84, 48), (64, 44), (44, 48), (30, 34), (48, 40)), "#4f9a4a", gloss=False)
    i.line([(64, 30), (66, 12)], "#3f7a3a", 6)


@icon("ekmek")
def _(i):
    i.shape(E(8, 34, 120, 104), "#d9a05b")
    for x in (36, 60, 84):
        i.line([(x - 8, 50), (x + 8, 80)], "#f3d9a4", 6)


@icon("simit")
def _(i):
    def ring(d, s):
        d.ellipse((s(12), s(12), s(116), s(116)), fill=255)
        d.ellipse((s(42), s(42), s(86), s(86)), fill=0)
    i.shape(ring, "#c9803f")
    for a in range(0, 360, 30):
        r = 41
        x, y = 64 + r * math.cos(math.radians(a)), 64 + r * math.sin(math.radians(a))
        i.dot(x, y, 2.5, "#fff6dc")


@icon("peynir")
def _(i):
    i.shape(R(14, 38, 114, 100, 10), "#f8f4ea")
    for x, y, r in ((40, 60, 5), (76, 78, 6), (92, 56, 4)):
        i.dot(x, y, r, "#e4dccb")


@icon("zeytin")
def _(i):
    i.shape(E(12, 70, 116, 112), "#f4efe6", gloss=False)
    for x, y in ((30, 46), (60, 38), (90, 48), (46, 64), (78, 64)):
        i.shape(E(x - 16, y - 13, x + 16, y + 13), "#4b2a5a")


@icon("karpuz")
def _(i):
    i.shape(lambda d, s: d.pieslice((s(8), s(-40), s(120), s(112)), 0, 180, fill=255), "#3f8a3f", gloss=False)
    i.shape(lambda d, s: d.pieslice((s(16), s(-32), s(112), s(100)), 0, 180, fill=255), "#f2efe0", outline=False, gloss=False)
    i.shape(lambda d, s: d.pieslice((s(22), s(-26), s(106), s(92)), 0, 180, fill=255), "#e9473b", outline=False)
    for x, y in ((40, 50), (64, 62), (88, 50), (52, 76), (76, 76)):
        i.dot(x, y, 3, "#2b1d14")


@icon("yumurta")
def _(i):
    i.shape(E(30, 14, 98, 116), "#fbf7ef")


@icon("ay")
def _(i):
    def moon(d, s):
        d.ellipse((s(14), s(14), s(110), s(110)), fill=255)
        d.ellipse((s(44), s(2), s(130), s(88)), fill=0)
    i.shape(moon, "#f5cd4f")
    i.shape(E(88, 80, 100, 92), "#f5cd4f", gloss=False)


@icon("gunes")
def _(i):
    for a in range(0, 360, 45):
        c, s_ = math.cos(math.radians(a)), math.sin(math.radians(a))
        i.shape(P((64 + 58 * c, 64 + 58 * s_), (64 + 30 * c - 10 * s_, 64 + 30 * s_ + 10 * c),
                  (64 + 30 * c + 10 * s_, 64 + 30 * s_ - 10 * c)), "#f5a93a", gloss=False)
    i.shape(E(30, 30, 98, 98), "#f7cf4a")


@icon("cay")
def _(i):
    i.shape(E(16, 100, 112, 122), "#c9ccd1", gloss=False)
    i.shape(P((40, 18), (88, 18), (78, 58), (90, 96), (38, 96), (50, 58)), "#c4402c")
    i.shape(R(36, 12, 92, 24, 4), "#f4efe6", gloss=False)


@icon("borek")
def _(i):
    i.shape(R(10, 44, 118, 104, 14), "#e8b04a")
    for x in range(22, 112, 16):
        i.line([(x, 52), (x + 10, 96)], "#f7d98a", 4)


@icon("ev")
def _(i):
    i.shape(R(22, 56, 106, 118, 4), "#f6f0e4")
    i.shape(P((10, 62), (64, 12), (118, 62)), "#c8553a")
    i.shape(R(54, 80, 76, 118, 3), "#3e6fb5", gloss=False)
    i.shape(R(30, 70, 46, 86, 2), "#9ad3e0", gloss=False)
    i.shape(R(84, 70, 100, 86, 2), "#9ad3e0", gloss=False)


@icon("kurabiye")
def _(i):
    i.shape(E(12, 12, 116, 116), "#d39a55")
    for x, y in ((40, 42), (76, 36), (54, 72), (86, 74), (36, 86), (70, 96)):
        i.shape(E(x - 6, y - 5, x + 6, y + 5), "#5c3a26", outline=False, gloss=False)


@icon("kapi")
def _(i):
    i.shape(R(26, 8, 102, 122, 6), "#8a5a3b")
    i.shape(R(36, 20, 92, 60, 4), "#a86f48", gloss=False)
    i.shape(R(36, 70, 92, 112, 4), "#a86f48", gloss=False)
    i.dot(84, 66, 5, "#f2c94c")


@icon("heart")
def _(i):
    def heart(d, s):
        d.ellipse((s(12), s(18), s(66), s(72)), fill=255)
        d.ellipse((s(62), s(18), s(116), s(72)), fill=255)
        d.polygon([(s(16), s(56)), (s(64), s(114)), (s(112), s(56)), (s(64), s(40))], fill=255)
    i.shape(heart, "#e04a4a")


@icon("cat")
def _(i):
    i.shape(E(22, 62, 110, 120), "#f8f6f2")
    i.shape(P((26, 40), (34, 8), (54, 30)), "#f8f6f2", gloss=False)
    i.shape(P((102, 40), (94, 8), (74, 30)), "#f8f6f2", gloss=False)
    i.shape(E(22, 20, 106, 86), "#f8f6f2")
    i.dot(48, 52, 5, "#2b1d14")
    i.dot(80, 52, 5, "#2b1d14")
    i.dot(64, 64, 4, "#e88a9a")
    i.dot(38, 64, 6, "#f6c3c8")
    i.dot(90, 64, 6, "#f6c3c8")


@icon("bush", 144, 112)
def _(i):
    i.shape(E(4, 40, 70, 106), "#4f9a4a")
    i.shape(E(74, 40, 140, 106), "#4f9a4a")
    i.shape(E(30, 10, 114, 100), "#5aa852")
    for x, y in ((50, 40), (90, 54), (64, 72), (110, 76), (30, 76)):
        i.dot(x, y, 5, "#e04a4a")


@icon("tree", 144, 160)
def _(i):
    i.shape(R(60, 100, 84, 156, 4), "#8a5a3b", gloss=False)
    i.shape(E(10, 40, 80, 110), "#3f8a46")
    i.shape(E(64, 40, 134, 110), "#3f8a46")
    i.shape(E(26, 4, 118, 92), "#4f9e50")


@icon("crate", 128, 112)
def _(i):
    i.shape(R(10, 10, 118, 104, 6), "#b07a4a")
    i.line([(22, 22), (106, 92)], "#8a5a3b", 7)
    i.line([(106, 22), (22, 92)], "#8a5a3b", 7)


@icon("pot", 112, 128)
def _(i):
    for x, y in ((30, 22), (56, 12), (82, 22), (44, 34), (70, 34)):
        i.shape(E(x - 12, y - 12, x + 12, y + 12), "#e04a4a", gloss=False)
    i.shape(R(14, 50, 98, 66, 4), "#c96a43")
    i.shape(P((20, 64), (92, 64), (82, 122), (30, 122)), "#c96a43")


@icon("cart", 144, 112)
def _(i):
    i.line([(126, 46), (142, 30)], "#8a5a3b", 7)
    i.shape(R(8, 30, 128, 78, 6), "#b07a4a")
    for x, c in ((30, "#e04a35"), (56, "#f5a93a"), (82, "#5aa852"), (106, "#f7cf4a")):
        i.shape(E(x - 12, 18, x + 12, 42), c, gloss=False)
    i.shape(E(22, 72, 54, 104), "#6b6f75")
    i.shape(E(84, 72, 116, 104), "#6b6f75")


@icon("stall", 256, 144)
def _(i):
    i.shape(R(20, 50, 34, 140, 3), "#8a5a3b", gloss=False)
    i.shape(R(222, 50, 236, 140, 3), "#8a5a3b", gloss=False)
    i.shape(R(8, 92, 248, 116, 6), "#a86f48")
    for k, (x, c) in enumerate(((44, "#e04a35"), (84, "#f5a93a"), (124, "#5aa852"), (164, "#f7cf4a"), (204, "#e04a35"))):
        for dx in (-12, 0, 12):
            i.shape(E(x + dx - 11, 68 + abs(dx) // 2, x + dx + 11, 92 + abs(dx) // 2), c, gloss=False)
    i.shape(lambda d, s: d.polygon([(s(4), s(46)), (s(24), s(8)), (s(232), s(8)), (s(252), s(46))], fill=255), "#f4efe6")
    for k in range(6):
        x0 = 4 + k * 41.3
        if k % 2 == 0:
            i.shape(P((x0 + 20 * (1 - 0), 8), (x0 + 20 + 41.3 * 0.9, 8), (x0 + 41.3, 46), (x0, 46)), "#d8452f", outline=False, gloss=False)


@icon("altin")
def _(i):
    i.shape(E(12, 12, 116, 116), "#f2c23a")
    i.shape(E(28, 28, 100, 100), "#f7d65e", gloss=False)
    i.line([(52, 46), (64, 40), (64, 88)], "#c9962a", 7)
    i.line([(50, 88), (78, 88)], "#c9962a", 7)


@icon("biber")
def _(i):
    i.shape(P((40, 30), (70, 26), (96, 60), (100, 100), (84, 118), (60, 92), (36, 56)), "#4caf50")
    i.line([(54, 30), (50, 12), (60, 8)], "#3f7a3a", 6)


@icon("sogan")
def _(i):
    i.shape(E(18, 34, 110, 118), "#d9a066")
    i.shape(P((54, 40), (64, 10), (74, 40)), "#d9a066", gloss=False)
    for x in (44, 64, 84):
        i.line([(x, 50), (x, 104)], "#b9804a", 3)


@icon("havuc")
def _(i):
    i.shape(P((30, 40), (84, 34), (60, 120)), "#f08a2c")
    for dx in (-10, 0, 10):
        i.shape(E(52 + dx - 7, 8, 52 + dx + 7, 40), "#4f9a4a", gloss=False)
    for y in (56, 74, 92):
        i.line([(44 + (y - 56) * 0.25, y), (58, y - 2)], "#c96a1c", 3)


@icon("mercimek")
def _(i):
    i.shape(lambda d, s: d.pieslice((s(10), s(20), s(118), s(120)), 0, 180, fill=255), "#f2efe6", gloss=False)
    i.shape(E(14, 52, 114, 84), "#e8892b", gloss=False)
    import random
    rnd = random.Random(3)
    for _k in range(14):
        x, y = rnd.uniform(26, 102), rnd.uniform(58, 76)
        i.dot(x, y, 4, "#f2a65a")


@icon("sut")
def _(i):
    i.shape(P((36, 30), (92, 30), (98, 46), (98, 118), (30, 118), (30, 46)), "#f8f6f2")
    i.shape(R(30, 64, 98, 96, 2), "#5aa0d8", outline=False, gloss=False)
    i.shape(R(44, 10, 84, 32, 4), "#5aa0d8")


@icon("pirinc")
def _(i):
    i.shape(R(24, 28, 104, 118, 12), "#e6d3a3")
    i.shape(R(34, 14, 94, 34, 6), "#c49a5a", gloss=False)
    for x, y in ((48, 64), (64, 72), (80, 62), (56, 90), (76, 88)):
        i.dot(x, y, 4, "#fffaf0")


@icon("seker")
def _(i):
    i.shape(R(20, 50, 64, 94, 6), "#ffffff")
    i.shape(R(64, 50, 108, 94, 6), "#f4efe6")
    i.shape(R(42, 18, 86, 56, 6), "#ffffff")


@icon("tencere")
def _(i):
    i.shape(R(4, 50, 24, 62, 4), "#9aa0a6", gloss=False)
    i.shape(R(104, 50, 124, 62, 4), "#9aa0a6", gloss=False)
    i.shape(R(16, 44, 112, 116, 14), "#b5442d")
    i.shape(E(14, 34, 114, 56), "#9aa0a6", gloss=False)
    i.shape(R(54, 22, 74, 36, 5), "#5c3a26", gloss=False)


@icon("zil")
def _(i):
    i.shape(P((64, 16), (96, 40), (104, 96), (24, 96), (32, 40)), "#f2c23a")
    i.shape(R(16, 92, 112, 106, 6), "#d9a72e", gloss=False)
    i.shape(E(54, 100, 74, 120), "#c9962a", gloss=False)
    i.shape(E(56, 6, 72, 22), "#d9a72e", gloss=False)


@icon("file")
def _(i):
    i.line([(40, 50), (48, 14), (80, 14), (88, 50)], "#4f8a5b", 7)
    i.shape(P((18, 46), (110, 46), (96, 120), (32, 120)), "#7fbf6a")
    for x in range(30, 104, 14):
        i.line([(x, 50), (x + 6, 116)], "#4f8a5b", 3)
    for y in range(62, 116, 14):
        i.line([(24, y), (104, y)], "#4f8a5b", 3)


@icon("defter")
def _(i):
    i.shape(R(22, 10, 110, 118, 8), "#c8553a")
    i.shape(R(34, 22, 100, 106, 4), "#fff4dc", gloss=False)
    for y in (42, 58, 74, 90):
        i.line([(44, y), (90, y)], "#c9b99a", 3)
    for y in (24, 46, 68, 90):
        i.shape(E(14, y, 30, y + 12), "#9aa0a6", gloss=False)


@icon("kese")
def _(i):
    i.shape(E(18, 40, 110, 122), "#c0392b")
    i.shape(P((40, 44), (88, 44), (100, 18), (28, 18)), "#c0392b", gloss=False)
    i.line([(38, 44), (90, 44)], "#f2c23a", 6)
    i.shape(E(48, 66, 80, 98), "#f2c23a", gloss=False)


@icon("takvim")
def _(i):
    i.shape(R(14, 22, 114, 118, 10), "#f8f6f2")
    i.shape(R(14, 22, 114, 50, 10), "#c8412f", gloss=False)
    for x in (40, 88):
        i.shape(R(x - 5, 10, x + 5, 34, 4), "#5c3a26", gloss=False)
    for r in range(3):
        for c in range(4):
            i.dot(32 + c * 21, 66 + r * 17, 5, "#c9b99a")
    i.dot(74, 83, 7, "#4f8a5b")


@icon("yildiz")
def _(i):
    pts = []
    for k in range(10):
        a = math.radians(-90 + k * 36)
        r = 56 if k % 2 == 0 else 24
        pts.append((64 + r * math.cos(a), 66 + r * math.sin(a)))
    i.shape(P(*pts), "#f2c23a")


@icon("ayar")
def _(i):
    def gear(d, s):
        pts = []
        for k in range(16):
            a = math.radians(k * 22.5)
            r = 56 if (k // 1) % 2 == 0 else 44
            pts.append((s(64 + r * math.cos(a)), s(64 + r * math.sin(a))))
        d.polygon(pts, fill=255)
        d.ellipse((s(46), s(46), s(82), s(82)), fill=0)
    i.shape(gear, "#9aa0a6")


@icon("album")
def _(i):
    i.shape(R(12, 18, 116, 116, 10), "#8e3b2f")
    i.shape(R(20, 24, 108, 110, 6), "#f3e3c3", gloss=False)
    i.shape(P((34, 34), (86, 28), (94, 86), (42, 92)), "#ffffff", gloss=False)
    i.shape(P((42, 42), (80, 38), (86, 70), (48, 74)), "#7cc3e8", outline=False, gloss=False)
    i.shape(E(52, 54, 66, 68), "#f2c23a", outline=False, gloss=False)
    i.shape(R(56, 96, 72, 104, 3), "#c8412f", gloss=False)


@icon("yagmur")
def _(i):
    def cloud(d, s):
        d.ellipse((s(16), s(30), s(70), s(80)), fill=255)
        d.ellipse((s(44), s(18), s(108), s(78)), fill=255)
        d.rounded_rectangle((s(18), s(50), s(110), s(80)), radius=s(14), fill=255)
    i.shape(cloud, "#c9d6e3")
    for x, y in ((38, 92), (64, 100), (90, 92)):
        i.shape(P((x, y - 10), (x + 7, y + 4), (x, y + 10), (x - 7, y + 4)), "#3e8fd0", gloss=False)


@icon("balik")
def _(i):
    i.shape(P((86, 64), (118, 38), (112, 64), (118, 90)), "#e0843a", gloss=False)
    i.shape(E(10, 36, 96, 92), "#f2a65a")
    i.dot(30, 58, 6, "#3b2a1e")
    i.line([(52, 44), (60, 64), (52, 84)], "#d0743a", 4)


@icon("orgu")
def _(i):
    i.shape(E(14, 20, 110, 116), "#d6577a")
    for k in range(4):
        i.line([(26 + k * 18, 30 + k * 4), (60 + k * 14, 106 - k * 6)], "#b23a5e", 4)
    i.line([(104, 82), (122, 112)], "#c9a26b", 5)
    i.line([(96, 92), (118, 120)], "#c9a26b", 5)


@icon("manti")
def _(i):
    i.shape(E(8, 70, 120, 116), "#f4efe6")
    for x, y in ((40, 70), (64, 62), (88, 70), (52, 84), (78, 84)):
        i.shape(P((x - 14, y + 8), (x, y - 12), (x + 14, y + 8)), "#f3d9a4")
    for x, y in ((30, 96), (60, 102), (92, 96)):
        i.dot(x, y, 4, "#c8412f")


@icon("odun")
def _(i):
    for k, (x, y) in enumerate(((14, 70), (40, 52), (66, 70), (28, 34), (54, 34))):
        i.shape(R(x, y, x + 52, y + 26, 13), "#a8703f" if k % 2 == 0 else "#946035")
        i.dot(x + 44, y + 13, 8, "#e8c48e")
        i.dot(x + 44, y + 13, 3, "#a8703f")


@icon("davetiye")
def _(i):
    i.shape(R(10, 30, 118, 104, 8), "#f8f2e6")
    i.shape(P((12, 32), (64, 74), (116, 32)), "#efe3c8", gloss=False)
    i.shape(E(52, 60, 76, 84), "#c8412f", gloss=False)
    i.dot(64, 72, 4, "#f2c23a")


@icon("firin")
def _(i):
    i.shape(R(12, 40, 116, 118, 10), "#e8d2b0")
    i.shape(P((6, 46), (64, 10), (122, 46)), "#c8553a", gloss=False)
    i.shape(E(36, 62, 92, 112), "#5c3a26", gloss=False)
    i.shape(E(44, 74, 84, 112), "#f2a03a", outline=False, gloss=False)
    i.shape(R(88, 14, 102, 40, 3), "#8a5a3b", gloss=False)


@icon("kina")
def _(i):  # kına tepsisi: bakır tepsi, ortada kına kasesi, mumlar
    i.shape(E(6, 60, 122, 116), "#c98a3a")
    i.shape(E(16, 66, 112, 108), "#e0a85a", outline=False, gloss=False)
    i.shape(E(40, 56, 88, 96), "#a8452e")
    i.shape(E(48, 62, 80, 82), "#7a2e1e", outline=False, gloss=False)
    for x in (22, 106):
        i.shape(R(x - 6, 40, x + 6, 80, 3), "#f8f2e6")
        i.shape(E(x - 5, 26, x + 5, 42), "#f2c23a", outline=False)


@icon("yuzuk")
def _(i):
    def ring(d, s):
        d.ellipse((s(20), s(40), s(108), s(120)), fill=255)
        d.ellipse((s(36), s(56), s(92), s(104)), fill=0)
    i.shape(ring, "#e8b63a")
    i.shape(P((48, 44), (64, 14), (80, 44), (64, 56)), "#bfe4f2")
    i.dot(58, 32, 4, "#ffffff")


@icon("pasta")
def _(i):  # düğün pastası: iki kat, kremalı, üstte kiraz
    i.shape(R(14, 72, 114, 118, 8), "#f8f2e6")
    i.shape(R(32, 36, 96, 76, 8), "#fbe9ee")
    for x in range(22, 112, 16):
        i.dot(x, 76, 6, "#e88aa6")
    for x in range(40, 96, 14):
        i.dot(x, 40, 5, "#e88aa6")
    i.dot(64, 26, 10, "#c8412f")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    import sys
    only = sys.argv[1:]  # ad verilirse yalnız onlar üretilir
    for name, (fn, w, h) in ICONS.items():
        if only and name not in only:
            continue
        i = Icon(w, h)
        fn(i)
        i.save(name)
    print(f"{len(ICONS)} icons -> {OUT}")


if __name__ == "__main__":
    main()
