# RTL@3D OS

RTL@3D OS is [Nura](https://nura.eco) (formerly postmarketOS) with a small
set of packages of ours on top: kernels and device fixes for the phones
[RTL@3D](https://apps.finailabz.com) supports, and RTL@3D itself.
Everything else comes from Nura and Alpine Linux, unchanged.

Not affiliated with or endorsed by Nura or postmarketOS.

## Packages

| Package | What it does |
|---|---|
| `rtl3d-os-base` | adds this repository and its signing key |
| `rtl3d-fairphone-fp6` | Fairphone (Gen. 6): the GNSS set-up service stops retrying for ever; PulseAudio scheduling for its speakers |

More are coming: the Fairphone 6 kernel with speaker and camera support, and
RTL@3D as packages.

## Using it

On a phone running Nura edge, as root:

```sh
wget -O /etc/apk/keys/rtl3d-os.rsa.pub https://inaim-finailabz.github.io/rtl3d-os/rtl3d-os.rsa.pub
mkdir -p /etc/apk/repositories.d
echo https://inaim-finailabz.github.io/rtl3d-os/edge > /etc/apk/repositories.d/rtl3d-os.list
apk update && apk add rtl3d-os-base
```

Then the package for your phone, e.g. `apk add rtl3d-fairphone-fp6`.

## Building

GitHub Actions builds every package on arm64 (Alpine edge) and publishes the
signed repository on GitHub Pages: `.github/workflows/build.yml`,
`tools/build.sh`.

## Licence

The packaging in this repository is GPL-3.0-or-later. Each package's own
licence is in its APKBUILD.
