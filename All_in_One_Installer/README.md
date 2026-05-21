# Qidi Q2 Superuser - All-in-One Installer

A single ANSI-colored bash menu that drives every supported install, uninstall, and addon path for the Qidi Q2 community toolkit. No more remembering which `.sh` to run for which Q2 variant.

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
| 1 | Install **BunnyBox & HelixScreen** | Q2 owners **with** a Qidi Box. Installs Happy Hare MMU, HelixScreen UI (pinned >= v0.99.66), unified configs, `box_drying.cfg`, patches `mmu_parameters.cfg` to wire spool rotation into Happy Hare's drying callback, and applies KAMP. Disables `[include box.cfg]` (conflicts with Happy Hare) and strips the `HELIX_QIDI_BOX_WRITE` drop-in (BunnyBox owns the Box write path). |
| 2 | Install **Just Faster Printer** | Q2 owners **without** a Box. Keeps the stock Qidi screen. Cleaner macros, faster `PRINT_START`, KAMP, `screws_tilt_adjust`, Spoolman. |
| 3 | **Revert to Backup** | Full upstream-style stock restore: explicitly purges every install-managed path (Happy Hare source, `mmu/`, klipper/moonraker extras, moonraker.conf sections, Idle Fan Shutdown, BoxWrite drop-in, Mainsail), re-enables `lightdm` + `makerbase-client`, restores from `_FIRST_STOCK` (or oldest timestamped backup) under `/home/mks/mudstockbackups/`, removes all backup directories, then runs the verifier sweep to catch any leftover problems before declaring the revert complete. |
| 4 | **Idle Fan Shutdown** (addon) | Toggle. After 10 minutes idle, powers down fans + heaters unless extruder/bed/chamber temps are still above safe thresholds. Re-checks every 60 s while temps remain unsafe. |
| 5 | **Mainsail** (addon) | Toggle. Installs Mainsail web UI on port 100, leaving Qidi's stock UI on port 80 untouched. Delegates to Camden-Winder's `install-mainsail.sh`. Access at `http://<printer-ip>:100`. Uninstall removes the nginx site config and `/home/mks/mainsail/`; moonraker.conf CORS entries are left in place (harmless). |
| 6 | About | Plain-text explanation of what the AIO does, version, known limitations. |
| 7 | **Health Check / Run Verifiers** | Non-destructive on-demand health check. Runs the same verifier sweep that Revert to Backup runs at the end: checks BunnyBox/HelixScreen install state, `box.cfg`, HelixScreen version, Idle Fan Shutdown state, BoxWrite drop-in state, Mainsail reachability, duplicate gcode_macro declarations, orphan `[include]` lines, invalid Klipper options (e.g. `timeout:` misplaced in `[bed_mesh]`), and leftover Happy Hare MMU artifacts. Each potential fix prompts the user before applying. |
| 0 | Exit | Quit. |

There are no per-component uninstall options. Revert to Backup is the single uninstall path; it delegates to `uninstall_bunnybox()`, `uninstall_helixscreen()`, `uninstall_idle_fan_shutdown()`, and `uninstall_mainsail()` internally before restoring stock configs.

## Spool rotation during drying

When BunnyBox is installed, `mmu_parameters.cfg` is patched to set:

```ini
heater_vent_macro:    _QIDI_BOX_VENT
heater_vent_interval: 5
```

This routes Happy Hare's periodic heater-vent callback to `_QIDI_BOX_VENT` (defined in `box_drying.cfg`), which uses `FORCE_MOVE` to rotate each of the 4 Qidi Box gear steppers 75° every 5 minutes during any `MMU_HEATER DRY=1` cycle. Direction alternates each call so net filament travel cancels out over a long dry. Rotation is guarded against active prints and active MMU operations.

While BunnyBox is installed, native Qidi Box rotation (via `box_extras.so`) is unavailable because `[include box.cfg]` is disabled to prevent a Klipper startup crash. Revert to Backup re-enables `[include box.cfg]` and restores Qidi's native drying/rotation through the stock UI.

## Filament drying presets

After installing BunnyBox, these macros are available from the Klipper console or HelixScreen:

| Macro | Temp | Time | Source |
|---|---|---|---|
| `DRY_PLA` | 45 °C | 4 h | Qidi + Bambu recommended |
| `DRY_PETG` | 65 °C | 4 h | Qidi recommended |
| `DRY_ABS` | 65 °C | 4 h | Bambu recommended |
| `DRY_TPU` | 55 °C | 4 h | Bambu (max to avoid deformation) |
| `DRY_PA` | 70 °C | 8 h | Qidi + Bambu recommended |

For one-off settings, use `BOX_DRY TEMP=<°C> TIME=<min> [HUMIDITY=<%>]`. Status: `BOX_DRY_STATUS`. Stop: `BOX_DRY_STOP`. Manual single rotation: `BOX_ROTATE_SPOOLS`.

## Safety net

- Every install **and** every uninstall first writes a timestamped backup of `/home/mks/printer_data/config/` to `/home/mks/mudstockbackups/YYYYMMDD_HHMMSS/`.
- BunnyBox install also writes a per-run log to `/home/mks/mudstockbackups/install_YYYYMMDD_HHMMSS.log`.
- Revert to Backup ends with the full verifier sweep (option 7) to catch leftover problems before declaring the revert complete. Each potential fix prompts before applying.
- Every uninstall option asks for `[y/N]` confirmation.
- The script refuses to run as `root` to avoid breaking file permissions on the Q2.

## Qidi Box write support (HELIX_QIDI_BOX_WRITE)

