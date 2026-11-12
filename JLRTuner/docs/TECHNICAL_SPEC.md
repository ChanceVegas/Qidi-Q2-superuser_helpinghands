# JLRTuner — Technical Specification & Feasibility Report

**Status:** Draft 0.1 — research / pre-implementation
**Scope:** A macOS application that simplifies diagnostics, configuration, and
(eventually) performance calibration for **Jaguar Land Rover (JLR)** vehicles,
modelled on the capabilities of the GAP Diagnostic *iiDTool*.
**Audience:** The enthusiast owner who today has to pay a specialist for work
their own car's buses already expose.

> This is an engineering research document. It describes *how the vehicle
> diagnostic stack works* so an interoperable tool can be built against it. It
> is **not** a guide to defeating manufacturer security, and it does not contain
> seed-key bypass material, security-gateway circumvention, or emissions-defeat
> instructions. See [§9 Legal & Safety](#9-legal--safety).

---

## 1. Why the pivot to JLR

The project began aimed at BMW / Mercedes / Audi, using the GAP *iiDTool* as the
reference product. Research established a decisive fact:

**The iiDTool is a Land Rover / Jaguar–only tool.** GAP Diagnostic (Terrebonne,
Québec, Canada) has built exclusively for the JLR platform for over a decade.
Every manual, model code (L319 Discovery 3/4, L322 Range Rover, L405 Range
Rover, L494 RR Sport, L538/L551 Evoque, Velar), bus choice, and feature is
JLR-specific. Its protocol stack, security model, and tune-flashing pipeline do
not transfer to the German marques, which use entirely different diagnostic
software (BMW ISTA + FSC licensing, Mercedes Xentry + SCN coding) and gateway
security.

Reverse-engineering the iiDTool is therefore only coherent if the **target is
JLR**. The project now targets JLR, and this document is written against that
platform.

---

## 2. The iiDTool, reverse-engineered from public data

### 2.1 Product shape

| Attribute | Detail |
|---|---|
| Form factor | OBD-II dongle + smartphone app |
| App | `IIDControl` — iOS (App Store id 634092136) & Android (`com.gap.iidcontrol`), free. Latest seen: v4.3.0 build 194 (Oct 2025) |
| Link | **Bluetooth Low Energy** ("Bluetooth Smart", BT ≥ 4.0). Uses GATT; the dongle does **not** appear in the phone's normal pairing list — the app owns the connection |
| Also sold | `EASControl` — a cut-down suspension raise/lower tool; its feature set is a subset of the iiDTool |
| Vendor | GAP Diagnostic, Canada |

### 2.2 Hardware generations

| Gen | Buses | DoIP | Notes |
|---|---|---|---|
| **G2** | CAN (+ legacy) | No | Non-upgradable; exchange-only for G3 |
| **G3** | CAN, **LIN**, **DS2** | No | DS2 is a pre-CAN BMW-era bus — present for early **L322** Range Rovers, which were BMW-platform (2002–2005). This is the only "German" DNA in the tool. |
| **G4** | CAN, LIN, DS2, **DoIP** | **Yes** | Required for 2020+ vehicles with DoIP-only ECUs. The **Pro** ships *both* a G4 and a G3 unit (older modules still answer only on CAN). |

### 2.3 Feature model

Functions split into two tiers:

- **Diagnostics** (always available on supported vehicles): fault read/clear,
  live data (app shows up to 8 PIDs at once), output/actuator control, service
  & test routines, email export of faults/live data/ECU info.
- **Advanced programming**: CCF (Car Configuration File) read/edit/save/restore,
  suspension height calibration, key programming, and **ECU flashing** (coverage
  *varies per platform* — this is the crucial caveat, see §6).

### 2.4 Licensing model (business-model reference)

Activation is **per-vehicle VIN**:

1. Tool displays a 10-character hex *activation code* bound to the connected car.
2. Owner submits it via web form; an *unlock code* is emailed back.
3. **BT** model = full diagnostics + advanced programming on **one free VIN**;
   extra VINs are paid licences.
4. **Pro** model = fully unlocked for advanced programming across VINs.

Firmware updates over USB or internet; historically free on BT, with reports of
an annual fee model at one point — terms have shifted over time.

### 2.5 Can it touch engine management? Yes — as a *pipe*, not a *tuner*

This is the single most important architectural insight for our goal:

- The iiDTool is a **diagnostic + flashing transport**. Native engine-related
  functions are fault/live/actuation plus **reflashing the engine ECU**.
- **Engine tuning is not intelligence inside the device.** A performance *tune
  file* is bought separately (third parties such as Bell Auto Services sell e.g.
  a 2.7 L TDV6 remap for ~£350+VAT), VIN-locked, and **flashed through** the
  iiDTool. Workflow: export ECU info via the app → send to tuner → receive
  calibration → tool writes it.
- So the device **can read and reflash the engine ECU**, but the map-editing
  intelligence lives in an external file. **Our tool should mirror this
  separation**: a robust, safe flashing transport first; calibration content as
  a separate, pluggable layer later.

---

## 3. Reference implementation: `jlr-open-diag`

The strongest existing precedent is the open-source **`jlr-open-diag`**
(GitHub `ohenriquet/lr-scanner`) — a cross-platform reimplementation of JLR's
SDD (Symptom Driven Diagnostics) stack. It is the closest thing to a blueprint
and validates feasibility on a real car (Discovery 4 / L319 3.0 SDV6).

| Area | Status in that project |
|---|---|
| Mongoose Pro JLR **J2534** USB driver (`mongoose` crate, LGPL) | Working |
| **UDS over ISO-TP**: VIN, module scan, DTCs + help text, live data | **Working on car** |
| Security access (UDS 0x27) | Reported working (algorithm not published) |
| SDD `.exml` data decode (3DES) → SQLite | Working |
| CCF **read**/decode (BCM) | Working on car |
| CCF **write** | **Blocked** — see §6 |
| UI | Rust core + Flutter front-end; macOS connects |
| Licensing | MIT core; contains **no JLR data** (imports the user's own SDD install locally) |

Key takeaways for us:

1. **A J2534 pass-thru + UDS/ISO-TP core is a proven path on macOS.**
2. **Read/diagnose/config-read is achievable without defeating anything.**
3. **Write/flash is gated by an online-delivered Secondary Boot Loader** (§6) —
   a hard architectural wall, not a coding gap.
4. **Rust core + native/Flutter UI** is a sane, portable architecture. For a
   *native-feeling macOS* app we can instead put a **Swift/SwiftUI** front-end
   over a Rust or C protocol core (FFI), keeping the heavy protocol logic in a
   portable, testable library.

---

## 4. The protocol stack (what we must implement)

```
┌─────────────────────────────────────────────┐
│  SwiftUI app (macOS)                         │  UI, map viz, workflows
├─────────────────────────────────────────────┤
│  Diagnostic session manager                  │  session state, VIN/ECU DB
├───────────────┬─────────────────────────────┤
│  UDS (ISO 14229)                             │  0x10/0x22/0x19/0x27/0x2E/0x31/0x34-37
├───────────────┼─────────────────────────────┤
│  ISO-TP (ISO 15765-2) │  DoIP (ISO 13400)    │  transport / segmentation
├───────────────┼─────────────────────────────┤
│  CAN / CAN-FD         │  Ethernet (Activation)│  link layer
├───────────────┴─────────────────────────────┤
│  Hardware abstraction layer (HAL)            │  J2534 pass-thru / BLE dongle
└─────────────────────────────────────────────┘
```

### 4.1 Hardware abstraction layer (HAL)

Two adapter families to support:

- **J2534 pass-thru** (Mongoose Pro JLR, Tactrix, DrewTech, etc.). J2534 is a
  Windows DLL API; on macOS we talk to the device over **USB via IOKit / libusb**
  and implement the pass-thru semantics ourselves (as `jlr-open-diag`'s
  `mongoose` crate does). This is the path to flashing-grade throughput and
  DoIP.
- **BLE dongle** (iiDTool-style). A future in-house dongle would expose a GATT
  service; the HAL abstracts "send CAN/DoIP frame / receive frame" so the upper
  stack is adapter-agnostic.

The HAL interface is deliberately narrow:

```swift
protocol VehicleLink {
    func openChannel(_ proto: BusProtocol, baud: Int) throws -> Channel
}
protocol Channel {
    func send(_ frame: Frame) throws
    func receive(timeout: Duration) throws -> Frame
    func setFilter(_ filter: MessageFilter) throws
    func close()
}
```

### 4.2 CAN / ISO-TP

- Classic 11-bit and 29-bit CAN; ISO-TP (ISO 15765-2) single-frame / first-frame
  / consecutive-frame / flow-control segmentation for payloads > 7 bytes.
- Per-ECU request/response CAN IDs come from the vehicle/ECU definition DB (§5).

### 4.3 DoIP (ISO 13400) — G4-class vehicles

- Ethernet-over-OBD. Vehicle Identification announcement, routing activation,
  then UDS payloads inside DoIP messages. Needed for 2020+ modules that no longer
  answer on CAN. This is the single biggest *hardware* requirement for recent
  cars and the reason the iiDTool needed a new generation.

### 4.4 UDS (ISO 14229) — the service layer

Services the tool needs, by capability:

| Service | SID | Used for | Risk tier |
|---|---|---|---|
| DiagnosticSessionControl | 0x10 | enter default/extended/programming session | low |
| ReadDataByIdentifier | 0x22 | live data, ECU info, VIN, part numbers | low (read) |
| ReadDTCInformation | 0x19 | fault reading | low (read) |
| ClearDiagnosticInformation | 0x14 | fault clearing | low |
| InputOutputControlByIdentifier | 0x2F | actuator/output tests | medium |
| RoutineControl | 0x31 | service routines (regen, calibration, erase) | medium–high |
| SecurityAccess | 0x27 | unlock protected functions (seed/key) | **gated** |
| WriteDataByIdentifier | 0x2E | write config items / CCF entries | high |
| Request/Transfer/ExitTransfer | 0x34/0x36/0x37 | block download of firmware/calibration | high |

**MVP uses only the low-risk read/clear services.** Everything at "high"/"gated"
is a later phase and runs into §6.

---

## 5. Vehicle & ECU definition database

The protocol stack is generic; the per-vehicle knowledge is data. Modelled on
how SDD/`jlr-open-diag` separate code from car data, and on the iiDTool's VIN
model.

A JSON/SQLite definition per platform & ECU carries:

- CAN request/response IDs (and DoIP logical addresses) per module
- DID map: identifier → {name, type, scaling, unit} for live data & info
- DTC → description tables
- Routine IDs and their meaning
- Memory/segment layout for calibration reads (later phase)

Example target engine ECUs (diesel, L319 and relatives):

| Platform | Engine | Engine ECU | Transport |
|---|---|---|---|
| Discovery 3/4 (L319) | 2.7 TDV6 | Siemens/Continental SID201/SID204/SID206 family | CAN |
| Discovery 4 (L319) | 3.0 SDV6 | **Bosch EDC17CP11** (TC1796) | CAN |
| RR Sport / later | 3.0 | Bosch EDC17CP42 class | CAN |
| Transmission | ZF 6HP/8HP | TCM (ZF) | CAN |

> ECU part/calibration numbers must be verified against the *physical* module —
> do not assume from platform alone.

---

## 6. The hard walls (be honest about these up front)

### 6.1 Security Access (UDS 0x27)

Protected functions (writes, flashing, key ops) require a seed/key exchange: the
ECU issues a random seed, the tester returns a key derived by a secret algorithm
keyed to that ECU family. **This document does not contain or derive those
algorithms.** For legitimately owned vehicles, the supported routes are the
manufacturer's online programming service and approved tooling. Our tool should
treat 0x27 as a provider interface — pluggable, not bundled — and ship **no**
JLR key material.

### 6.2 Secondary Boot Loader (SBL) — the CCF/flash write wall

`jlr-open-diag`'s central finding: reading config works, **writing does not**,
because modern JLR modules (e.g. BCM) will not accept erase/flash until a
**Secondary Boot Loader** is downloaded into their RAM first. Without it, erase
returns UDS negative response **`7F 31 22`** (conditionsNotCorrect) even with the
right session and security. The SBL is **not** in a local SDD install — SDD
fetches it at write-time from JLR's **TOPIx** servers. This is an online,
authenticated dependency, not a byte we can reconstruct offline.

**Implication:** full write/flash parity with a dealer tool requires either (a)
JLR online access, or (b) lawfully obtained per-VIN programming files. Our MVP
deliberately stops *before* this wall.

### 6.3 Secure Gateway / Secured Diagnostics (2018+)

Later JLR vehicles add a **Secure Gateway Module (SGM)** and "Secured
Diagnostics": privileged operations require online authentication against JLR
(TOPIx / Pathfinder). Generic tools are blocked from gateway-protected writes.
Reportedly not enforced in some regions (e.g. the Americas) — unverified and
not something to design around. Our architecture isolates this behind the
"privileged operation provider" so the diagnostic/read product works regardless.

---

## 7. macOS application architecture

**Front-end:** Swift / SwiftUI (native, per the original product decision).
**Core:** a portable protocol library (Rust or C++), exposed to Swift via a thin
FFI, so the stack is unit-testable off-device and reusable for a future iOS app
or an in-house BLE dongle's firmware-side tooling.

```
JLRTuner.app
├─ UI (SwiftUI)            Connection · Dashboard · Faults · LiveData · CCF viewer
├─ ViewModels (MVVM)
├─ CoreBridge (Swift↔FFI)
└─ libjlrdiag (Rust/C)     HAL · CAN/ISO-TP · DoIP · UDS · DID/DTC decode
                           + VehicleDB (SQLite)
```

macOS-specific concerns:
- **USB access** to the J2534 adapter via IOKit; app is **not** sandboxable in
  the MAS sense if it needs raw USB — plan for Developer-ID notarized
  distribution outside the App Store.
- Driver/entitlement: `com.apple.security.device.usb` if partially sandboxed.
- Background BLE (future dongle) needs the Bluetooth entitlement.

---

## 8. Phased roadmap

| Phase | Deliverable | Touches security walls? |
|---|---|---|
| **0** | This spec + reference-source dossier | No |
| **1 (MVP)** | J2534 HAL on macOS; connect; read VIN; module scan; DTC read/clear; live data (read-only UDS 0x22/0x19/0x14) | **No** |
| **2** | CCF/config **read** + decode; saved snapshots; richer live-data dashboards & map/heatmap visualisation | No (read only) |
| **3** | Actuator/output tests, service routines (regen, calibrations) via 0x2F/0x31 | Medium (owner-authorised) |
| **4** | Write/flash transport (0x27 provider, 0x34–37 block transfer) — *only* with lawful programming files / online access | **Yes — gated** |
| **5** | Pluggable calibration layer (tune files as external, VIN-locked content), mirroring the iiDTool model | Yes |

MVP (Phase 1) is fully achievable with no security circumvention and is the
right place to prove the stack on a real car.

---

## 9. Legal & Safety

- **Own-vehicle only.** This tooling is for vehicles the user owns or is
  authorised to service.
- **No security circumvention shipped.** No seed-key algorithms, no SGM bypass,
  no SBL redistribution. Protected operations are provider interfaces fed by
  lawful credentials/files.
- **Emissions.** Removing or defeating EGR/DPF/SCR on a road vehicle is illegal
  in the US (Clean Air Act) and many jurisdictions. JLRTuner will not implement
  emissions-defeat routines. Performance calibration that keeps emissions
  equipment intact, and off-road/competition use where lawful, are the only
  in-scope tuning directions.
- **Warranty / type approval.** Any reflash may void warranty and alter type
  approval; the app must surface this before any write.
- **Brick risk.** Flashing can render a module inoperable. Any write phase must
  back up first, verify power/ignition state, checksum every block, and require
  explicit confirmation.

---

## 10. Open questions

1. Which specific JLR platform(s) and model years are the first targets? (Drives
   CAN-vs-DoIP and which ECU definitions to build first.)
2. Do we standardise on the **Mongoose Pro JLR** J2534 adapter for Phase 1 (max
   reuse of `jlr-open-diag`'s proven driver) or a broader J2534 abstraction?
3. Rust vs C++ for the core library (Rust preferred: memory safety + the
   existing reference code is Rust).
4. Is an in-house BLE dongle a real goal, or is J2534 sufficient? (BLE RE of the
   `IIDControl` app would be a separate, deeper phase requiring the APK.)

See `REFERENCES.md` for the full source dossier.
