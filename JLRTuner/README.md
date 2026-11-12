# JLRTuner

A macOS application to make **Jaguar Land Rover** diagnostics, configuration, and
(eventually) performance calibration accessible to the enthusiast owner — the
work that today usually means paying a specialist to plug in a dealer-grade tool.

> **This is a standalone project.** It is unrelated to, and shares nothing with,
> the Qidi Q2 AIO installer that also lives in this repository. It currently
> lives here only because development was scoped to this branch; it is structured
> to be lifted into its own repository unchanged.

## Status

**Research / pre-implementation.** No application code yet. This directory holds
the technical research that defines what gets built.

- [`docs/TECHNICAL_SPEC.md`](docs/TECHNICAL_SPEC.md) — feasibility report &
  architecture: the GAP iiDTool reverse-engineered from public data, the JLR
  protocol stack (CAN/ISO-TP/DoIP/UDS), the open-source precedent
  (`jlr-open-diag`), the security walls, the macOS app architecture, and a phased
  roadmap.
- [`docs/REFERENCES.md`](docs/REFERENCES.md) — the full source dossier.

## The short version

- The **GAP iiDTool** — the product this project is modelled on — is a **Land
  Rover / Jaguar-only** tool (not BMW/Mercedes/Audi). Hence the JLR focus.
- It is a **BLE dongle + phone app** that acts as a **diagnostic and flashing
  transport**. It can reach the engine ECU, but engine *tuning* is a separate,
  VIN-locked **tune file bought elsewhere and flashed through the tool** — not
  intelligence in the device.
- Our build adds two confirmed core requirements: **live engine data streaming**
  and **flashing a matched tune to both the engine ECU and the transmission
  TCM** (ZF 8HP/6HP). See spec §4.5 (live data) and §7 (flashing strategy).
- A proven open-source reimplementation of JLR's diagnostic stack already exists
  (`jlr-open-diag`): **read/diagnose/config-read works on a real car**; **write/
  flash is walled** behind an online-delivered Secondary Boot Loader and, on
  2018+ cars, a Secure Gateway.
- **The MVP targets the achievable, no-circumvention half**: connect over J2534,
  read VIN, scan modules, read/clear faults, stream live data.

## Scope & ethics

Own-vehicle use only. Ships **no** security-bypass material (no seed-key
algorithms, no gateway circumvention, no bootloader redistribution) and **no**
emissions-defeat routines. See `TECHNICAL_SPEC.md` §10.

## Next decisions

Open questions that gate Phase 1 are listed in `TECHNICAL_SPEC.md` §11 — chiefly:
first target platform/model-years, J2534 adapter choice, bench/boot flashing
interface, and core-library language.
