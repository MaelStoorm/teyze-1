#!/usr/bin/env python3
"""Google Play'e gidecek AAB'yi imzaya hazırlar ve denetler.

1. AAB'de eski bir imza varsa siler: META-INF/*.SF, *.RSA, *.DSA, *.EC dosyaları ve
   META-INF/MANIFEST.MF içindeki dosya özetleri. Böylece yükleme anahtarıyla jarsigner
   temiz bir dosyaya imza atar.
2. Paket adını, sürüm kodunu, min/hedef SDK'yı export_presets.cfg ile karşılaştırır
   (bundletool dump manifest ile).
3. arm64-v8a ve armeabi-v7a için Godot kütüphanesinin AAB'de olduğunu, 64 bit
   kütüphanelerin 16 KB sayfa boyutuna uygun hizalandığını kontrol eder.

Kullanım:
    python3 tools/aab_denetle.py build/fatma-teyze-unsigned.aab \
        --bundletool bundletool-all.jar [--presets export_presets.cfg]
"""
import argparse
import os
import re
import struct
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
import zipfile

ANDROID_NS = "{http://schemas.android.com/apk/res/android}"
SIGNATURE_EXT = (".SF", ".RSA", ".DSA", ".EC")
ABIS = ("arm64-v8a", "armeabi-v7a")
PAGE_16K = 0x4000

errors = []


def fail(msg):
    errors.append(msg)
    print("HATA: " + msg)


def read_android_preset(path):
    """export_presets.cfg içinden Android önayarının ayarlarını okur."""
    sections = {}
    current = None
    with open(path, encoding="utf-8") as f:
        for line in f:
            header = re.match(r"^\[(.+)\]\s*$", line)
            if header:
                current = sections.setdefault(header.group(1), {})
                continue
            kv = re.match(r"^([A-Za-z0-9_/.\-]+)=(.*)$", line.rstrip("\n"))
            if kv and current is not None:
                current[kv.group(1)] = kv.group(2).strip('"')
    for name, values in sections.items():
        if values.get("platform") == "Android" and name + ".options" in sections:
            return sections[name + ".options"]
    sys.exit("export_presets.cfg içinde Android önayarı yok")


def manifest_main_section(data):
    """MANIFEST.MF'nin yalnızca ana bölümünü (dosya özetleri olmadan) bırakır."""
    text = data.decode("utf-8").replace("\r\n", "\n")
    head = text.split("\n\n", 1)[0].strip("\n")
    return (head + "\n\n").replace("\n", "\r\n").encode("utf-8")


def strip_signature(aab):
    with zipfile.ZipFile(aab) as z:
        infos = z.infolist()
        sig = [i.filename for i in infos
               if i.filename.startswith("META-INF/") and i.filename.upper().endswith(SIGNATURE_EXT)]
        mf = z.read("META-INF/MANIFEST.MF") if "META-INF/MANIFEST.MF" in z.namelist() else None
    new_mf = manifest_main_section(mf) if mf is not None else None
    if not sig and new_mf == mf:
        print("İmza yok, AAB olduğu gibi kalıyor.")
        return
    print("İmza artıkları siliniyor: " + ", ".join(sig + (["MANIFEST.MF özetleri"] if new_mf != mf else [])))
    fd, tmp = tempfile.mkstemp(suffix=".aab", dir=os.path.dirname(os.path.abspath(aab)))
    os.close(fd)
    with zipfile.ZipFile(aab) as src, zipfile.ZipFile(tmp, "w") as dst:
        for info in src.infolist():
            if info.filename in sig:
                continue
            body = new_mf if info.filename == "META-INF/MANIFEST.MF" else src.read(info)
            dst.writestr(info, body, compress_type=info.compress_type)
    os.replace(tmp, aab)


