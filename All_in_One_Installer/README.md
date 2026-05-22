# Qidi Q2 Superuser - All-in-One Installer

> **Disclaimer:** Use this tool at your own risk. The author is not responsible for any damage, malfunction, or data loss caused to your printer. Qidi states that any modifications to files on their printers may void the manufacturer warranty.

A single ANSI-colored bash menu that drives every supported install, uninstall, and addon path for the Qidi Q2 community toolkit.

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
Enter selection:
```

## Requirements

- Qidi Q2 running stock Klipper firmware
- SSH access as user `mks` (the default Qidi user)
- Internet access from the printer (script downloads installers from GitHub)
- **Do not run as root** — the script will refuse to start

## Install

SSH into the Q2 as `mks`, then run one of the following:

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

All menu prompts read from `/dev/tty` so they work correctly under `curl | bash`.

## What each menu item does

| # | Action | When to use |
|---|--------|-------------|
| 1 | Install **BunnyBox & HelixScreen** | Q2 with a Qidi Box. Installs Happy Hare MMU, HelixScreen UI, unified configs, `box_drying.cfg`, KAMP, and spool-rotation wiring. |
| 2 | Install **Just Faster Printer** | Q2 without a Box. Keeps the stock Qidi screen. Cleaner macros, faster `PRINT_START`, KAMP, `screws_tilt_adjust`, Spoolman. |
| 3 | **Revert to Backup** | Full stock restore. Removes BunnyBox, HelixScreen, all addons, restores from the first-run snapshot, then runs a full health check before finishing. |
| 4 | **Idle Fan Shutdown** | Toggle. Powers down fans + heaters after 10 minutes idle, unless temps are still unsafe. |
| 5 | **Mainsail** | Toggle. Installs Mainsail web UI on port 100; Qidi's stock UI on port 80 is untouched. Access at `http://<printer-ip>:100`. |
| 6 | About | Version and info screen. |
| 7 | **Health Check / Run Verifiers** | Non-destructive on-demand check. Scans for duplicate macros, orphan includes, invalid Klipper options, and leftover MMU artifacts. Prompts before fixing anything. |
| 0 | Exit | Quit. |

Revert to Backup is the single uninstall path — there are no per-component uninstall options.

## Filament drying presets

After installing BunnyBox, these macros are available from the Klipper console or HelixScreen. Spools rotate automatically every 5 minutes throughout the cycle.

| Macro | Temp | Time | Source |
|---|---|---|---|
| `DRY_PLA` | 45 °C | 4 h | Qidi + Bambu recommended |
| `DRY_PETG` | 65 °C | 4 h | Qidi recommended |
| `DRY_ABS` | 65 °C | 4 h | Bambu recommended |
| `DRY_TPU` | 55 °C | 4 h | Bambu (max to avoid deformation) |
| `DRY_PA` | 70 °C | 8 h | Qidi + Bambu recommended |

Custom cycle: `BOX_DRY TEMP=<°C> TIME=<min> [HUMIDITY=<%>]`  
Status: `BOX_DRY_STATUS` · Stop: `BOX_DRY_STOP` · Manual rotation: `BOX_ROTATE_SPOOLS`

## Safety net

- A timestamped backup of `/home/mks/printer_data/config/` is written to `/home/mks/mudstockbackups/` before every install. The first backup ever taken is preserved as `_FIRST_STOCK` — that's what Revert to Backup restores from.
- Every uninstall confirms with `[y/N]` before proceeding.
- The script refuses to run as `root`.

## After installing BunnyBox & HelixScreen

1. `FIRMWARE_RESTART` (Klipper console or HelixScreen).
2. Verify: `systemctl status klipper`.
3. Run **option 7 (Health Check)** to confirm everything loaded correctly.
4. **First-time only** — calibrate MMU gear steppers:
   ```
   MMU_CALIBRATE_GEAR GATE=0 LENGTH=100
   ```
   Mark the filament, measure travel, re-run with `MEASURED=<mm>`.
5. Start a drying cycle: run `DRY_PLA`, `DRY_PETG`, etc. from the console or HelixScreen.

## After installing Just Faster Printer

1. `FIRMWARE_RESTART`.
2. Run a bed level + `SCREWS_TILT_CALCULATE` before your first print.

## Known limitations

- **Native Qidi Box AMS UI is unavailable while BunnyBox is installed.** Revert to Backup brings the stock UI back.
- **HelixScreen has no native dryer UI.** Use the `DRY_*` macros from the console, or add them as HelixScreen macro shortcuts (gear icon → Macros → Add).
- **`MMU_CALIBRATE_GEAR` is required after a clean install.**
- **BunnyBox requires HelixScreen for MMU workflows** — the stock Qidi screen doesn't expose the MMU UI.
- **HelixScreen is pinned to `v0.99.66`** — update `HELIXSCREEN_PIN` in `aio_menu.sh` when a newer stable release ships.
- **Mainsail is always pulled from `latest`** — no version pinning.

## Troubleshooting

**`ERROR: Cannot reach raw.githubusercontent.com`** — No internet route from the printer. Check network settings.

**`ERROR: Config directory not found`** — Not a Qidi Q2 running Klipper, or not running as `mks`.

**`Option 'timeout' is not valid in section 'bed_mesh'`** — Some Qidi stock configs misplace `timeout: 43200` inside `[bed_mesh]`. Option 7 detects and fixes this.

**`gcode command BED_MESH_CALIBRATE already registered`** — Older BunnyBox `KAMP_Settings.cfg` conflict. Option 7 re-fetches the correct file.

**`CLEAR_TOOLCHANGE_STATE already registered`** — `[include box.cfg]` is active alongside Happy Hare. Re-run option 1 to disable it, or use option 3 to revert to stock.

**Klipper errors after uninstalling** — Stale `[include mmu/base/*.cfg]` lines in `printer.cfg`. Option 3 (Revert to Backup) is the clean fix; option 7 will also catch orphan includes.

**No stock backup exists** — `/home/mks/mudstockbackups/` is created on first run. If configs were already overwritten, restore from a Qidi factory image first, then run the AIO to capture a clean `_FIRST_STOCK`.

## Links

- Repo: https://github.com/ChanceVegas/Qidi-Q2-superuser_helpinghands
- Upstream: https://github.com/Camden-Winder/Qidi-Q2-superuser
- BunnyBox: https://github.com/Camden-Winder/Bunny-Box
- HelixScreen: https://github.com/prestonbrown/helixscreen
- Mainsail: https://github.com/mainsail-crew/mainsail
