"""Generates the pixel-art sprites in assets/sprites from the ASCII grids below.

Run: python3 tools/make_sprites.py   (needs Pillow)
Each character is one pixel; '.' is transparent. Godot scales them up with
nearest filtering, so they stay crisp on any phone.
"""
from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "assets" / "sprites"

PAL = {
    "k": "#2b1d14",  # outline
    "s": "#f1c27d",  # skin
    "S": "#d79f63",  # skin shade
    "w": "#f4efe6",  # white
    "W": "#cfc6b8",  # white shade
    "r": "#c8412f",  # red
    "R": "#8e2a20",  # dark red
    "o": "#e8892b",  # orange
    "y": "#f2c94c",  # yellow
    "Y": "#c99a2e",  # dark yellow
    "g": "#4f8a5b",  # green
    "G": "#2f5e3d",  # dark green
    "l": "#7fbf6a",  # light green
    "b": "#8a5a3b",  # brown
    "B": "#5c3a26",  # dark brown
    "u": "#3d6fb6",  # blue
    "U": "#284b80",  # dark blue
    "c": "#79c2d0",  # light blue / glass
    "p": "#9b59b6",  # purple
    "P": "#6c3483",  # dark purple
    "h": "#3b2a1e",  # hair
    "n": "#2c3e50",  # navy
    "e": "#9aa0a6",  # grey
    "E": "#62676c",  # dark grey
    "t": "#b5442d",  # roof tile
    "T": "#7d2c1d",  # roof tile shade
    "m": "#e6d3a3",  # sand / bread light
    "M": "#c49a5a",  # bread crust
}

SPRITES = {}


def sprite(name, rows, w=None):
    w = w or max(len(r) for r in rows)
    for r in rows:
        if len(r) > w:
            raise ValueError(f"{name}: row too long ({len(r)}>{w}): {r}")
    SPRITES[name] = [r.ljust(w, ".") for r in rows]


# --- characters -----------------------------------------------------------
sprite("teyze", [
    "....kkkkkkkk....",
    "...kpppwppppk...",
    "..kpwpppppwppk..",
    "..kpppppppppPk..",
    "..kpsssssssspk..",
    "..kskkkskkkssk..",
    "..kskcksckcssk..",
    "..kssssSsssssk..",
    "...kssrrrsssk...",
    "....kssssssk....",
    "...kgggwwgggk...",
    "..kgggwggwgggk..",
    "..ksgggggggg sk.",
    "..kkbbbbbbbbkk..",
    "...kbbbbbbbbk...",
    "....kkk..kkk....",
])
SPRITES["teyze"] = [r.replace(" ", "g") for r in SPRITES["teyze"]]

sprite("player", [
    ".....kkkkkk.....",
    "....khhhhhhk....",
    "...khhhhhhhhk...",
    "...khssssssh k..",
    "...kskksskksk...",
    "...kssssssssk...",
    "....kssSSssk....",
    ".....kssssk.....",
    "....kuuuuuuk....",
    "...kuuuwwuuuk...",
    "...ksuuuuuusk...",
    "...kkuuuuuukk...",
    "....knnnnnnk....",
    "....knnkknnk....",
    "....kBBk.kBBk...",
    "....kkk...kkk...",
])
SPRITES["player"] = [r.replace(" ", "h") for r in SPRITES["player"]]

sprite("cat", [
    "................",
    "..k.......k.....",
    ".kwk.....kwk....",
    ".kwwkkkkkwwk....",
    ".kwwwwwwwwwk....",
    "kwwkwwwwkwwwk...",
    "kwwkwwwwkwwwk...",
    "kwwwwrrwwwwwk...",
    ".kwwwwwwwwwk..k.",
    "..kwwwwwwwwk.kwk",
    "..kwwwwwwwwwkwk.",
    "..kwwwwwwwwwwk..",
    "..kwwWwwwWwwk...",
    "..kwk.kwk.kwk...",
    "..kk..kk..kk....",
    "................",
])

