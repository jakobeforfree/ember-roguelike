#!/usr/bin/env python3
"""Downloads only the Web export templates out of Godot's ~1 GB template archive
using HTTP range requests (the .tpz is a zip; we read its directory, then just
the entries we need). Standard library only, so it runs on any CI/Vercel image."""
import os, struct, sys, urllib.request, zlib

VERSION = sys.argv[1] if len(sys.argv) > 1 else "4.3-stable"
URL = f"https://github.com/godotengine/godot/releases/download/{VERSION}/Godot_v{VERSION}_export_templates.tpz"
WANT = {"templates/version.txt", "templates/web_nothreads_release.zip", "templates/web_nothreads_debug.zip"}
OUT = os.path.expanduser(f"~/.local/share/godot/export_templates/{VERSION.replace('-', '.')}")


def fetch(a, b=None):
    req = urllib.request.Request(URL, headers={"Range": f"bytes={a}-{'' if b is None else b}"})
    with urllib.request.urlopen(req) as r:
        return r.read()


def main():
    with urllib.request.urlopen(urllib.request.Request(URL, method="HEAD")) as r:
        size = int(r.headers["Content-Length"])
    tail = fetch(size - 65536, size - 1)
    i = tail.rfind(b"PK\x05\x06")
    cd_size, cd_off = struct.unpack("<II", tail[i + 12:i + 20])
    cd = fetch(cd_off, cd_off + cd_size - 1)
    os.makedirs(OUT, exist_ok=True)
    p = 0
    while p < len(cd):
        f = struct.unpack("<IHHHHHHIIIHHHHHII", cd[p:p + 46])
        meth, csz, nl, el, cl, lho = f[4], f[8], f[10], f[11], f[12], f[16]
        name = cd[p + 46:p + 46 + nl].decode()
        p += 46 + nl + el + cl
        if name not in WANT:
            continue
        h = fetch(lho, lho + 29)
        nl2, el2 = struct.unpack("<HH", h[26:30])
        start = lho + 30 + nl2 + el2
        data = fetch(start, start + csz - 1)
        if meth == 8:
            data = zlib.decompress(data, -15)
        with open(os.path.join(OUT, os.path.basename(name)), "wb") as fh:
            fh.write(data)
        print("extracted", name, len(data))


main()
