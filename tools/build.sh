#!/bin/sh
# Builds every package into one signed apk repository, inside an Alpine
# edge (aarch64) container:
#
#   docker run --rm -e RTL3D_OS_KEY -v "$PWD:/src" -w /src alpine:edge \
#       sh tools/build.sh out/edge
#
# RTL3D_OS_KEY is the private signing key (PEM); its public half is
# keys/rtl3d-os.rsa.pub, which phones get from rtl3d-os-base.
set -eu
OUT="$(mkdir -p "${1:?the folder for the repository}" && cd "$1" && pwd)"
SRC="$(pwd)"

apk add -q abuild alpine-sdk
[ -n "${RTL3D_OS_KEY:-}" ] || { echo "RTL3D_OS_KEY is not set" >&2; exit 1; }
mkdir -p /root/.abuild
printf '%s\n' "$RTL3D_OS_KEY" > /root/.abuild/rtl3d-os.rsa
chmod 600 /root/.abuild/rtl3d-os.rsa
cp keys/rtl3d-os.rsa.pub /root/.abuild/rtl3d-os.rsa.pub
cp keys/rtl3d-os.rsa.pub /etc/apk/keys/
echo 'PACKAGER_PRIVKEY=/root/.abuild/rtl3d-os.rsa' > /root/.abuild/abuild.conf

work="$(mktemp -d)"
for apkbuild in */*/APKBUILD; do
    dir="$(dirname "$apkbuild")"
    echo "== $dir"
    # -F: as root (a throwaway container). A package with makedepends (e.g.
    # plasma-mobile) gets them installed from Alpine; one without (our file
    # packages, whose depends are Nura's and not in this container) uses -d.
    if grep -q '^makedepends=' "$SRC/$apkbuild"; then deps=""; else deps="-d"; fi
    (cd "$SRC/$dir" && REPODEST="$work" SRCDEST="$work/src" abuild -F $deps -r)
done

arch="$(apk --print-arch)"
mkdir -p "$OUT/$arch"
find "$work" -name '*.apk' -exec cp {} "$OUT/$arch/" \;
cd "$OUT/$arch"
if apk mkndx --help >/dev/null 2>&1; then
    apk mkndx -q -o APKINDEX.tar.gz ./*.apk
else
    apk index -q -o APKINDEX.tar.gz ./*.apk
fi
abuild-sign -q -k /root/.abuild/rtl3d-os.rsa APKINDEX.tar.gz
# apk 3 fetches a noarch package from <repo>/noarch/, whatever the index's
# arch: the noarch ones are published there too.
mkdir -p "$OUT/noarch"
for f in ./*.apk; do
    tar -xzOf "$f" .PKGINFO 2>/dev/null | grep -qx 'arch = noarch' && cp "$f" "$OUT/noarch/"
done
ls -l "$OUT/$arch"
