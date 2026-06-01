# Qidi Q2 Superuser - What Was Done

A summary of the toolkit assembled in `ChanceVegas/Qidi-Q2-superuser_helpinghands`, what each piece does, and where the All-in-One (AIO) menu fits in.

## Project

**Qidi Q2 Superuser** is a community-driven toolkit that unlocks advanced features on the Qidi Q2 3D printer beyond stock Qidi firmware: multi-material printing, a modern touchscreen UI, automatic filament drying with humidity sensing, adaptive bed meshing, and faster, cleaner print start/end macros - all with a backup/restore safety net.

The `helpinghands` fork hardens the upstream installers and adds the AIO menu so anything you can do to a Q2 can be done from a single script.

## Accomplished

### `All_in_One_Installer/aio_menu.sh` (new)

Single-entry, ANSI-colored bash menu that drives every install and uninstall path. Merges all logic from `BunnyBox&HelixScreen.sh` directly - one script, no shelling out to siblings. Refuses to run as root.

Current menu items:

| # | Action |
|---|--------|
| 1 | Install BunnyBox & HelixScreen (Q2 with Qidi Box) |
| 2 | Install KlipperScreen (temporarily disabled while Q2 display behavior is investigated) |
| 3 | Install Just Faster Printer (Q2 without Box, stock screen) |
| 4 | Revert to Backup (full uninstall + restore stock) |
| 5 | Idle Fan Shutdown |
| 6 | Mainsail |
| 7 | About |
| 8 | Health Check / Run Verifiers |
| 0 | Exit |

Features:
- Preflight (network reachability to GitHub, `${CONFIG_DIR}` present, `enable_force_move` sanity check)
- First-run stock snapshot plus timestamped backups to `/home/mks/mudstockbackups/YYYYMMDD_HHMMSS/` before install/revert operations
- Stock `/home/mks/printer_data/config/KAMP` is included in the config snapshot when present, so Revert to Backup can restore the original Qidi KAMP directory
- Install log via `tee` for BunnyBox+HelixScreen flow
- Per-action `[OK] / [INFO] / [WARN] / [ERR]` status lines (green / cyan / yellow / red)
- Live status header showing BunnyBox, display UI, IdleFan, BoxWrite, Mainsail, and camera state
- Y/N confirmation on destructive restore paths
- Post-install and option 8 verification: confirms key files, Klipper/Moonraker health, Happy Hare/MMU state, HelixScreen state, duplicate macros, invalid options, and orphan includes
- Duplicate-macro verification follows the active `printer.cfg` include graph, so stock files preserved on disk for Revert to Backup do not generate false warnings
- "Revert to Backup" removes AIO-installed services/config residue, restores `${CONFIG_DIR}` from the first stock snapshot when available, re-enables `lightdm` + `makerbase-client`, verifies the stock display stack, and only removes `/home/mks/mudstockbackups` after the stock restore succeeds.

### `Install-Script/BunnyBox&HelixScreen.sh` (hardened)

Standalone installer for the BunnyBox + HelixScreen path. Same logic as the AIO menu item 1, also exposed as a one-liner with CLI flags: `--reinstall`, `--clean`, `--uninstall`, `--help`.

What it installs / does:
- BunnyBox (Happy Hare MMU) via Camden-Winder's `install-bb-q2.sh`
- HelixScreen via Preston Brown's `install.sh`
- Unified `gcode_macro.cfg` and `printer.cfg` from this repo
- `box_drying.cfg` (Qidi Box spool rotation during drying)
- Patches `mmu/base/mmu_parameters.cfg` with `heater_vent_macro: _QIDI_BOX_VENT` and `heater_vent_interval: 5`
- AIO KAMP root files for the BunnyBox/HelixScreen path (`KAMP_Settings.cfg`, `Adaptive_Meshing.cfg`, `Line_Purge.cfg`, `Smart_Park.cfg`)
- HelixScreen `settings.json`
- Fixes the KAMP double-nesting include bug if it appears
- Wraps third-party installers in `set +e` so a "warning" exit code doesn't abort the run

### `Install-Script/JustFasterPrinter.sh` (upstream)

Lightweight config upgrade for Q2 owners **without** a Qidi Box. Now reachable from AIO menu item 2. Keeps the stock screen, no BunnyBox, no HelixScreen - just cleaner macros and faster starts. KAMP_Settings goes into the `KAMP/` subdirectory (`[include ./KAMP/KAMP_Settings.cfg]`).

### `Install-Script/box_drying.cfg`

Klipper config that restores spool rotation during filament drying using Happy Hare's Environment Manager. Provides:
- `_QIDI_BOX_VENT` - the macro Happy Hare calls on its venting interval; uses `FORCE_MOVE` on `stepper_mmu_gear*` to rotate spools so the heat penetrates evenly
- `BOX_DRY [TEMP=] [TIME=] [HUMIDITY=]` - wraps `MMU_HEATER DRY=1` with humidity-based early termination via the AHT2X sensor
- `BOX_DRY_STOP`, `BOX_DRY_STATUS`, `BOX_ROTATE_SPOOLS`

