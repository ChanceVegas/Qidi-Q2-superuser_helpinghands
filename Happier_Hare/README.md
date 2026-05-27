# Happier Hare

Happier Hare is the Qidi Q2 compatibility layer for HelixScreen's Happy Hare
backend. Its first job is native Qidi Box drying in HelixScreen without relying
on macro buttons.

## Goal

On BunnyBox installs, Happy Hare owns the Qidi Box hardware. HelixScreen
v0.99.70 already contains an AMS environment/dryer overlay, but its Happy Hare
backend does not expose that overlay on the Q2 path. Happier Hare patches that
backend so the native environment indicator and dryer controls can appear.

## Patch Set

`patches/helixscreen-v0.99.70-happier-hare.patch` changes HelixScreen v0.99.70:

- exposes Happy Hare as an environment-capable backend for the AMS panel
- marks Happy Hare dryer support available for the Qidi/BunnyBox path
- shows the environment indicator even when Happy Hare has no separate humidity
  sensor value to publish
- displays dryer temperature from `DryerInfo` when per-unit environment data is
  absent
- sends `MMU_HEATER DRY=1 TEMP=... TIMER=...` instead of `DURATION=...`
- sends `MMU_HEATER STOP=1` for stop, matching Happy Hare's command parser

## Installer

`install_happier_hare.sh` supports three paths:

```bash
# Install a prebuilt patched HelixScreen zip
./install_happier_hare.sh --install-zip URL

# Clone HelixScreen v0.99.70 and apply the source patch
./install_happier_hare.sh --patch-source

# Patch, build, and install locally when a Pi DRM toolchain is available
./install_happier_hare.sh --build-source
```

On the printer, the expected production path is a prebuilt patched zip supplied
through `HAPPIER_HARE_ZIP_URL` or `--install-zip`. The AIO also probes the
stable release asset `happier-hare-rc2.0/helixscreen-pi.zip` and installs it
automatically once that asset exists.

Local source builds target the Pi DRM binary used on the Qidi Q2
(`/dev/dri/card0`) and require the `aarch64-linux-gnu-g++` toolchain.

## RC2.0 Scope

RC2.0 should not remove the macro buttons yet. They remain the fallback and a
diagnostic path. The native HelixScreen dryer control becomes the primary path
after a patched HelixScreen artifact is installed and verified on hardware.