# --- tiles ----------------------------------------------------------------
sprite("grass", [
    "llllllllllllllll",
    "lllglllllllllgll",
    "llllllllllllllll",
    "lllllllglllllll.",
    "llglllllllllllll",
    "llllllllllgllll.",
    "llllllllllllllll",
    "lllllgllllllllll",
    "llllllllllllglll",
    "lgllllllllllllll",
    "llllllllgllllll.",
    "llllllllllllllll",
    "lllglllllllllgll",
    "llllllllllllllll",
    "lllllllglllllll.",
    "llllllllllllllll",
])
SPRITES["grass"] = [r.replace(".", "l") for r in SPRITES["grass"]]

sprite("path", [
    "eeeeEeeeeeeEeeee",
    "eWWeEeWWWeeEeWWe",
    "eWeeEeWeeeeEeWee",
    "EEEEEEEEEEEEEEEE",
    "eeEeeeeeEeeeeeEe",
    "eWEeWWWeEeWWWeEe",
    "eeEeWeeeEeWeeeEe",
    "EEEEEEEEEEEEEEEE",
    "eeeeEeeeeeeEeeee",
    "eWWeEeWWWeeEeWWe",
    "eWeeEeWeeeeEeWee",
    "EEEEEEEEEEEEEEEE",
    "eeEeeeeeEeeeeeEe",
    "eWEeWWWeEeWWWeEe",
    "eeEeWeeeEeWeeeEe",
    "EEEEEEEEEEEEEEEE",
])

# --- buildings & props -------------------------------------------------------
sprite("house", [
    "...........kkkkkkkkkk...........",
    ".........kkttttttttttkk.........",
    ".......kkttTttttTttttttkk.......",
    ".....kkttttttTttttttTttttkk.....",
    "...kkttTttttttttTtttttttTttkk...",
    ".kkttttttTttttttttttTtttttttkk..",
    "kTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTk",
    "kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk",
    ".kwwwwwwwwwwwwwwwwwwwwwwwwwwwwk.",
    ".kwkkkkkkwwwwwwwwwwwwwwkkkkkkwk.",
    ".kwkcwwckwwwwwwwwwwwwwwkcwwckwk.",
    ".kwkcwwckwwwwwwwwwwwwwwkcwwckwk.",
    ".kwkwwwwkwwwwwwwwwwwwwwkwwwwkwk.",
    ".kwkkkkkkwwwwkkkkkkwwwwkkkkkkwk.",
    ".kwkbbbbkwwwkuuuuuukwwwkbbbbkwk.",
    ".kwwkrkrwwwwkuUuuUukwwwwkrkrwwk.",
    ".kwkgkgkwwwwkuUuuUukwwwkgkgkwwk.",
    ".kWWWWWWWWWWkuuuuyukWWWWWWWWWWk.",
    ".kWWWWWWWWWWkuuuuuukWWWWWWWWWWk.",
    ".kkkkkkkkkkkkkkkkkkkkkkkkkkkkkk.",
])

sprite("neighbor_house", [
    "...........kkkkkkkkkk...........",
    ".........kkuuuuuuuuuukk.........",
    ".......kkuuUuuuuUuuuuuukk.......",
    ".....kkuuuuuuUuuuuuuUuuuukk.....",
    "...kkuuUuuuuuuuuUuuuuuuuUuukk...",
    ".kkuuuuuuUuuuuuuuuuuUuuuuuuukk..",
    "kUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUk",
    "kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk",
    ".kmmmmmmmmmmmmmmmmmmmmmmmmmmmmk.",
    ".kmkkkkkkmmmmmmmmmmmmmmkkkkkkmk.",
    ".kmkcmmckmmmmmmmmmmmmmmkcmmckmk.",
    ".kmkcmmckmmmmmmmmmmmmmmkcmmckmk.",
    ".kmkkkkkkmmmmkkkkkkmmmmkkkkkkmk.",
    ".kmmmmmmmmmmkbbbbbbkmmmmmmmmmmk.",
    ".kmmmmmmmmmmkbBbbBbkmmmmmmmmmmk.",
    ".kMMMMMMMMMMkbbbbybkMMMMMMMMMMk.",
    ".kMMMMMMMMMMkbbbbbbkMMMMMMMMMMk.",
    ".kkkkkkkkkkkkkkkkkkkkkkkkkkkkkk.",
])

