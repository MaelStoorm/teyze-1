"""Oyunun ses efektlerini ve alaturka müziğini sentezler (assets/sounds/*.wav).

Run: python3 tools/make_sounds.py   (needs numpy)
Hiçbir ses dosyası dışarıdan alınmadı; hepsi burada matematikle üretiliyor.
Müzik Hicaz makamında, saz benzeri telli sesle (Karplus-Strong) ve hafif
darbuka ritmiyle çalınan, döngüye girebilen kısa bir parça.
"""
import wave
from pathlib import Path

import numpy as np

OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"
SR = 22050
rng = np.random.default_rng(7)

# Re Hicaz: Re, Mi bemol, Fa diyez, Sol, La, Si bemol, Do, Re
N = {
    "D3": 146.83, "A3": 220.0, "D4": 293.66, "Eb4": 311.13, "F#4": 369.99, "G4": 392.0,
    "A4": 440.0, "Bb4": 466.16, "C5": 523.25, "D5": 587.33, "F#5": 739.99, "A5": 880.0,
    "D6": 1174.66, "Eb5": 622.25, "G5": 783.99, "Bb5": 932.33,
}


def t(sec):
    return np.arange(int(SR * sec)) / SR


def env(n, attack=0.005, decay=None):
    e = np.ones(n)
    a = max(int(SR * attack), 1)
    e[:a] = np.linspace(0, 1, a)
    if decay:
        e *= np.exp(-np.arange(n) / (SR * decay))
    return e


def pluck(freq, sec, bright=0.5, damp=0.996):
    """Karplus-Strong telli çalgı sesi (saz/ud gibi)."""
    n = int(SR * sec)
    period = max(int(SR / freq), 2)
    buf = rng.uniform(-1, 1, period)
    # parlaklık: gürültüyü biraz yumuşat
    for _ in range(int((1 - bright) * 3)):
        buf = (buf + np.roll(buf, 1)) / 2
    out = np.zeros(n)
    for i in range(n):
        j = i % period
        out[i] = buf[j]
        buf[j] = damp * 0.5 * (buf[j] + buf[(j + 1) % period])
    return out * env(n, 0.002)


def sine(freq, sec, decay=0.2):
    x = t(sec)
    f = np.full_like(x, freq) if np.isscalar(freq) else freq
    phase = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(phase) * env(len(x), 0.003, decay)


def noise(sec, decay=0.05, smooth=0):
    n = int(SR * sec)
    x = rng.uniform(-1, 1, n)
    for _ in range(smooth):
        x = (x + np.roll(x, 1)) / 2
    return x * env(n, 0.001, decay)


def mix(*parts):
    n = max(int(start * SR) + len(p) for start, p in parts)
    out = np.zeros(n)
    for start, p in parts:
        s = int(start * SR)
        end = min(n, s + len(p))
        if s < n:
            out[s:end] += p[: end - s]
    return out


def save(name, x, peak=0.8):
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    data = (x * 32767).astype(np.int16)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


# --- efektler -----------------------------------------------------------------

