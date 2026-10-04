"""Oyunun ses efektlerini ve müziğini sentezler (assets/sounds/*.wav).

Çalıştır: python3 tools/make_sounds.py   (numpy gerekir)
Hiçbir ses dosyası dışarıdan alınmadı; hepsi burada matematikle üretiliyor.

Hedef: yumuşak, sıcak, "mahalle sabahı" havası. Sert, vızıltılı, metalik ya da
gürültülü tınılardan kaçınılır.
- Müzik: Rast makamını andıran (inişte Fa naturel) neşeli ve sakin bir ezgi;
  marimba/kalimba benzeri tokmaklı sesler, sıcak pad ve bas, hafif "düm-tek"
  vurmalılar. Alçak geçiren süzgeç, yankı (geri beslemeli gecikme) ve oda
  yankısı (reverb) eklenir. Parça kesintisiz döngüye girer (tüm efektler
  dairesel evrişimle uygulanır, taşan kuyruk başa katlanır).
- Efektler: kısa, yuvarlak ve kısık sesler; ayrıca adım ve sevimli hayvan
  sesleri (inek, tavuk, ördek, köpek, kedi).
"""
import wave
from pathlib import Path

import numpy as np

OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"
SR = 22050
NYQ = SR / 2
rng = np.random.default_rng(7)

_SEMI = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def hz(name):
    """'F#5', 'Bb4', 'G3' gibi nota adını frekansa çevirir."""
    k = _SEMI[name[0]]
    rest = name[1:]
    if rest.startswith("#"):
        k += 1
        rest = rest[1:]
    elif rest.startswith("b"):
        k -= 1
        rest = rest[1:]
    midi = 12 * (int(rest) + 1) + k
    return 440.0 * 2 ** ((midi - 69) / 12)


def t(sec):
    return np.arange(int(SR * sec)) / SR


def env(n, attack=0.005, decay=None, release=0.01):
    """Yumuşak giriş, üstel sönüm ve tıkırtısız bitiş."""
    e = np.ones(n)
    a = min(max(int(SR * attack), 1), n)
    e[:a] = np.sin(np.linspace(0, np.pi / 2, a)) ** 2
    if decay:
        e *= np.exp(-np.arange(n) / (SR * decay))
    r = min(max(int(SR * release), 1), n)
    e[-r:] *= np.cos(np.linspace(0, np.pi / 2, r)) ** 2
    return e


def osc(freq, n):
    """Sabit ya da değişen frekanslı sinüs."""
    f = np.full(n, freq) if np.isscalar(freq) else np.asarray(freq)[:n]
    return np.sin(2 * np.pi * np.cumsum(f) / SR)


# --- süzgeçler ve yankı ---------------------------------------------------------

def lp_kernel(cutoff, taps=129):
    m = np.arange(taps) - (taps - 1) / 2
    h = np.sinc(2 * cutoff / SR * m) * np.blackman(taps)
    return h / h.sum()


def conv(x, h, circular=False):
    """FFT ile evrişim. circular=True: döngü için başa sarar (kesintisiz)."""
    if circular:
        n = len(x)
        hh = np.zeros(n)
        for i in range(0, len(h), n):  # çekirdek uzunsa sararak ekle
            seg = h[i:i + n]
            hh[:len(seg)] += seg
        return np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(hh), n)
    n = len(x) + len(h) - 1
    size = 1 << (n - 1).bit_length()
    return np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(h, size), size)[:n]