sprite("stall", [
    "kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk",
    "krrrrwwwwrrrrwwwwrrrrwwwwrrrrwwk",
    "krrrrwwwwrrrrwwwwrrrrwwwwrrrrwwk",
    "kRRRRWWWWRRRRWWWWRRRRWWWWRRRRWWk",
    ".kkrrkkwwkkrrkkwwkkrrkkwwkkrrkk.",
    "..kb........................bk..",
    "..kb........................bk..",
    "..kb........................bk..",
    "..kb..kkk...kkk....kkk......bk..",
    "..kb.krrrk.kyyyk..kgggk.....bk..",
    "kkkkkrrrrrkyyyyykkgggggkkkkkkkkk",
    "kbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbk",
    "kBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBk",
    ".kbk........................kbk.",
    ".kbk........................kbk.",
    ".kkk........................kkk.",
])

sprite("tree", [
    "......kkkkkk......",
    "....kkggggggkk....",
    "...kggllggggggk...",
    "..kgglllggggGggk..",
    ".kgglllggggggGggk.",
    ".kggllgggggggGGgk.",
    "kgggggggggGgggGggk",
    "kgggggggggggggGGgk",
    "kggGggggggggggGggk",
    ".kgGGgggggggGGGgk.",
    ".kggGGGgggGGGGggk.",
    "..kkgGGGGGGGGgkk..",
    "....kkkbbBkkkk....",
    "......kbbBk.......",
    "......kbbBk.......",
    ".....kbbbbBk......",
    ".....kkkkkkk......",
])

sprite("bush", [
    "................",
    ".....kkkkkk.....",
    "...kkgglgggkk...",
    "..kgglllggggGk..",
    ".kgglllgggggGGk.",
    ".kggllgggggggGk.",
    "kgggggggrggggGGk",
    "kggrgggggggggGGk",
    "kgggggggggrgGGGk",
    "kggggggggggGGGGk",
    ".kGgggggGGGGGGk.",
    "..kkGGGGGGGGkk..",
    "....kkkkkkkk....",
])

sprite("crate", [
    "kkkkkkkkkkkkkkkk",
    "kbbbbbbbbbbbbbbk",
    "kbkkkkkkkkkkkkbk",
    "kbkbBbbbbbbBbkbk",
    "kbkbbBbbbbBbbkbk",
    "kbkbbbBbbBbbbkbk",
    "kbkbbbbBBbbbbkbk",
    "kbkbbbbBBbbbbkbk",
    "kbkbbbBbbBbbbkbk",
    "kbkbbBbbbbBbbkbk",
    "kbkbBbbbbbbBbkbk",
    "kbkkkkkkkkkkkkbk",
    "kBBBBBBBBBBBBBBk",
    "kkkkkkkkkkkkkkkk",
])

sprite("pot", [
    "...r..r....r....",
    "..rrr.rr..rrr...",
    "...rgrr.g.rr....",
    "....g.g.gg.g....",
    "...g.ggg.gg.....",
    "..kkkkkkkkkkkk..",
    "..ktttttttttTk..",
    "..kTTTTTTTTTTk..",
    "...kttttttttk...",
    "...kttttttTTk...",
    "...kttttttTTk...",
    "....kttttTTk....",
    "....kkkkkkkk....",
])

sprite("cart", [
    "................",
    "..kkkkkkkkkkkk..",
    "..kbbbbbbbbbbk..",
    "..kbyyoorrggbk..",
    "..kbbbbbbbbbbkkk",
    "..kBBBBBBBBBBk.k",
    "...kkkkkkkkkk..k",
    "....kek..kek....",
    "....kkk..kkk....",
])

# --- market items -----------------------------------------------------------
sprite("domates", [
    "................",
    "......kgk.......",
    "....kkgggkk.....",
    "...krrkgkrrk....",
    "..krrrrrrrrrk...",
    "..krwrrrrrrrk...",
    ".krwrrrrrrrrrk..",
    ".krrrrrrrrrrRk..",
    ".krrrrrrrrrrRk..",
    ".krrrrrrrrrRRk..",
    "..krrrrrrrRRk...",
    "..kRrrrrRRRRk...",
    "...kkRRRRRkk....",
    ".....kkkkk......",
])

