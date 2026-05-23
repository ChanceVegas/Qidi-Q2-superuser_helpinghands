# Qidi Q2 Superuser - All-in-One Installer

> **Disclaimer:** Use this tool at your own risk. The author is not responsible for any damage, malfunction, or data loss caused to your printer. Qidi states that any modifications to files on their printers may void the manufacturer warranty.

A single menu that handles every install, uninstall, and addon path for the Qidi Q2 community toolkit — no more tracking which script does what.

```
============================================
   Qidi Q2 Superuser - AIO Setup Menu (RC1.20)
============================================
  BunnyBox: not found | Display: none | IdleFan: off | BoxWrite: off
  Mainsail: not found | Camera: off
--------------------------------------------
  INSTALL
   1) Install BunnyBox & HelixScreen    (Q2 with Qidi Box)
   2) Install BunnyBox & KlipperScreen  (Q2 with Qidi Box, alt UI)
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
| 1 | **Install BunnyBox & HelixScreen** | For Q2 owners with a Qidi Box. Installs Happy Hare MMU firmware and the HelixScreen touchscreen UI, applies optimised Klipper configs, and enables filament drying with automatic spool rotation. |
| 2 | **Install BunnyBox & KlipperScreen** | Same as option 1 but uses KlipperScreen instead of HelixScreen. KlipperScreen runs as an X11 client on the printer's existing display. Choose this if you prefer KlipperScreen's interface. |
| 3 | **Install Just Faster Printer** | For Q2 owners without a Box. Keeps the stock Qidi screen but adds cleaner macros, faster print start, and adaptive bed meshing. |
| 4 | **Revert to Backup** | Fully uninstalls everything AIO has installed and restores your printer to the state it was in before the first AIO run. Runs a health check automatically at the end. |
| 5 | **Idle Fan Shutdown** | Addon toggle. Shuts off fans and heaters after 10 minutes idle, but only once all temps have dropped to safe levels. |
| 6 | **Mainsail** | Addon toggle. Installs the Mainsail web interface, accessible at `http://<printer-ip>:100`. Qidi's stock UI on port 80 is unaffected. Includes a camera proxy so the webcam stream works in Mainsail. |
| 7 | **About** | Shows the current AIO version and a brief description. |
| 8 | **Health Check / Run Verifiers** | Scans your Klipper config for common problems — duplicate macros, broken include lines, invalid settings — and offers to fix each one. Safe to run any time. |

## Filament drying (BunnyBox installs only)

After installing BunnyBox (option 1 or 2), the following one-tap drying macros are available from the Klipper console or HelixScreen. Spools rotate automatically throughout each cycle.

| Macro | Temp | Time |
|---|---|---|
| `DRY_PLA` | 45 °C | 4 h |
| `DRY_PETG` | 65 °C | 4 h |
| `DRY_ABS` | 65 °C | 4 h |
| `DRY_TPU` | 55 °C | 4 h |
| `DRY_PA` | 70 °C | 8 h |

## After installing BunnyBox & HelixScreen (option 1)

1. Run `FIRMWARE_RESTART` from the Klipper console or HelixScreen.
2. Run **option 8 (Health Check)** to verify everything loaded correctly.
3. **First-time only:** calibrate the MMU gear steppers:
   ```
   MMU_CALIBRATE_GEAR GATE=0 LENGTH=100
   ```
   Mark the filament at the entry point, measure how far it moved, then re-run with `MEASURED=<mm>`. Repeat for each gate.
4. Load filament into each gate and start a drying preset if needed.

## After installing BunnyBox & KlipperScreen (option 2)

1. Run `FIRMWARE_RESTART` from the Klipper console.
2. The printer display will switch to KlipperScreen automatically.
3. Run **option 8 (Health Check)** to verify everything loaded correctly.
4. Calibrate MMU gear steppers (same procedure as option 1, step 3).

## After installing Just Faster Printer (option 3)

1. Run `FIRMWARE_RESTART`.
2. Run a bed level and `SCREWS_TILT_CALCULATE` before your first print.

## Release history

| Version | Notable additions |
|---------|------------------|
| RC1.20 | KlipperScreen now runs as an X11 client on lightdm's display (`DISPLAY=:0`) — no longer requires `xserver-xorg-legacy`; verifier no longer false-alarms on HelixScreen when KlipperScreen is active |
| RC1.19 | Fixed KlipperScreen install: clones full repo before running installer so path variables resolve correctly |
| RC1.18 | Fixed KlipperScreen install: patches `xserver-xorg-legacy` out of installer (Qidi holds `xserver-common`) |
| RC1.17 | KlipperScreen install attempted Wayland backend (superseded by RC1.18) |
| RC1.16 | Added option 2: BunnyBox + KlipperScreen as an alternative display |
| RC1.14 | Adopted `RC<major>.<minor>` version format; fixed duplicate webcam entries in Mainsail |
| RC13 | Fixed camera stream in Mainsail (nginx `/webcam/` proxy + correct ustreamer paths) |
| RC11 | Fixed two post-install Klipper errors: `gcode: not valid in section 'bed_mesh'` and `BED_MESH_CALIBRATE already registered`; install now aborts correctly if a required step fails |
| RC10 | Fixed fresh-install black screen — HelixScreen now activates correctly after option 1 |
| RC9 | Automatic spool rotation during filament drying cycles |
| RC8 | Health check runs automatically after every Revert to Backup; new config validators (orphan includes, invalid settings, leftover MMU files) |
| RC7 | Mainsail web UI as a menu addon |
| RC6 | Fixed `BED_MESH_CALIBRATE` duplicate crash from older BunnyBox installs |
| RC5 | Fixed Klipper startup crash caused by conflicting Box hardware drivers |
| RC4 | Simplified uninstall — Revert to Backup is now the single restore path |
| RC1–3 | Initial AIO release; HelixScreen + BunnyBox install/uninstall; idle fan shutdown addon |

## Known limitations

- **Native Qidi Box AMS panel is unavailable while BunnyBox is installed.** Revert to Backup restores it.
- **HelixScreen has no built-in dryer UI.** Use the `DRY_*` macros from the console, or add them as HelixScreen macro shortcuts (gear icon → Macros → Add).
- **MMU gear calibration is required after a fresh install.**
- **Camera streaming (Mainsail)** requires a USB camera connected to the printer.

## Troubleshooting

**`ERROR: Cannot reach raw.githubusercontent.com`** — No internet from the printer. Check network settings.

**`ERROR: Config directory not found`** — Not running as `mks`, or this isn't a Klipper-based Q2.

**Klipper won't start after install** — Run option 8 (Health Check). It will identify and offer to fix the most common causes.

**Klipper won't start after uninstall** — Use option 4 (Revert to Backup) for a clean restore.

**KlipperScreen not showing on display** — Check `sudo journalctl -u KlipperScreen -n 50`. Confirm `lightdm.service` is active (`systemctl status lightdm`).

**No stock backup exists** — `/home/mks/mudstockbackups/` is created automatically on first run. If configs were already changed before the first AIO run, restore from a Qidi factory image first, then run AIO to capture a clean baseline.

## Links

- Repo: https://github.com/ChanceVegas/Qidi-Q2-superuser_helpinghands
- Upstream: https://github.com/Camden-Winder/Qidi-Q2-superuser
- BunnyBox: https://github.com/Camden-Winder/Bunny-Box
- HelixScreen: https://github.com/prestonbrown/helixscreen
- KlipperScreen: https://github.com/KlipperScreen/KlipperScreen
- Mainsail: https://github.com/mainsail-crew/mainsail
