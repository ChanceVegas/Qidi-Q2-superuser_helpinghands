# CLAUDE.md — Qidi Q2 Superuser AIO

Project context for Claude Code sessions. Read this first every time.

## Quick Start — Test Commands

Always run these before committing:

```bash
bash -n All_in_One_Installer/aio_menu.sh          # shell syntax check
python3 -m json.tool Install-Script/helixscreen_settings.json  # JSON lint
shellcheck -S warning All_in_One_Installer/aio_menu.sh         # style (advisory)
```

## Repo Layout

```
All_in_One_Installer/
  aio_menu.sh              ← Main artifact. All installer logic lives here.
  README.md
  WHAT_WAS_DONE.md

Install-Script/
  BunnyBox&HelixScreen.sh  ← Legacy single-shot installer (superseded by AIO)
  helixscreen_settings.json← Shipped to /home/mks/.config/helixscreen/settings.json
  idle_fan_shutdown.cfg
  box_drying.cfg
  mmu/                     ← Happy Hare / BunnyBox Klipper config files
  printer(BunnyBox&HelixScreen).cfg

Configurations/            ← Stock Qidi reference files. DO NOT MODIFY.
Plugins/                   ← Stock plugin reference. DO NOT MODIFY.

.claude/
  settings.json            ← Pre-approved Bash/WebFetch permissions
  hooks/pre-commit-check.sh← Auto-lint on every commit
  checklist.md             ← Pre-flight checklists
```

## Target Environment

- Hardware: Qidi Q2 Pro 3D printer
- OS: ARM Linux, user `mks`
- Stack: Klipper + Moonraker + Happy Hare (MMU) + HelixScreen (LVGL UI) + Qidi Box (4-slot AMS)
- Key paths on the printer:
  - `/home/mks/printer_data/config/` — Klipper config root
  - `/home/mks/mudstockbackups/` — AIO backup snapshots
  - `/home/mks/helixscreen/` — HelixScreen install dir
  - `/home/mks/Happy-Hare/` — Happy Hare MMU firmware

## Critical Rules

1. **Never modify** `Configurations/` or `Plugins/` — read-only stock Qidi mirrors.
2. **Never push to `main` directly** — all work goes on a `claude/*` branch; merge via PR.
3. **Bump `AIO_VERSION`** whenever `aio_menu.sh` changes (currently `RC1`; next is `RC2`).
4. **`bash -n` before every commit** touching any `.sh` file.
5. **`python3 -m json.tool` before every commit** touching any `.json` file.
6. **Do not run `aio_menu.sh` as root** — the script self-enforces this.
7. **`sudo tee` pattern for writing files with elevated perms**, never `echo > file` with sudo.
8. **Use `banner`, `info`, `warn`, `ok`, `err` helpers** — never raw `echo` in installer logic.

## Install-Function Conventions

Every new capability that installs something must follow this checklist:

| Requirement | Example |
|---|---|
| `install_*()` function | `install_idle_fan_shutdown()` |
| `uninstall_*()` function | `uninstall_idle_fan_shutdown()` |
| `*_installed()` or `*_enabled()` detection helper | `idle_fan_shutdown_installed()` |
| Wired into `revert_to_backup()` | call `uninstall_*` in the revert block |
| Status indicator added to `show_status_line()` | `IdleFan: on/off` |
| `verify_*()` post-install check (warn, never fail) | `verify_qidi_box_helixscreen()` |

When `install_*` fetches a remote file, use the `fetch()` helper, not `curl` directly.

### Current Install Functions

| Function | Feature | Status indicator |
|---|---|---|
| `install_bunnybox_helixscreen()` | Happy Hare + HelixScreen | `BunnyBox: installed/not found`, `HelixScreen: installed/not found` |
| `install_just_faster()` | JustFasterPrinter macros | (no AMS/Box) |
| `install_idle_fan_shutdown()` | 10m idle fan+heater shutdown | `IdleFan: on/off` |
| `install_qidi_box_write()` | HelixScreen HELIX_QIDI_BOX_WRITE drop-in | `BoxWrite: on/off` |

### Current Menu Layout

```
1) Install BunnyBox & HelixScreen   (Q2 with Qidi Box)
2) Install Just Faster Printer      (Q2 without Box)
3) Uninstall BunnyBox only
4) Uninstall HelixScreen only
5) Uninstall Both
6) Revert to Backup                 (uninstall both + restore)
7) Idle Fan Shutdown                (10m idle, temp-gated)
8) About
0) Exit
```

## Autonomous-Session Policy

Claude may do the following **without asking first**:

- Commit and push to any `claude/*` branch
- Create a draft PR after pushing a new branch
- Run `bash -n`, `python3 -m json.tool`, `shellcheck` (lint/syntax checks)
- Merge a PR to `main` when the handoff context explicitly says to do so

Claude **must ask first** before:

- Pushing to `main` directly
- Force-pushing any branch
- Deleting branches or files not created in the same session
- Taking actions visible to users outside this repo (posting comments, etc.)

## RC1 — What's In It

Merged to `main` via PR #1 (2026-05-20):

- `AIO_VERSION='RC1'` constant; rendered in banner and About screen
- `verify_qidi_box_helixscreen()` — post-install check (warns, never fails)
- `install_qidi_box_write()` — systemd drop-in for `HELIX_QIDI_BOX_WRITE=1`; `BoxWrite:` status line
- `helixscreen_settings.json`: `"ams": { "spool_style": "3d" }` for Qidi Box AMS view

## RC2 — Candidate Features (not yet implemented)

- Confirm-on-first-run gate for `HELIX_QIDI_BOX_WRITE` (y/N with 5s default-yes timeout)
- HelixScreen version pinning to a tagged release instead of `main`
- `update_qidi_box_dropin` migration helper
- "9) Run all verifiers" self-test menu item
- `/release` slash command for version bump + changelog + tag + push

## External Resources

- HelixScreen: `prestonbrown/helixscreen` on GitHub
- Happy Hare: `moggieuk/Happy-Hare`
- BunnyBox installer: `Camden-Winder/Bunny-Box` → `Q2/install-bb-q2.sh`
- Qidi Box: `wiki.qidi3d.com`