sprite("ekmek", [
    "................",
    "................",
    "....kkkkkkkk....",
    "..kkMMMMMMMMkk..",
    ".kMMmMMMmMMMmMk.",
    "kMMmmMMmmMMmmMMk",
    "kMMMmMMMmMMMmMMk",
    "kMMMMMMMMMMMMMMk",
    "kMMMMMMMMMMMMMBk",
    ".kBMMMMMMMMMMBk.",
    "..kkBBBBBBBBkk..",
    "....kkkkkkkk....",
])

sprite("simit", [
    "................",
    ".....kkkkkk.....",
    "...kkMMwMMMkk...",
    "..kMwMMMMwMMMk..",
    ".kMMMMkkkkMwMMk.",
    ".kMwMk....kMMMk.",
    "kMMMk......kMwMk",
    "kMwMk......kMMMk",
    "kMMMk......kMMBk",
    ".kMMMk....kMMBk.",
    ".kMwMMkkkkMMBBk.",
    "..kMMMwMMMMBBk..",
    "...kkBBBBBBkk...",
    ".....kkkkkk.....",
])

sprite("peynir", [
    "................",
    "................",
    "................",
    ".kkkkkkkkkkkkkk.",
    ".kwwwwwwwwwwwwk.",
    ".kwwWwwwwwWwwwk.",
    ".kwwwwwwwwwwwwk.",
    ".kwwwwwWwwwwwwk.",
    ".kwWwwwwwwwwWwk.",
    ".kwwwwwwwwwwwwk.",
    ".kWWWWWWWWWWWWk.",
    ".kkkkkkkkkkkkkk.",
])

sprite("zeytin", [
    "................",
    "................",
    "...kkk...kkk....",
    "..kPPPk.kPPPk...",
    "..kPwPk.kPwPk...",
    "..kPPPk.kPPPk...",
    "...kkkkkkkkk....",
    "....kPPPkPk.....",
    ".kkkkkkkkkkkkkk.",
    ".kwwwwwwwwwwwwk.",
    "..kwwwwwwwwwwk..",
    "..kWWWWWWWWWWk..",
    "...kkkkkkkkkk...",
])

sprite("cay", [
    "................",
    "....kkkkkkkk....",
    "....kwwwwwwk....",
    "....kcrrrrck....",
    ".....krrrrk.....",
    "......krrk......",
    "......krrk......",
    ".....krrrrk.....",
    "....krrrrrrk....",
    "....kcrrrrck....",
    ".....kkkkkk.....",
    "..kkkkkkkkkkkk..",
    "..keeeeeeeeeek..",
    "...kkkkkkkkkk...",
])

sprite("karpuz", [
    "................",
    "................",
    "................",
    "kkkkkkkkkkkkkkkk",
    "krrrrrkrrrrrkrrk",
    "krrkrrrrrkrrrrrk",
    ".krrrrrrrrrrrrk.",
    ".kwwwwwwwwwwwwk.",
    "..kggggggggggk..",
    "...kGGGGGGGGk...",
    "....kkkkkkkk....",
])

sprite("yumurta", [
    "................",
    "................",
    "......kkkk......",
    ".....kwwwwk.....",
    "....kwwwwwwk....",
    "...kwwwwwwwwk...",
    "...kwwwwwwwWk...",
    "..kwwwwwwwwwWk..",
    "..kwwwwwwwwwWk..",
    "..kwwwwwwwwWWk..",
    "...kwwwwwwWWk...",
    "....kkWWWWkk....",
    "......kkkk......",
])

# --- message icons ----------------------------------------------------------
sprite("ay", [
    "................",
    ".....kkkkk......",
    "...kkyyyyk......",
    "..kyyyyyk.......",
    ".kyyyyyk........",
    ".kyyyyk.........",
    "kyyyyyk.........",
    "kyyyyyk.........",
    "kyyyyyyk........",
    ".kyyyyyyk.....k.",
    ".kYyyyyyykkkkyk.",
    "..kYYyyyyyyyyk..",
    "...kkYYYYYYkk...",
    ".....kkkkkk.....",
])

