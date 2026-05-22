# CLAUDE.md — HelixScreen Drying UI

Scoped session context for adding native Qidi Box drying buttons to HelixScreen on the Qidi Q2.

## Goal

Pre-configure HelixScreen macro shortcut buttons for filament drying so users get one-tap `DRY_PLA`, `DRY_PETG`, etc. buttons immediately after a BunnyBox + HelixScreen install — no manual HelixScreen UI setup required.

## Development Branch

`claude/helixscreen-drying-ui` — all work goes here, merge to `main` via PR.

## Context

- **HelixScreen** is a Klipper touchscreen UI by prestonbrown, installed at `/home/mks/helixscreen/` on the Q2.
- AIO ships a custom `helixscreen_settings.json` (at `Install-Script/helixscreen_settings.json`) that is written to `/home/mks/helixscreen/config/settings.json` on install. It currently sets `"ams": { "spool_style": "3d" }`.
- Drying macros (`DRY_PLA`, `DRY_PETG`, `DRY_ABS`, `DRY_TPU`, `DRY_PA`, `BOX_DRY_STOP`, `BOX_DRY_STATUS`) are defined in `Install-Script/box_drying.cfg` and deployed to the printer's config directory by `install_bunnybox_helixscreen()` in `All_in_One_Installer/aio_menu.sh`.

## Key Question to Resolve First

Does HelixScreen's `settings.json` support pre-seeding macro shortcut buttons, or do shortcuts only live in a separate runtime database/file?

- Check the HelixScreen source repo (`prestonbrown/helixscreen`) for the settings schema and any macro/shortcut configuration format.
- Look for a `macros`, `shortcuts`, or `buttons` key in `settings.json` examples or docs.
- If macros are stored elsewhere (e.g. a SQLite db or separate JSON), identify the file path on the printer and whether it can be written at install time.

## Relevant Files

| File | Purpose |
|---|---|
| `Install-Script/helixscreen_settings.json` | Shipped settings file; add macro definitions here if schema supports it |
| `Install-Script/box_drying.cfg` | Source of drying macro definitions (`DRY_PLA`, etc.) |
| `All_in_One_Installer/aio_menu.sh` | `install_bunnybox_helixscreen()` deploys both files |

## Buttons to Add

| Button label | Macro |
|---|---|
| Dry PLA | `DRY_PLA` |
| Dry PETG | `DRY_PETG` |
| Dry ABS | `DRY_ABS` |
| Dry TPU | `DRY_TPU` |
| Dry PA / Nylon | `DRY_PA` |
| Stop Drying | `BOX_DRY_STOP` |
| Drying Status | `BOX_DRY_STATUS` |

## Deliverables

1. **Schema research** — document how HelixScreen stores macro shortcuts and whether `settings.json` is the right vector.
2. **Updated `helixscreen_settings.json`** — add the drying macro buttons in the correct format (or identify the correct file if not `settings.json`).
3. **`aio_menu.sh` update** — if a separate file is required, add a `fetch` or write step to `install_bunnybox_helixscreen()`.
4. **AIO version bump** — RC10 in `aio_menu.sh`.
5. **README release history** — add RC10 row in `All_in_One_Installer/README.md`.

## Constraints

- Do not modify `Configurations/` or `Plugins/` — read-only stock Qidi mirrors.
- Run `bash -n All_in_One_Installer/aio_menu.sh` and `python3 -m json.tool Install-Script/helixscreen_settings.json` before every commit touching those files.
- Use `banner`, `info`, `warn`, `ok`, `err` helpers in shell code — never raw `echo`.
- All work on `claude/helixscreen-drying-ui`; never push directly to `main`.
