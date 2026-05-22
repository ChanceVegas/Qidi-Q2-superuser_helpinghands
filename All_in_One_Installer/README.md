# Qidi Q2 Superuser - All-in-One Installer

> **Disclaimer:** Use this tool at your own risk. The author is not responsible for any damage, malfunction, or data loss caused to your printer. Qidi states that any modifications to files on their printers may void the manufacturer warranty.

A single menu that handles every install, uninstall, and addon path for the Qidi Q2 community toolkit — no more tracking which script does what.

```
============================================
   Qidi Q2 Superuser - AIO Setup Menu (RC9)
============================================
  BunnyBox: not found | HelixScreen: not found | IdleFan: off | BoxWrite: off | Mainsail: not found
--------------------------------------------
  INSTALL
   1) Install BunnyBox & HelixScreen   (Q2 with Qidi Box)
   2) Install Just Faster Printer      (Q2 without Box)
  UNINSTALL
   3) Revert to Backup                 (full uninstall + restore stock)
  ADDONS
   4) Idle Fan Shutdown                (10m idle, temp-gated)
   5) Mainsail                         (web UI on port 100)
  INFO
   6) About
   7) Health Check / Run Verifiers
   0) Exit
============================================
```

## Requirements

- Qidi Q2 running stock Klipper firmware
- SSH access as user `mks` (the default Qidi user)
- Internet access from the printer
- **Do not run as root** — the script will refuse to start

## Install

SSH into the Q2 as `mks`, then:

**One-liner:**
```bash
curl -sSL https://raw.githubusercontent.com/ChanceVegas/Qidi-Q2-superuser_helpinghands/refs/heads/main/All_in_One_Installer/aio_menu.sh | bash
```

**Download first (review before running):**
```bash
curl -fsSL -o aio_menu.sh \
  https://raw.githubusercontent.com/ChanceVegas/Qidi-Q2-superuser_helpinghands/refs/heads/main/All_in_One_Installer/aio_menu.sh
chmod +x aio_menu.sh
./aio_menu.sh
```

## Menu options

| # | Option | What it does |
|---|--------|-------------|
| 1 | **Install BunnyBox & HelixScreen** | For Q2 owners with a Qidi Box. Installs Happy Hare MMU firmware and the HelixScreen UI, applies optimised Klipper configs, and enables filament drying with automatic spool rotation. |
| 2 | **Install Just Faster Printer** | For Q2 owners without a Box. Keeps the stock Qidi screen but adds cleaner macros, faster print start, adaptive bed meshing, and Spoolman support. |
| 3 | **Revert to Backup** | Fully uninstalls everything AIO has installed and restores your printer to the state it was in before the first AIO run. Runs a health check automatically at the end. |
| 4 | **Idle Fan Shutdown** | Addon toggle. Shuts off fans and heaters after 10 minutes idle, but only once all temps have dropped to safe levels. |
| 5 | **Mainsail** | Addon toggle. Installs the Mainsail web interface, accessible at `http://<printer-ip>:100`. Qidi's stock UI on port 80 is unaffected. |
| 6 | **About** | Shows the current AIO version and a brief description. |
| 7 | **Health Check / Run Verifiers** | Scans your Klipper config for common problems — duplicate macros, broken include lines, invalid settings — and offers to fix each one before applying it. Safe to run any time. |

## Filament drying (BunnyBox install only)

After installing BunnyBox, the following one-tap drying macros are available from the Klipper console or HelixScreen. Spools rotate automatically throughout each cycle.

| Macro | Temp | Time |
|---|---|---|
| `DRY_PLA` | 45 °C | 4 h |
| `DRY_PETG` | 65 °C | 4 h |
| `DRY_ABS` | 65 °C | 4 h |
| `DRY_TPU` | 55 °C | 4 h |
| `DRY_PA` | 70 °C | 8 h |

## After installing BunnyBox & HelixScreen

1. Run `FIRMWARE_RESTART` from the Klipper console or HelixScreen.
2. Run **option 7 (Health Check)** to verify everything loaded correctly.
3. **First-time only:** calibrate the MMU gear steppers:
   ```
   MMU_CALIBRATE_GEAR GATE=0 LENGTH=100
   ```
   Mark the filament at the entry point, measure how far it moved, then re-run with `MEASURED=<mm>`. Repeat for each gate.
4. Load filament into each gate and start a drying preset if needed.

## After installing Just Faster Printer

1. Run `FIRMWARE_RESTART`.
2. Run a bed level and `SCREWS_TILT_CALCULATE` before your first print.

## Release history

| Version | Notable additions |
|---------|------------------|
| RC9 | Automatic spool rotation during filament drying cycles |
| RC8 | Health check runs automatically after every Revert to Backup; new config validators (orphan includes, invalid settings, leftover MMU files) |
| RC7 | Mainsail web UI as a menu addon (option 5) |
| RC6 | Fixed `BED_MESH_CALIBRATE` duplicate crash from older BunnyBox installs |
| RC5 | Fixed Klipper startup crash caused by conflicting Box hardware drivers |
| RC4 | Simplified uninstall — Revert to Backup is now the single restore path |
| RC1–3 | Initial AIO release; HelixScreen + BunnyBox install/uninstall; idle fan shutdown addon |

## Known limitations

- **Native Qidi Box AMS panel is unavailable while BunnyBox is installed.** Revert to Backup restores it.
- **HelixScreen has no built-in dryer UI.** Use the `DRY_*` macros from the console, or add them as HelixScreen macro shortcuts (gear icon → Macros → Add).
- **MMU gear calibration is required after a fresh install.**
- **BunnyBox requires HelixScreen** — the stock Qidi screen doesn't expose the MMU interface.

## Troubleshooting

**`ERROR: Cannot reach raw.githubusercontent.com`** — No internet from the printer. Check network settings.

**`ERROR: Config directory not found`** — Not running as `mks`, or this isn't a Klipper-based Q2.

**Klipper won't start after install** — Run option 7 (Health Check). It will identify and offer to fix the most common causes.

**Klipper won't start after uninstall** — Use option 3 (Revert to Backup) for a clean restore.

**No stock backup exists** — `/home/mks/mudstockbackups/` is created automatically on first run. If configs were already changed before the first AIO run, restore from a Qidi factory image first, then run AIO to capture a clean baseline.

## Links

- Repo: https://github.com/ChanceVegas/Qidi-Q2-superuser_helpinghands
- Upstream: https://github.com/Camden-Winder/Qidi-Q2-superuser
- BunnyBox: https://github.com/Camden-Winder/Bunny-Box
- HelixScreen: https://github.com/prestonbrown/helixscreen
- Mainsail: https://github.com/mainsail-crew/mainsail