sprite("gunes", [
    ".......k........",
    "...k...y...k....",
    "....y..y..y.....",
    ".....kkkkk......",
    "....kyyyyyk.....",
    "...kyyyyyyyk....",
    "kyykyyyyyyykyyk.",
    "...kyyyyyyYk....",
    "...kyyyyyYYk....",
    "....kyyyYYk.....",
    ".....kkkkk......",
    "....y..y..y.....",
    "...k...y...k....",
    ".......k........",
])

sprite("ev", [
    ".......kk.......",
    "......kttk......",
    ".....kttttk.....",
    "....kttTtttk....",
    "...kttttttTtk...",
    "..kttTttttttTk..",
    ".kTTTTTTTTTTTTk.",
    "..kwwwwwwwwwwk..",
    "..kwkkwwwkkkwk..",
    "..kwkckwwkukwk..",
    "..kwkkwwwkukwk..",
    "..kwwwwwwkykwk..",
    "..kWWWWWWkukWk..",
    "..kkkkkkkkkkkk..",
])

sprite("kurabiye", [
    "................",
    ".....kkkkkk.....",
    "...kkMMMMMMkk...",
    "..kMMBMMMMMMMk..",
    ".kMMMMMMMBMMMMk.",
    ".kMMMMMMMMMMMMk.",
    "kMMBMMMMMMMBMMMk",
    "kMMMMMMBMMMMMMMk",
    "kMMMMMMMMMMMMBMk",
    "kMBMMMMMMMMMMMMk",
    ".kMMMMMBMMMMMMk.",
    ".kMMMMMMMMMBMMk.",
    "..kMMMMMMMMMMk..",
    "...kkMMMMMMkk...",
    ".....kkkkkk.....",
])

sprite("borek", [
    "................",
    "................",
    "................",
    "..kkkkkkkkkkkk..",
    ".kyMyMyMyMyMyMk.",
    "kMyyMyyMyyMyyMyk",
    "kyyMyyMyyMyyMyyk",
    "kMMMMMMMMMMMMMMk",
    "kyyyyyyyyyyyyyyk",
    "kYYYYYYYYYYYYYYk",
    ".kkkkkkkkkkkkkk.",
])

sprite("kapi", [
    "...kkkkkkkkkk...",
    "..kbbbbbbbbbbk..",
    "..kbkkkkkkkkbk..",
    "..kbkBbbbbBkbk..",
    "..kbkbbbbbbkbk..",
    "..kbkbbbbbbkbk..",
    "..kbkkkkkkkkbk..",
    "..kbbbbbbbbbbk..",
    "..kbkkkkkkkkbk..",
    "..kbkbbbbbbkbk..",
    "..kbkbbbbyykbk..",
    "..kbkbbbbbbkbk..",
    "..kbkkkkkkkkbk..",
    "..kbbbbbbbbbbk..",
    ".kkkkkkkkkkkkkk.",
])

sprite("heart", [
    "................",
    "..kkk....kkk....",
    ".krrrk..krrrk...",
    "krwrrrkkrrrrrk..",
    "krwrrrrrrrrrrk..",
    "krrrrrrrrrrrRk..",
    ".krrrrrrrrrRk...",
    "..krrrrrrrRk....",
    "...krrrrrRk.....",
    "....krrrRk......",
    ".....krRk.......",
    "......kk........",
])


def hexrgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, rows in SPRITES.items():
        img = Image.new("RGBA", (len(rows[0]), len(rows)), (0, 0, 0, 0))
        for y, row in enumerate(rows):
            for x, ch in enumerate(row):
                if ch != ".":
                    img.putpixel((x, y), hexrgb(PAL[ch]))
        img.save(OUT / f"{name}.png")
    print(f"{len(SPRITES)} sprites -> {OUT}")


if __name__ == "__main__":
    main()