`HELIX_QIDI_BOX_WRITE` gates HelixScreen's native Qidi Box AMS write path (load filament, unload filament, change tool, set tool mapping).

**With BunnyBox installed (option 1):** the drop-in is **stripped**, not installed. Happy Hare owns Box hardware via `[mmu]` steppers and its own gcode commands; letting HelixScreen also drive the Box natively causes contention. The status line shows `BoxWrite: off` as the desired state.

**With BunnyBox removed (after Revert to Backup):** `[include box.cfg]` is restored, the stock Qidi UI handles Box AMS, and the drop-in is not needed.

You can manage the drop-in directly: it lives at `/etc/systemd/system/helixscreen.service.d/qidi-box-write.conf` and is set to `Environment=HELIX_QIDI_BOX_WRITE=1`. Revert to Backup removes it.

## After installing BunnyBox & HelixScreen

1. `FIRMWARE_RESTART` (Klipper console or HelixScreen).
2. Verify: `systemctl status klipper`.
3. Run **option 7 (Health Check / Run Verifiers)** to confirm box.cfg state, filament list, HelixScreen version, MMU artifacts, orphan includes, and invalid Klipper options.
4. **First-time only** — calibrate MMU gear steppers:
   ```
   MMU_CALIBRATE_GEAR GATE=0 LENGTH=100
   ```
   Mark filament, measure travel, re-run with `MEASURED=<mm>`.
5. Start drying with a preset (`DRY_PLA`, `DRY_PETG`, `DRY_ABS`, `DRY_TPU`, `DRY_PA`) or a custom cycle:
   ```
   BOX_DRY TEMP=45 TIME=300
   ```
   or auto-select from gate filament types:
   ```
   MMU_HEATER DRY=1
   ```
6. Check status: `BOX_DRY_STATUS`. Stop drying: `BOX_DRY_STOP`.

## After installing Just Faster Printer

1. `FIRMWARE_RESTART`.
2. Run a bed level + `SCREWS_TILT_CALCULATE` before your first print.

## After installing Mainsail

1. Open `http://<printer-ip>:100` in any browser on the same network.
2. Qidi's stock UI on port 80 is unaffected — both are accessible.
3. To remove: re-run option 5 and confirm uninstall.

## Known limitations

- **Native Qidi Box AMS UI is unavailable while BunnyBox is installed.** `[include box.cfg]` is disabled because it loads `box_extras.so`, which registers gcode commands that Happy Hare's MMU package also registers — loading both crashes Klipper on startup. Revert to Backup brings the stock UI back.
- **HelixScreen has no native dryer progress UI yet.** Use the `DRY_*` macros above from the Klipper console, or add them as HelixScreen macro shortcuts (gear icon → Macros → Add). They'll appear as one-tap buttons on the HelixScreen main menu.
- **`MMU_CALIBRATE_GEAR` is required after clean installs.**
- **BunnyBox currently requires HelixScreen for MMU workflows** — the stock Qidi screen does not yet expose the MMU UI.
- **HelixScreen is pinned to `v0.99.66`** — the minimum version required for Qidi Box AMS support. Update `HELIXSCREEN_PIN` in `aio_menu.sh` when a newer stable release ships.
- **Mainsail is always pulled from `latest`** — no version pinning. A breaking Mainsail release would be picked up automatically. If that becomes a problem, re-run option 5 and uninstall to roll back to stock UI only.

## Troubleshooting

**`ERROR: Cannot reach raw.githubusercontent.com`** — The Q2 has no internet route. Check the printer's network settings.

**`ERROR: Config directory not found: /home/mks/printer_data/config`** — This isn't a Qidi Q2 running stock Klipper, or the user isn't `mks`.

**`WARN: force_move not found in printer.cfg`** — Spool rotation during drying needs `[force_move] enable_force_move: True`. The unified printer.cfg installed by option 1 already sets this; the warning is only for pre-install state.

**`Option 'timeout' is not valid in section 'bed_mesh'`** — Some Qidi stock `printer.cfg` versions misplace `timeout: 43200` inside `[bed_mesh]`; it belongs in `[idle_timeout]`. Option 7 detects this and prompts to fix it.

**`gcode command BED_MESH_CALIBRATE already registered`** — Older BunnyBox versions ship a `KAMP_Settings.cfg` that defines `BED_MESH_CALIBRATE` inline alongside `Adaptive_Meshing.cfg`'s definition. Option 7's `fix_known_klipper_conflicts` re-fetches the correct `KAMP_Settings.cfg` to heal this.

**`CLEAR_TOOLCHANGE_STATE already registered`** — `box_extras.so` (loaded via `[include box.cfg]`) and Happy Hare's MMU package both register this command. Re-run option 1 to apply the defensive disable, or pick option 3 (Revert to Backup) for a clean stock restore.

**Klipper errors after uninstalling BunnyBox** — `printer.cfg` may have stale `[include mmu/base/*.cfg]` references. Pick option 3 (Revert to Backup) to restore stock configs; the post-revert verifier sweep will also catch orphan includes.

**Forgot to take a stock backup before tinkering** — `/home/mks/mudstockbackups/` is created automatically on the first run. If you've already overwritten configs, restore from a fresh Qidi factory image, then run the AIO so it captures a real stock backup.

## Links

- Repo: https://github.com/ChanceVegas/Qidi-Q2-superuser_helpinghands
- Upstream (uninstall lineage): https://github.com/Camden-Winder/Qidi-Q2-superuser
- BunnyBox: https://github.com/Camden-Winder/Bunny-Box
- HelixScreen: https://github.com/prestonbrown/helixscreen
- Mainsail: https://github.com/mainsail-crew/mainsail
