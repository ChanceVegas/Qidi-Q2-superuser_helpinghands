# CLAUDE.md - Qidi Q2 Superuser AIO

Project context for coding sessions. Read this first every time.

## Quick Start

```bash
git status --short --branch
rg -n "AIO_VERSION|install_klipperscreen|prepare_display_for_klipperscreen" All_in_One_Installer/aio_menu.sh
bash -n All_in_One_Installer/aio_menu.sh
python3 -m json.tool Install-Script/helixscreen_settings.json
```

Run `shellcheck -S warning All_in_One_Installer/aio_menu.sh` when available. Treat shellcheck as advisory unless a finding is clearly unsafe.

## Project

This repo contains a Bash-based all-in-one installer menu for the Qidi Q2 Pro 3D printer. The main artifact is:

```text
All_in_One_Installer/aio_menu.sh
```

Everything runs on the printer over SSH as user `mks`.

Current baseline:

```text
Repo: https://github.com/ChanceVegas/Qidi-Q2-superuser_helpinghands
Main version: RC1.30
Working branches: claude/*
```

## Target Environment

- Device: Qidi Q2 Pro 3D printer
- SoC: Rockchip aarch64, kernel 5.10.160
- OS: Debian Bullseye ARM, user `mks`
- Console: `ttyFIQ0` UART serial, not a VT console
- No VT subsystem: `/dev/tty0` does not exist at boot
- DRM/KMS: `/dev/dri/card0` via Rockchip VOP display-subsystem
- Stack: Klipper, Moonraker, Happy Hare, HelixScreen, Qidi Box

Key printer paths:

```text
/home/mks/printer_data/config/   Klipper config root
/home/mks/mudstockbackups/       AIO backup snapshots
/home/mks/helixscreen/           HelixScreen install dir
/home/mks/Happy-Hare/            Happy Hare MMU firmware
/home/mks/KlipperScreen/         KlipperScreen install dir
```

## Repo Layout

```text
All_in_One_Installer/
  aio_menu.sh                         Main artifact
  README.md
  WHAT_WAS_DONE.md
  KLIPPERSCREEN_DISPLAY_INVESTIGATION.md

Install-Script/
  BunnyBox&HelixScreen.sh             Legacy single-shot installer
  helixscreen_settings.json
  idle_fan_shutdown.cfg
  box_drying.cfg
  mmu/
  printer(BunnyBox&HelixScreen).cfg
  gcode_macro-BunnyBox&HelixScreen.cfg

Configurations/                       Stock Qidi reference files; do not modify
Plugins/                              Stock plugin reference; do not modify

CLAUDE.md                             Operating rules and current context
HANDOFF.md                            Current project state and next work
```

## Critical Rules

1. Never modify `Configurations/` or `Plugins/`.
2. Never push directly to `main`; work on `claude/*` branches and merge by PR.
3. Bump `AIO_VERSION` on every `aio_menu.sh` change. Format is `RC<major>.<minor>`. Next version after `RC1.30` is `RC1.31`.
4. Run `bash -n All_in_One_Installer/aio_menu.sh` before every commit touching shell.
5. Run `python3 -m json.tool` before every commit touching JSON.
6. Never use raw `echo` in installer logic. Use `banner`, `info`, `warn`, `ok`, and `err`.
7. Use the `sudo tee` pattern for elevated file writes.
8. Use the `fetch()` helper for all remote downloads; do not add raw `curl` downloads.
9. Do not run `aio_menu.sh` as root; it self-enforces this.

## Current Menu

```text
INSTALL
 1) Install BunnyBox & HelixScreen    (Q2 with Qidi Box)
 2) Install KlipperScreen             (temporarily disabled)
 3) Install Just Faster Printer       (Q2 without Box)
UNINSTALL
 4) Revert to Backup                  (full uninstall + restore stock)
ADDONS
 5) Idle Fan Shutdown                 (10m idle, temp-gated)
 6) Mainsail                          (web UI on port 100)
INFO
 7) About
 8) Health Check / Run Verifiers
 0) Exit
```

Option 2 is disabled in the menu with:

```text
KlipperScreen install is temporarily disabled - display issue under investigation.
```

The `install_klipperscreen()` function is preserved for re-enablement.

## Install Function Registry

| Function | Feature | Status indicator |
|---|---|---|
| `install_bunnybox_helixscreen()` | Happy Hare + HelixScreen | `BunnyBox`, `Display` |
| `install_klipperscreen()` | KlipperScreen HH Edition | `Display` |
| `install_just_faster()` | JustFasterPrinter macros | none |
| `install_idle_fan_shutdown()` | 10m idle fan/heater shutdown | `IdleFan` |
| `install_qidi_box_write()` | HelixScreen Qidi Box write drop-in | `BoxWrite` |
| `install_mainsail()` | Mainsail web UI on port 100 | `Mainsail` |

New installer capabilities should include an `install_*` function, matching uninstall/cleanup path where applicable, detection helper, revert integration, status indicator when user-visible, and verifier when risk warrants it.

## KlipperScreen Problem

Outstanding work is tracked in:

```text
All_in_One_Installer/KLIPPERSCREEN_DISPLAY_INVESTIGATION.md
```

Short version: upstream KlipperScreen uses `xinit`, which launches Xorg through a VT-dependent path. The Q2 kernel has no real VT subsystem, so `/dev/tty0` tricks do not solve it. Investigate Cage/Wayland first, then explicit Xorg options, then keeping/restoring lightdm.

## Autonomous Session Policy

May do without asking:

- Commit and push to any `claude/*` branch.
- Create a draft PR after pushing.
- Run `bash -n`, `shellcheck`, and `python3 -m json.tool`.
- Merge a PR to `main` only when explicitly told to.

Must ask first:

- Push directly to `main`.
- Force-push any branch.
- Delete branches or files not created in the same session.
- Change repo settings, secrets, branch protections, or other admin controls.

## Release History Snapshot

| Version | What changed |
|---|---|
| RC1.30 | Option 2 disabled pending display fix; function preserved |
| RC1.29 | `ExecStartPre` creates `/dev/tty0`; still insufficient |
| RC1.28 | Clears upstream `ConditionPathExists=/dev/tty0` gate |
| RC1.27 | Option 2 decoupled from BunnyBox |
| RC1.26 | Uses upstream KlipperScreen installer with `NETWORK=N` |
| RC1.25 | Fixes shallow clone and premature service start issues |
| RC1.24 | Fixes service group, clone detection, daemon reload ordering |
| RC1.23 | Tried lightdm `:0` client approach, later abandoned |
| RC1.22 | Removed KlipperScreen option; added drying macro buttons |
| RC1.14 | Adopted `RC<major>.<minor>` version format |
| RC13-RC1 | Initial AIO release line and hardening fixes |