The installer patches `heater_vent_macro` and `heater_vent_interval` in `mmu_parameters.cfg` automatically.

### `Install-Script/gcode_macro-BunnyBox&HelixScreen.cfg`

Unified macro config for the BunnyBox + HelixScreen install path.

### `Install-Script/gcode_macro(JustFasterPrinter).cfg`

Macro config for the non-Box Q2.

### `Install-Script/printer(BunnyBox&HelixScreen).cfg`

Printer config wired for MMU includes, HelixScreen compatibility, and KAMP.

### `Install-Script/JustFasterPrinter.cfg`

Printer config for non-Box Q2 with KAMP, `screws_tilt_adjust`, and Spoolman hooks.

### `Install-Script/KAMP_settings.cfg`

Klipper Adaptive Meshing & Purging settings - tuned for the Q2 bed.

### `Install-Script/uninstall.sh` (upstream)

Original Camden-Winder revert script. The current AIO keeps the revert concept but expands it substantially: Revert to Backup is now menu item 4, prefers the first clean stock snapshot, restores the stock `KAMP/` directory when it was present in the backup, removes AIO leftovers, and verifies stock display services before deleting `/home/mks/mudstockbackups`.

## Achievements

- **Multi-material printing** via Happy Hare MMU (BunnyBox).
- **HelixScreen** replacement touchscreen UI - modern, themeable, Klipper-native.
- **Automatic filament drying** with humidity-based early termination (AHT2X) and active spool rotation while drying.
- **KAMP adaptive bed meshing** - meshes only the printed area.
- **`screws_tilt_adjust`** for guided manual bed leveling.
- **Faster, cleaner `PRINT_START` / `PRINT_END`** macros.
- **Spoolman hooks** for filament inventory.
- **Full backup/restore safety net** - first-run stock snapshot plus timestamped backups; `Revert to Backup` restores the pre-AIO config state, including stock `KAMP/` when present.
- **Single-entry AIO menu** so users do not have to remember which `.sh` to run for which Q2 variant.

## File Paths Reference

| Source file | Destination on printer |
|---|---|
| `gcode_macro-BunnyBox&HelixScreen.cfg` | `/home/mks/printer_data/config/gcode_macro.cfg` |
| `printer(BunnyBox&HelixScreen).cfg`    | `/home/mks/printer_data/config/printer.cfg` |
| `box_drying.cfg`                       | `/home/mks/printer_data/config/box_drying.cfg` |
| `KAMP_settings.cfg` (BB+HS)            | `/home/mks/printer_data/config/KAMP_Settings.cfg` |
| `helixscreen_settings.json`            | `/home/mks/helixscreen/config/settings.json` |
| `gcode_macro(JustFasterPrinter).cfg`   | `/home/mks/printer_data/config/gcode_macro.cfg` |
| `JustFasterPrinter.cfg`                | `/home/mks/printer_data/config/printer.cfg` |
| `KAMP_settings.cfg` (JFP)              | `/home/mks/printer_data/config/KAMP/KAMP_Settings.cfg` |
| `mmu_parameters.cfg` (patch target)    | `/home/mks/printer_data/config/mmu/base/mmu_parameters.cfg` |
| Backups                                | `/home/mks/mudstockbackups/YYYYMMDD_HHMMSS/` |
| First stock snapshot                   | `/home/mks/mudstockbackups/_FIRST_STOCK/` |
| Stock KAMP restore source              | `/home/mks/mudstockbackups/_FIRST_STOCK/KAMP/` when present |

## Known Limitations

- **Native Qidi Box humidity/dryer UI requires the Happier Hare patched HelixScreen zip.** Without that zip, use the `BOX_DRY` macro or the Klipper console as a workaround.
- **`MMU_CALIBRATE_GEAR` is required after clean installs.** Mark filament, run `MMU_CALIBRATE_GEAR GATE=0 LENGTH=100`, measure travel, re-run with `MEASURED=<mm>`.
- **BunnyBox currently requires HelixScreen for MMU workflows** - the stock Qidi screen does not yet expose the MMU UI.

## Usage

From the Q2 over SSH (as user `mks`, never as root):

```bash
git clone https://github.com/ChanceVegas/Qidi-Q2-superuser_helpinghands.git
cd Qidi-Q2-superuser_helpinghands/All_in_One_Installer
./aio_menu.sh
```

Or to run the BunnyBox+HelixScreen installer non-interactively:

```bash
cd Qidi-Q2-superuser_helpinghands/Install-Script
./BunnyBox\&HelixScreen.sh --clean    # uninstall first, then reinstall
```

## Upstream Lineage

- **Repo:** [`ChanceVegas/Qidi-Q2-superuser_helpinghands`](https://github.com/ChanceVegas/Qidi-Q2-superuser_helpinghands)
- **Upstream:** [`Camden-Winder/Qidi-Q2-superuser`](https://github.com/Camden-Winder/Qidi-Q2-superuser) (uninstall logic only)
- **BunnyBox:** [`Camden-Winder/Bunny-Box`](https://github.com/Camden-Winder/Bunny-Box)
- **HelixScreen:** [`prestonbrown/helixscreen`](https://github.com/prestonbrown/helixscreen)