def sfx():
    save("tap", mix((0, sine(880, 0.08, 0.02)), (0, 0.3 * noise(0.02, 0.004))), 0.5)
    save("good", mix((0, pluck(N["A5"], 0.5, 0.8)), (0.09, pluck(N["D6"], 0.7, 0.8))), 0.6)
    sweep = np.linspace(200, 130, int(SR * 0.28))
    save("bad", sine(sweep, 0.28, 0.12) + 0.5 * sine(sweep * 1.5, 0.28, 0.08), 0.45)
    arp = [N["D5"], N["F#5"], N["A5"], N["D6"]]
    save("win", mix(*[(i * 0.1, pluck(f, 1.2, 0.8)) for i, f in enumerate(arp)]), 0.7)
    scale = ["D4", "Eb4", "F#4", "G4", "A4", "Bb4", "C5", "D5"]
    save("levelup", mix(*[(i * 0.09, pluck(N[k] * 2, 1.0, 0.8)) for i, k in enumerate(scale)],
                        (0.75, pluck(N["D6"], 1.6, 0.9))), 0.7)
    ping = lambda f: sine(f, 0.5, 0.12) + 0.6 * sine(f * 1.5, 0.5, 0.08)
    save("coin", mix((0, ping(2093)), (0.08, ping(2637))), 0.5)
    bubbles = [(i * 0.07 + rng.uniform(0, 0.03), sine(np.linspace(f, f * 1.8, int(SR * 0.05)), 0.05, 0.02))
               for i, f in enumerate(rng.uniform(300, 700, 5))]
    save("stir", mix(*bubbles), 0.45)
    # miyav: perdesi yükselip inen, sesli harfi "i"den "av"a dönen bir ses
    dur = 0.7
    x = t(dur)
    f0 = 520 + 300 * np.sin(np.pi * x / dur) ** 1.5 - 120 * (x / dur)
    phase = 2 * np.pi * np.cumsum(f0) / SR
    morph = x / dur
    voice = sum(np.sin(k * phase) * (np.exp(-((k * f0 - (2200 - 1400 * morph)) / 600) ** 2) + 0.4 / k)
                for k in range(1, 12))
    save("meow", voice * env(len(x), 0.04) * np.minimum(1, (dur - x) * 6), 0.55)
    w = noise(0.35, 0.15, smooth=6)
    save("whoosh", w * np.sin(np.linspace(0, np.pi, len(w))), 0.3)


# --- müzik --------------------------------------------------------------------

MELODY = [
    [("A4", 1), ("Bb4", .5), ("A4", .5), ("G4", 1), ("F#4", 1)],
    [("G4", .5), ("F#4", .5), ("Eb4", 1), ("D4", 2)],
    [("D4", .5), ("Eb4", .5), ("F#4", 1), ("G4", 1), ("A4", 1)],
    [("Bb4", .5), ("A4", .5), ("G4", .5), ("F#4", .5), ("G4", 2)],
    [("A4", 1), ("C5", 1), ("Bb4", .5), ("A4", .5), ("G4", 1)],
    [("F#4", 1), ("G4", .5), ("A4", .5), ("Bb4", 2)],
    [("A4", .5), ("G4", .5), ("F#4", .5), ("Eb4", .5), ("F#4", 1), ("G4", 1)],
    [("F#4", .5), ("Eb4", .5), ("D4", 3)],
]


def music():
    beat = 60 / 92
    bars = len(MELODY)
    total = bars * 4 * beat
    n = int(total * SR)
    out = np.zeros(n + SR * 3)

    def put(start, x, gain):
        s = int(start * SR)
        out[s:s + len(x)] += x * gain

    for b, bar in enumerate(MELODY):
        pos = b * 4 * beat
        for note, length in bar:
            put(pos, pluck(N[note], length * beat + 0.6, 0.55, 0.9975), 0.55)
            if length >= 1:  # sazın tekrar vuruşu (tremolo hissi)
                put(pos + beat / 2, pluck(N[note], 0.5, 0.4, 0.995), 0.18)
            pos += length * beat
        # ud gibi bas: her ölçünün başında ve ortasında
        root = "D3" if b % 2 == 0 else "A3"
        put(b * 4 * beat, pluck(N[root], 2.0, 0.3, 0.998), 0.4)
        put(b * 4 * beat + 2 * beat, pluck(N["D3"], 1.5, 0.3, 0.998), 0.25)
        # darbuka: düm - tek - tek düm - tek - (maksum benzeri)
        for k, kind in enumerate(["D", None, "T", "T", "D", None, "T", None]):
            s = b * 4 * beat + k * beat / 2
            if kind == "D":
                put(s, sine(np.linspace(110, 70, int(SR * 0.25)), 0.25, 0.08), 0.35)
            elif kind == "T":
                put(s, noise(0.06, 0.012, smooth=1), 0.12)

    # döngü: taşan kuyruğu başa ekle, böylece tekrar ederken kesinti olmaz
    tail = out[n:]
    out = out[:n]
    out[:len(tail)] += tail[: len(out)]
    save("muzik", out, 0.55)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    sfx()
    music()
    print("sounds ->", OUT)


if __name__ == "__main__":
    main()
