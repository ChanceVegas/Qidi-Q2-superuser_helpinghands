# Qidi Q2 Superuser - All-in-One Installer

A single ANSI-colored bash menu that drives every supported install and uninstall path for the Qidi Q2 community toolkit. No more remembering which `.sh` to run for which Q2 variant.

```
============================================
   Qidi Q2 Superuser - AIO Setup Menu
============================================
  BunnyBox: not found   |   HelixScreen: not found   |   IdleFan: off
--------------------------------------------
  INSTALL
   1) Install BunnyBox & HelixScreen   (Q2 with Qidi Box)
   2) Install Just Faster Printer      (Q2 without Box)
  UNINSTALL
   3) Uninstall BunnyBox only
   4) Uninstall HelixScreen only
   5) Uninstall Both
   6) Revert to Backup                 (uninstall both + restore)
  ADDONS
   7) Idle Fan Shutdown                (10m idle, temp-gated)
  INFO
   8) About
   0) Exit
============================================
Enter selection:
```

## Requirements

- Qidi Q2 running stock Klipper firmware
- SSH access to the printer as user `mks` (the default Qidi user)
- Network reachable from the printer (script downloads installers from GitHub)
- **Do not run as root** — the script will refuse to start

## Install (one-liner)

SSH into the Q2 as `mks`, then:

```bash
curl -sSL https://raw.githubusercontent.com/ChanceVegas/Qidi-Q2-superuser_helpinghands/refs/heads/main/All_in_One_Installer/aio_menu.sh | bash
```

That fetches the latest `aio_menu.sh` and runs it interactively. All menu prompts read from `/dev/tty`, so they still work correctly under `curl | bash`.

> **Tip:** prefer to review before running? Use the "Download then run" path below.

## Install (download then run)

```bash
cd ~
curl -fsSL -o aio_menu.sh \
  https://raw.githubusercontent.com/ChanceVegas/Qidi-Q2-superuser_helpinghands/refs/heads/main/All_in_One_Installer/aio_menu.sh
chmod +x aio_menu.sh
./aio_menu.sh
```

## Install (git clone)

```bash
cd ~
git clone https://github.com/ChanceVegas/Qidi-Q2-superuser_helpinghands.git
cd Qidi-Q2-superuser_helpinghands/All_in_One_Installer
chmod +x aio_menu.sh
./aio_menu.sh
```

## What each menu item does

| # | Action | When to pick it |
|---|--------|----------------|
| 1 | Install **BunnyBox & HelixScreen** | Q2 owners **with** a Qidi Box. Installs Happy Hare MMU, HelixScreen UI, unified configs, `box_drying.cfg`, patches `mmu_parameters.cfg`, applies KAMP. |
| 2 | Install **Just Faster Printer** | Q2 owners **without** a Box. Keeps the stock Qidi screen. Cleaner macros, faster `PRINT_START`, KAMP, `screws_tilt_adjust`, Spoolman. |
| 3 | Uninstall **BunnyBox only** | Remove Happy Hare MMU but keep HelixScreen. |
| 4 | Uninstall **HelixScreen only** | Restore stock screen but keep BunnyBox. |
| 5 | Uninstall **Both** | Remove BunnyBox and HelixScreen. Does **not** restore stock configs. |
| 6 | **Revert to Backup** | Full upstream-style stock restore: explicitly purges every install-managed path (Happy Hare source, `mmu/`, klipper/moonraker extras, moonraker.conf sections, Idle Fan Shutdown), re-enables `lightdm` + `makerbase-client`, restores from `_FIRST_STOCK` (or oldest timestamped backup) under `/home/mks/mudstockbackups/`, then removes all backup directories. |
| 7 | **Idle Fan Shutdown** (addon) | Toggle. After 10 minutes idle, powers down fans + heaters unless extruder/bed/chamber temps are still above safe thresholds. Re-checks every 60 s while temps remain unsafe. |
| 8 | About | Plain-text explanation of what the AIO does. |
| 0 | Exit | Quit. |

## Safety net

- Every install **and** every uninstall first writes a timestamped backup of `/home/mks/printer_data/config/` to `/home/mks/mudstockbackups/YYYYMMDD_HHMMSS/`.
- BunnyBox install also writes a per-run log to `/home/mks/mudstockbackups/install_YYYYMMDD_HHMMSS.log`.
- Every uninstall option asks for `[y/N]` confirmation.
- The script refuses to run as `root` to avoid breaking file permissions on the Q2.

## After installing BunnyBox & HelixScreen

1. `FIRMWARE_RESTART` (Klipper console or HelixScreen).
2. Verify: `systemctl status klipper`.
3. **First-time only** — calibrate MMU gear steppers:
   ```
   MMU_CALIBRATE_GEAR GATE=0 LENGTH=100
   ```
   Mark filament, measure travel, re-run with `MEASURED=<mm>`.
4. Start drying:
   ```
   BOX_DRY TEMP=45 TIME=300
   ```
   or auto-select from gate filament types:
   ```
   MMU_HEATER DRY=1
   ```
5. Check status: `BOX_DRY_STATUS`. Stop drying: `BOX_DRY_STOP`.

## After installing Just Faster Printer

1. `FIRMWARE_RESTART`.
2. Run a bed level + `SCREWS_TILT_CALCULATE` before your first print.

## Known limitations

- **HelixScreen has no native UI panel for Happy Hare's dryer yet.** Use the `BOX_DRY` macro or the Klipper console as a workaround.
- **`MMU_CALIBRATE_GEAR` is required after clean installs.**
- **BunnyBox currently requires HelixScreen for MMU workflows** — the stock Qidi screen does not yet expose the MMU UI.

## Troubleshooting

**`ERROR: Cannot reach raw.githubusercontent.com`** — The Q2 has no internet route. Check the printer's network settings.

**`ERROR: Config directory not found: /home/mks/printer_data/config`** — This isn't a Qidi Q2 running stock Klipper, or the user isn't `mks`.

**`WARN: force_move not found in printer.cfg`** — Spool rotation during drying needs `[force_move] enable_force_move: True`. The unified printer.cfg installed by option 1 already sets this; the warning is only for pre-install state.

**Klipper errors after uninstalling BunnyBox** — `printer.cfg` still has `[include mmu/base/*.cfg]` references. Either reinstall, or pick option 6 (Revert to Backup) to restore stock configs.

**Forgot to take a stock backup before tinkering** — `/home/mks/mudstockbackups/` is created automatically on the first run. If you've already overwritten configs, restore from a fresh Qidi factory image, then run the AIO so it captures a real stock backup.

## Links

- Repo: https://github.com/ChanceVegas/Qidi-Q2-superuser_helpinghands
- Upstream (uninstall lineage): https://github.com/Camden-Winder/Qidi-Q2-superuser
- BunnyBox: https://github.com/Camden-Winder/Bunny-Box
- HelixScreen: https://github.com/prestonbrown/helixscreen