def lowpass(x, cutoff, circular=False):
    h = lp_kernel(cutoff)
    if circular:
        return np.roll(conv(x, h, True), -(len(h) // 2))
    return conv(x, h)[len(h) // 2: len(h) // 2 + len(x)]


def reverb_ir(sec=1.8, decay=0.45, tone=3200, predelay=0.012):
    """Sönümlenen, koyulaştırılmış gürültüden oda yankısı."""
    n = int(SR * sec)
    x = np.arange(n) / SR
    bright = lowpass(rng.standard_normal(n), tone)
    dark = lowpass(rng.standard_normal(n), tone / 3)
    mixk = np.minimum(1, x / sec * 2)  # zamanla daha boğuk
    ir = ((1 - mixk) * bright + mixk * dark) * np.exp(-x / decay)
    ir *= env(n, 0.01)
    ir = np.concatenate([np.zeros(int(SR * predelay)), ir])
    return ir / np.sqrt(np.sum(ir ** 2))


def echo_ir(delay, fb=0.35, repeats=6):
    """Geri beslemeli gecikme (her tekrarda biraz daha boğuk)."""
    d = int(SR * delay)
    h = np.zeros(d * repeats + 1)
    for k in range(1, repeats + 1):
        h[d * k] = fb ** k
    return lowpass(h, 2500)


def roomy(x, wet=0.18, tail=0.8):
    """Kısa efektlere hafif oda yankısı (kuyruğu ekler)."""
    x = np.concatenate([x, np.zeros(int(SR * tail))])
    y = x + wet * conv(x, reverb_ir(tail + 0.4, 0.22))[:len(x)]
    return y * env(len(y), 0.0005, release=0.15)


# --- çalgılar -------------------------------------------------------------------

def partials(f, sec, parts, attack=0.003):
    """parts: (oran, genlik, sönüm) listesi; Nyquist üstü atlanır."""
    n = int(SR * sec)
    out = np.zeros(n)
    for ratio, amp, dec in parts:
        if f * ratio < NYQ * 0.85:
            out += amp * osc(f * ratio, n) * env(n, attack, dec, 0.02)
    return out


def marimba(f, sec=1.2):
    d = 0.55 * (440 / f) ** 0.4  # tizler daha çabuk söner
    return partials(f, sec, [(1, 1.0, d), (4, 0.18, d * 0.15), (2, 0.06, d * 0.4)], 0.002)


def kalimba(f, sec=1.0):
    return partials(f, sec, [(1, 1.0, 0.35), (3.0, 0.10, 0.05), (5.4, 0.04, 0.02)], 0.002)


def bell(f, sec=0.9, decay=0.35):
    return partials(f, sec, [(1, 1.0, decay), (2, 0.25, decay * 0.4), (3, 0.08, decay * 0.25),
                             (4.2, 0.03, decay * 0.15)], 0.002)


def pad(freqs, sec):
    n = int(SR * sec)
    out = np.zeros(n)
    for f in freqs:
        for det in (0.997, 1.003):
            out += osc(f * det, n) + 0.15 * osc(2 * f * det, n)
    return out * env(n, 0.45, release=min(0.7, sec / 2)) / len(freqs)


def bass(f, sec):
    return partials(f, sec, [(1, 1.0, 0.8), (2, 0.25, 0.25), (3, 0.05, 0.1)], 0.012)


def soft_noise(sec, lo=None, hi=None):
    n = int(SR * sec) + 256
    x = rng.standard_normal(n)
    if hi:
        x = lowpass(x, hi)
    if lo:
        x = x - lowpass(x, lo)
    return x[128:128 + int(SR * sec)]


def kick(sec=0.22):
    x = t(sec)
    f = 50 + 60 * np.exp(-x / 0.03)
    return osc(f, len(x)) * env(len(x), 0.003, 0.07)


def tok(f=620, sec=0.08):
    """Darbuka 'tek'ine benzeyen yumuşak tahta tıkırtısı."""
    return partials(f, sec, [(1, 1.0, 0.018), (1.6, 0.3, 0.01)], 0.001)


def shaker(sec=0.07):
    x = soft_noise(sec, lo=2500, hi=7000)
    return x * env(len(x), 0.008, 0.02)


def voice(f0, formants, tilt=0.3, nh=30):
    """Harmonik ses + formantlar (hayvan sesleri için). fc dizi olabilir."""
    f0 = np.asarray(f0)
    phase = 2 * np.pi * np.cumsum(f0) / SR
    out = np.zeros(len(f0))
    for k in range(1, nh + 1):
        fk = k * f0
        amp = tilt / k + sum(a * np.exp(-((fk - fc) / bw) ** 2) for fc, bw, a in formants)
        out += amp * (fk < NYQ * 0.8) * np.sin(k * phase)
    return out


def mix(*parts):
    n = max(int(start * SR) + len(p) for start, p in parts)
    out = np.zeros(n)
    for start, p in parts:
        s = int(start * SR)
        out[s:s + len(p)] += p
    return out


def save(name, x, peak=0.5):
    x = np.nan_to_num(x)
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    data = (x * 32767).astype(np.int16)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


# --- efektler -----------------------------------------------------------------

def sfx():
    # tap: yumuşak, baloncuklu "pop"
    n = int(SR * 0.07)
    x = np.arange(n) / SR
    pop = osc(380 + 520 * (1 - np.exp(-x / 0.012)), n) * env(n, 0.002, 0.018)
    save("tap", lowpass(pop, 3500), 0.4)

    # good: iki notalı hoş çan
    save("good", roomy(lowpass(mix((0, bell(hz("G5"), 0.6, 0.3)),
                                   (0.1, bell(hz("D6"), 0.8, 0.35))), 5000)), 0.5)

    # bad: yumuşak, alçak "bup-bup"
    def boop(f0, f1, sec):
        m = int(SR * sec)
        return (osc(np.linspace(f0, f1, m), m) + 0.12 * osc(np.linspace(2 * f0, 2 * f1, m), m)) \
            * env(m, 0.015, 0.12, 0.04)
    save("bad", lowpass(mix((0, boop(260, 235, 0.16)), (0.17, boop(205, 175, 0.26))), 1500), 0.4)

    # win: kısa, mutlu arpej (Do majör) + çan
    arp = ["C5", "E5", "G5", "C6"]
    win = mix(*[(i * 0.09, marimba(hz(k), 0.9)) for i, k in enumerate(arp)],
              (0.36, 0.5 * bell(hz("E6"), 1.0, 0.4)), (0.36, 0.4 * bell(hz("G5"), 1.0, 0.4)))
    save("win", roomy(lowpass(win, 5500), 0.22), 0.55)

    # levelup: pırıltılı yükselen arpej
    up = ["G5", "A5", "B5", "D6", "E6", "G6"]
    parts = [(i * 0.065, kalimba(hz(k), 0.8)) for i, k in enumerate(up)]
    parts.append((0.42, 0.6 * bell(hz("B6"), 1.2, 0.45)))
    parts.append((0.42, 0.5 * bell(hz("G6") * 1.004, 1.2, 0.45)))
    save("levelup", roomy(lowpass(mix(*parts), 6000), 0.25, 1.0), 0.5)

    # coin: yumuşak çan "din-ding"
    save("coin", roomy(lowpass(mix((0, 0.7 * bell(hz("B5"), 0.25, 0.08)),
                                   (0.07, bell(hz("E6"), 0.6, 0.25))), 5000), 0.15), 0.45)

    # stir: yumuşak baloncuklar
    bubbles = []
    for i in range(6):
        f = rng.uniform(350, 650)
        m = int(SR * 0.06)
        xb = np.arange(m) / SR
        b = osc(f * (1 + 0.9 * (1 - np.exp(-xb / 0.02))), m) * env(m, 0.004, 0.018)
        bubbles.append((i * 0.075 + rng.uniform(0, 0.025), b * rng.uniform(0.6, 1.0)))
    save("stir", lowpass(mix(*bubbles), 3000), 0.35)

    # meow: sevimli, yumuşak miyav ("i"den "av"a)
    dur = 0.55
    x = t(dur)
    morph = x / dur
    f0 = 600 + 330 * np.sin(np.pi * morph) ** 1.5 - 150 * morph
    v = voice(f0, [(2000 - 1200 * morph, 450, 1.0), (900, 300, 0.4)], 0.4, 12)
    if False:  # artık gerçek kayıt (assets/sounds/HAYVAN_SESLERI_LISANS.txt)
        save("meow", lowpass(v * env(len(x), 0.05, release=0.15), 4000), 0.42)

    # whoosh: havadar, yumuşak hışırtı (boğuktan parlağa geçen süzgeç)
    sec = 0.4
    a = soft_noise(sec, hi=700)
    b = soft_noise(sec, lo=400, hi=2200)
    k = np.linspace(0, 1, len(a))
    w = (1 - k) * a / np.std(a) + k * b / np.std(b)
    save("whoosh", w * np.sin(np.pi * k) ** 2, 0.25)

    # step: çok hafif adım tıkırtısı (~60 ms)
    sec = 0.06
    x = t(sec)
    thump = osc(110 + 90 * np.exp(-x / 0.008), len(x)) * env(len(x), 0.001, 0.014)
    tick = soft_noise(sec, lo=300, hi=1800) * env(len(x), 0.0005, 0.006)
    save("step", lowpass(thump + 0.08 * tick, 2200), 0.25)

    # moo: kısa, sevimli "möö"
    dur = 0.75
    x = t(dur)
    m = x / dur
    f0 = 185 + 35 * np.sin(np.pi * m * 0.8) - 45 * m ** 2 + 2.5 * np.sin(2 * np.pi * 5 * x)
    opn = np.minimum(1, m * 4)
    v = voice(f0, [(260 + 200 * opn, 150, 1.0), (650 + 250 * opn, 250, 0.5)], 0.35, 30)
    if False:  # artık gerçek kayıt (assets/sounds/HAYVAN_SESLERI_LISANS.txt)
        save("moo", lowpass(v * env(len(x), 0.08, release=0.2), 2200), 0.42)

    # cluck: "gıt gıt gıdak"
    def bok(sec, fa, fb):
        xx = t(sec)
        f = fb + (fa - fb) * np.exp(-xx / (sec * 0.4))
        vv = voice(f, [(1300, 400, 1.0), (2500, 500, 0.3)], 0.25, 14)
        return vv * env(len(xx), 0.004, sec * 0.45, 0.02)
    if False:  # artık gerçek kayıt (assets/sounds/HAYVAN_SESLERI_LISANS.txt)
        save("cluck", lowpass(mix((0, bok(0.09, 680, 470)), (0.13, bok(0.09, 700, 480)),
                              (0.29, bok(0.17, 820, 520))), 3800), 0.38)

    # quack: kısa, sevimli "vak"
    sec = 0.26
    x = t(sec)
    f0 = 300 + 130 * np.exp(-x / 0.08)
    v = voice(f0, [(1100, 300, 1.0), (2100, 400, 0.5)], 0.15, 20)
    shape = np.sin(np.pi * np.minimum(1, x / sec)) ** 0.6
    if False:  # artık gerçek kayıt (assets/sounds/HAYVAN_SESLERI_LISANS.txt)
        save("quack", lowpass(v * shape * env(len(x), 0.008, release=0.04), 3800), 0.38)

    # woof: küçük köpek "hav"
    sec = 0.2
    x = t(sec)
    f0 = 200 + 150 * np.exp(-x / 0.05)
    v = voice(f0, [(650, 250, 1.0), (1250, 300, 0.45)], 0.45, 20)
    breath = soft_noise(sec, lo=300, hi=1500) * 0.06
    if False:  # artık gerçek kayıt (assets/sounds/HAYVAN_SESLERI_LISANS.txt)
        save("woof", lowpass((v / 3 + breath) * env(len(x), 0.008, 0.09, 0.03), 2800), 0.42)


# --- müzik --------------------------------------------------------------------
# Sol Rast havası: Sol La Si Do Re Mi Fa# Sol; inişte Fa naturel (Rast'ın tadı).
# 16 ölçü, 4/4, 100 BPM -> 38.4 sn.

MELODY = [
    [("B4", .5), ("D5", .5), ("G5", 1), ("F#5", .5), ("E5", .5), ("D5", 1)],
    [("E5", .5), ("D5", .5), ("C5", 1), ("E5", 1), ("G5", 1)],
    [("F#5", 1), ("E5", .5), ("D5", .5), ("A4", 1), ("D5", 1)],
    [("B4", 1.5), ("A4", .5), ("G4", 2)],
    [("G4", .5), ("A4", .5), ("B4", 1), ("E5", 1), ("D5", 1)],
    [("C5", .5), ("D5", .5), ("E5", 1), ("G5", 1), ("E5", 1)],
    [("D5", .5), ("C5", .5), ("B4", .5), ("A4", .5), ("C5", 1), ("E5", 1)],
    [("D5", 3), (None, 1)],
    [("G5", .5), ("F#5", .5), ("G5", 1), ("D5", 1), ("B4", 1)],
    [("C5", .5), ("E5", .5), ("G5", 1), ("A5", 1), ("G5", 1)],
    [("F#5", .5), ("E5", .5), ("D5", 1), ("A4", 1), ("F#5", 1)],
    [("E5", 2), ("B4", 1), (None, 1)],
    [("E5", .5), ("F5", .5), ("G5", 1), ("F5", .5), ("E5", .5), ("D5", 1)],
    [("C5", .5), ("D5", .5), ("E5", 1), ("D5", .5), ("C5", .5), ("A4", 1)],
    [("B4", .5), ("C5", .5), ("D5", 1), ("C5", .5), ("A4", .5), ("F#4", 1)],
    [("G4", 3), (None, 1)],
]

# (pad akoru, bas kök, bas beşli)
G, C, D, EM, AM, D7 = (["G3", "B3", "D4"], "G2", "D3"), (["G3", "C4", "E4"], "C3", "G2"), \
    (["A3", "D4", "F#4"], "D3", "A2"), (["G3", "B3", "E4"], "E3", "B2"), \
    (["A3", "C4", "E4"], "A2", "E3"), (["A3", "C4", "F#4"], "D3", "A2")
CHORDS = [G, C, D, G, EM, C, AM, D, G, C, D, EM, C, AM, D7, G]


def music():
    beat = 60 / 100
    bar = 4 * beat
    total = len(MELODY) * bar
    n = int(round(total * SR))
    out = np.zeros(n + SR * 4)

    def put(start, x, gain):
        s = int(round(start * SR))
        out[s:s + len(x)] += x * gain

    for b, (notes, (chord, root, fifth)) in enumerate(zip(MELODY, CHORDS)):
        b0 = b * bar
        # ezgi: marimba (+ çok hafif kalimba ikizi oktav yukarıda)
        pos = b0
        for note, length in notes:
            if note:
                f = hz(note)
                put(pos, marimba(f, length * beat + 0.9), 0.5)
                put(pos, kalimba(f * 2, 0.6), 0.05)
            pos += length * beat
        # sıcak pad ve bas
        put(b0, pad([hz(k) for k in chord], bar + 0.6), 0.16)
        put(b0, bass(hz(root), 2 * beat + 0.3), 0.42)
        put(b0 + 2 * beat, bass(hz(fifth), 2 * beat + 0.3), 0.32)
        # ikinci yarıda: arka planda yumuşak kalimba arpeji
        if b >= 8:
            tones = [hz(k) * 2 for k in chord]
            for i in range(4):
                put(b0 + i * beat + beat / 2, kalimba(tones[i % 3], 0.7), 0.07)
        # vurmalılar: düm (1, 3), tek (2, 4), hafif shaker (sekizlikler)
        for i in range(4):
            s = b0 + i * beat
            if i in (0, 2):
                put(s, kick(), 0.32)
            else:
                put(s, tok(), 0.07)
            put(s, shaker(), 0.035)
            put(s + beat / 2, shaker(), 0.05)
        if b % 4 == 3:  # dört ölçüde bir küçük "tek-tek" süsü
            put(b0 + 3.5 * beat, tok(700), 0.05)

    # döngü: taşan kuyruğu başa ekle, böylece tekrar ederken kesinti olmaz
    tail = out[n:]
    out = out[:n]
    out[:len(tail)] += tail[:len(out)]

    # yankı + oda yankısı + yumuşatma: hepsi dairesel, döngü dikişsiz kalır
    out = out + 0.16 * conv(out, echo_ir(beat * 0.75, 0.35), circular=True)
    out = out + 0.30 * conv(out, reverb_ir(2.4, 0.6, 3000), circular=True)
    out = lowpass(out, 4500, circular=True)
    save("muzik", out, 0.6)


# --- konuşma mırıltısı -------------------------------------------------------------

## Ünlü formantları (F1, F2, F3) Hz: tatlı, kadınsı bir ses için.
VOWELS = {"a": (850, 1300, 2800), "e": (560, 2000, 2800), "i": (360, 2500, 3100),
          "o": (520, 950, 2600), "u": (380, 850, 2500)}


def voices():
    """Teyzelerin konuşurken çıkardığı kısa, anlamsız heceler (Animal Crossing
    gibi). Oyun her heceyi konuşanın perdesinde çalar."""
    for v, (f1, f2, f3) in VOWELS.items():
        sec = 0.09
        n = int(SR * sec)
        f0 = np.linspace(255, 232, n) * (1 + 0.012 * np.sin(np.arange(n) / SR * 2 * np.pi * 6))
        x = voice(f0, [(f1, 110, 1.0), (f2, 160, 0.55), (f3, 220, 0.18)], tilt=0.18, nh=24)
        x = lowpass(x * env(n, 0.01, release=0.035), 3800)
        save("ses_" + v, x, 0.4)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    import sys
    if sys.argv[1:] == ["voices"]:
        voices()
        return
    sfx()
    voices()
    music()
    print("sounds ->", OUT)
    for p in sorted(OUT.glob("*.wav")):
        with wave.open(str(p), "rb") as w:
            frames = w.readframes(w.getnframes())
            x = np.frombuffer(frames, np.int16) / 32767
            print(f"  {p.name:12s} {w.getnframes() / w.getframerate():6.2f} s  "
                  f"peak={np.max(np.abs(x)):.2f}")


if __name__ == "__main__":
    main()
