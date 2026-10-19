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
    # -F: as root (a throwaway container); -d: our noarch packages need
    # nothing at build time, and Nura's packages are not in this container.
    (cd "$SRC/$dir" && REPODEST="$work" SRCDEST="$work/src" abuild -F -d -r)
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
ls -l "$OUT/$arch"