def load_segments_aligned(elf):
    """64 bit ELF'in tüm PT_LOAD bölümleri en az 16 KB hizalı mı?"""
    if elf[:4] != b"\x7fELF" or elf[4] != 2:
        return None
    phoff = struct.unpack_from("<Q", elf, 0x20)[0]
    phentsize, phnum = struct.unpack_from("<HH", elf, 0x36)
    aligns = []
    for i in range(phnum):
        off = phoff + i * phentsize
        if struct.unpack_from("<I", elf, off)[0] == 1:  # PT_LOAD
            aligns.append(struct.unpack_from("<Q", elf, off + 0x30)[0])
    return bool(aligns) and min(aligns) >= PAGE_16K


def check_contents(aab, package):
    with zipfile.ZipFile(aab) as z:
        names = set(z.namelist())
        mpath = "base/manifest/AndroidManifest.xml"
        if mpath not in names:
            fail(mpath + " yok")
        elif package.encode() not in z.read(mpath):
            fail("AndroidManifest'te paket adı yok: " + package)
        else:
            print("Manifest: %s (%s)" % (mpath, package))
        for abi in ABIS:
            libs = sorted(n for n in names if n.startswith("base/lib/%s/" % abi) and n.endswith(".so"))
            if not any(n.endswith("/libgodot_android.so") for n in libs):
                fail("%s için libgodot_android.so yok" % abi)
                continue
            for n in libs:
                note = ""
                if abi == "arm64-v8a":
                    ok = load_segments_aligned(z.read(n))
                    note = "16 KB hizalı" if ok else "16 KB HİZALI DEĞİL"
                    if not ok:
                        fail("%s 16 KB sayfa boyutuna hizalı değil" % n)
                print("  %s %.1f MB %s" % (n, z.getinfo(n).file_size / 1e6, note))
        sig = [n for n in names if n.startswith("META-INF/") and n.upper().endswith(SIGNATURE_EXT)]
        if sig:
            fail("imza dosyaları kaldı: " + ", ".join(sig))


def check_manifest(aab, bundletool, preset):
    out = subprocess.run(["java", "-jar", bundletool, "dump", "manifest", "--bundle", aab],
                         check=True, capture_output=True, text=True).stdout
    print(out)
    root = ET.fromstring(out)
    sdk = root.find("uses-sdk")
    found = {
        "package/unique_name": root.get("package"),
        "version/code": root.get(ANDROID_NS + "versionCode"),
        "gradle_build/min_sdk": sdk.get(ANDROID_NS + "minSdkVersion") if sdk is not None else None,
        "gradle_build/target_sdk": sdk.get(ANDROID_NS + "targetSdkVersion") if sdk is not None else None,
    }
    for key, value in found.items():
        want = preset.get(key, "")
        if want and value != want:
            fail("%s: önayarda %s, AAB'de %s" % (key, want, value))
        else:
            print("%-24s %s" % (key, value))
    perms = [p.get(ANDROID_NS + "name") for p in root.iter("uses-permission")]
    print("İzinler: " + (", ".join(perms) if perms else "yok"))
    activity = root.find("application/activity")
    if activity is not None:
        print("Ekran yönü: " + str(activity.get(ANDROID_NS + "screenOrientation")))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("aab")
    ap.add_argument("--bundletool", required=True)
    ap.add_argument("--presets", default="export_presets.cfg")
    args = ap.parse_args()

    preset = read_android_preset(args.presets)
    strip_signature(args.aab)
    check_contents(args.aab, preset["package/unique_name"])
    subprocess.run(["java", "-jar", args.bundletool, "validate", "--bundle", args.aab],
                   check=True, stdout=subprocess.DEVNULL)
    print("bundletool validate: geçti")
    check_manifest(args.aab, args.bundletool, preset)

    if errors:
        sys.exit("%d sorun bulundu" % len(errors))
    print("AAB hazır: %s (%.1f MB)" % (args.aab, os.path.getsize(args.aab) / 1e6))


if __name__ == "__main__":
    main()
