#!/usr/bin/env python3
"""Godot'nun dışa aktardığı APK'dan Google Play için AAB üretir.

Godot AAB'yi yalnızca Gradle ile derleyebilir; Gradle de Android SDK ister.
Bu betik onun yerine Godot'nun hazır APK'sını kullanır:

  1. AndroidManifest'te targetSdkVersion'ı Play'in istediği seviyeye çeker,
  2. bundletool'un içindeki aapt2 ile kaynakları proto biçimine çevirir,
  3. dosyaları "base" modülüne dizip bundletool build-bundle ile AAB yapar.

APK'da sıkıştırılmadan (stored) duran dosyalar AAB'de de sıkıştırılmadan kalır.
İmzalama ayrıca jarsigner ile yapılır (bkz. docs/store/YAYINLAMA.md).

Kullanım:
    godot --headless --export-release Android build/teyze-unsigned.apk
    python3 tools/make_aab.py --apk build/teyze-unsigned.apk \
        --bundletool /yol/bundletool-all.jar --out build/teyze.aab [--target-sdk 36]
"""
import argparse
import json
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import zipfile

TARGET_SDK_ATTR = 0x01010270  # android:targetSdkVersion
TYPE_INT_DEC = 0x10
ADAPTIVE_ICON = "res/mipmap-anydpi-v26/icon.xml"
THEMED_ICON = "res/mipmap-anydpi-v26/themed_icon.xml"


def patch_target_sdk(axml: bytes, target: int) -> bytes:
    """Derlenmiş (ikili) AndroidManifest içindeki targetSdkVersion değerini değiştirir."""
    data = bytearray(axml)
    _, header_size, _ = struct.unpack_from("<HHI", data, 0)
    pos = header_size
    res_ids = []
    patched = 0
    while pos < len(data):
        ctype, hsize, csize = struct.unpack_from("<HHI", data, pos)
        if ctype == 0x0180:  # RES_XML_RESOURCE_MAP_TYPE
            n = (csize - hsize) // 4
            res_ids = list(struct.unpack_from("<%dI" % n, data, pos + hsize))
        elif ctype == 0x0102:  # RES_XML_START_ELEMENT_TYPE
            ext = pos + hsize
            attr_start, attr_size, attr_count = struct.unpack_from("<HHH", data, ext + 8)
            for i in range(attr_count):
                a = ext + attr_start + i * attr_size
                name = struct.unpack_from("<I", data, a + 4)[0]
                if name < len(res_ids) and res_ids[name] == TARGET_SDK_ATTR:
                    dtype = data[a + 15]
                    if dtype != TYPE_INT_DEC:
                        sys.exit("targetSdkVersion beklenmedik türde: 0x%x" % dtype)
                    old = struct.unpack_from("<I", data, a + 16)[0]
                    struct.pack_into("<I", data, a + 16, target)
                    print("targetSdkVersion %d -> %d" % (old, target))
                    patched += 1
        pos += csize
    if patched != 1:
        sys.exit("AndroidManifest'te targetSdkVersion bulunamadı (%d)" % patched)
    return bytes(data)


def module_path(name: str):
    """APK içindeki yolu AAB'deki base modülü yoluna çevirir."""
    if name.startswith("META-INF/"):
        return None  # eski imza; AAB ayrıca imzalanır
    if name == "AndroidManifest.xml":
        return "manifest/AndroidManifest.xml"
    if name == "resources.pb":
        return "resources.pb"
    if name.startswith(("res/", "assets/", "lib/")):
        return name
    if name.startswith("classes") and name.endswith(".dex"):
        return "dex/" + name
    return "root/" + name


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apk", required=True)
    ap.add_argument("--bundletool", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--target-sdk", type=int, default=36)
    args = ap.parse_args()

    tmp = tempfile.mkdtemp(prefix="aab-")
    try:
        with zipfile.ZipFile(args.bundletool) as bt:
            aapt2 = bt.extract("linux/aapt2", tmp)
        os.chmod(aapt2, 0o755)

        # 1. targetSdkVersion
        patched = os.path.join(tmp, "patched.apk")
        stored = []
        adaptive = None
        with zipfile.ZipFile(args.apk) as src, zipfile.ZipFile(patched, "w") as dst:
            for info in src.infolist():
                body = src.read(info)
                if info.filename == "AndroidManifest.xml":
                    body = patch_target_sdk(body, args.target_sdk)
                if info.filename == ADAPTIVE_ICON:
                    adaptive = body
                if info.compress_type == zipfile.ZIP_STORED and info.filename.startswith("assets/"):
                    stored.append(info.filename)
                dst.writestr(info, body, compress_type=info.compress_type)
            # Godot tek renkli katmanı icon.xml'e koyup themed_icon.xml'i siliyor, ama
            # kaynak tablosu hâlâ onu gösteriyor; aapt2 convert bu boşlukta durur.
            if THEMED_ICON not in src.namelist() and adaptive:
                dst.writestr(THEMED_ICON, adaptive)

        # 2. proto biçimi
        proto = os.path.join(tmp, "proto.apk")
        subprocess.run([aapt2, "convert", "--output-format", "proto", "-o", proto, patched], check=True)

        # 3. base modülü
        base = os.path.join(tmp, "base.zip")
        with zipfile.ZipFile(proto) as src, zipfile.ZipFile(base, "w", zipfile.ZIP_DEFLATED) as dst:
            for info in src.infolist():
                target = module_path(info.filename)
                if target and not info.is_dir():
                    dst.writestr(target, src.read(info))

        config = os.path.join(tmp, "BundleConfig.json")
        with open(config, "w") as f:
            json.dump({
                "optimizations": {
                    "splitsConfig": {"splitDimension": [
                        {"value": "ABI"},
                        {"value": "SCREEN_DENSITY", "negate": True},
                        {"value": "LANGUAGE", "negate": True},
                        {"value": "TEXTURE_COMPRESSION_FORMAT", "negate": True},
                    ]},
                    "uncompressNativeLibraries": {"enabled": True},
                },
                "compression": {"uncompressedGlob": stored},
            }, f)

        if os.path.exists(args.out):
            os.remove(args.out)
        subprocess.run(["java", "-jar", args.bundletool, "build-bundle",
                        "--modules=" + base, "--config=" + config, "--output=" + args.out], check=True)
        print("AAB hazır: %s (%.1f MB)" % (args.out, os.path.getsize(args.out) / 1e6))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    main()
