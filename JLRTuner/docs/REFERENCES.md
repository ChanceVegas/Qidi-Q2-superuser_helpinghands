# Source Dossier — JLRTuner Research

Collected during the pivot-to-JLR research pass. Vendor/marketing and forum
sources are flagged; treat capability claims from sellers as unverified until
checked against primary JLR documentation or confirmed on a car.

## GAP iiDTool — product, hardware, protocols

- GAP Diagnostic — IIDTool product page — <https://www.gap-diagnostic.com/products/iidtool/>
- GAP Diagnostic — IIDTool Pro shop page — <https://www.gap-diagnostic.com/shop/iidtool-pro/>
- GAP Diagnostic — FAQ — <https://www.gap-diagnostic.com/faq/>
- GAP Diagnostic — IIDTool G4 announcement (2020–2025 coverage) — <https://www.gap-diagnostic.com/2023/07/18/iidtool-g4-2/>
- IIDTool Pro / BT / regular — User Manual v3.00 (PDF) — <https://www.fullfatrr.com/gallery/albums/userpics/10672/IIDToolV3.00.pdf>
- IIDTool User Manual v3.00 Beta (PDF) — <https://media.disco3.co.uk/gallery/albums/userpics/11480/IIDToolV3_00-Beta.pdf>
- IIDTool L322 edition manual v2.17.09 (PDF) — <https://www.fullfatrr.com/gallery/albums/userpics/10672/IIDToolV2.17.09-RR02.pdf>
- IIDTool Pro manual (ManualsLib) — <https://www.manualslib.com/manual/2811790/Gap-Diagnostic-Iidtool-Pro.html>
- IIDTool Pro G3 manual (ManualsLib) — <https://www.manualslib.com/manual/3358598/Gap-Diagnostic-Iidtool-Pro-G3.html>
- IIDTool BT User Manual (manualzz) — <https://manualzz.com/doc/70903322/gap-diagnostic-iidtool-bt-user-manual>

## iiDTool companion app (BLE)

- IIDControl — Google Play (`com.gap.iidcontrol`) — <https://play.google.com/store/apps/details?id=com.gap.iidcontrol&hl=en_US>
- IIDControl — Apple App Store (id 634092136) — <https://apps.apple.com/us/app/iidcontrol/id634092136>
- IIDControl APK listing (version history) — <https://apkcombo.com/iidcontrol/com.gap.iidcontrol/>

## iiDTool G4 / DoIP / flashing coverage (retailers)

- JGS4x4 — Introducing the new G4 GAP IIDTool — <https://www.jgs4x4.co.uk/blog/introducing-the-new-g4-gap-iidtool/>
- JGS4x4 — GAP diagnostics landing — <https://www.jgs4x4.co.uk/gap-diagnostics>
- JGS4x4 — GAP IIDTool vs iCarsoft guide — <https://www.jgs4x4.co.uk/land-rover-diagnostic-equipment-guide-gap-iidtool-vs-icarsoft/>
- Bell Auto Services — IID BT Tool G4 (2017+) — <https://bellautoservices.co.uk/store/gap-diagnostics-iid-bt-tool-g4/>
- Terrafirma — IID BT Professional G4 — <https://terrafirma4x4.com/products/performance/scanners/tfiidbtg4>

## iiDTool-flashed remaps (tune-as-separate-file model)

- Bell Auto Services — IIDTool remaps & tuning landing — <https://bellautoservices.co.uk/store/iidtool-remaps-and-tuning/>
- Bell Auto Services — Discovery 2.7 TDV6 IIDTool remap — <https://bellautoservices.co.uk/store/iidtool-discovery-2-7l-tdv6-remap/>
- Bell Auto Services — RR Sport 2.7 TDV6 IIDTool remap — <https://bellautoservices.co.uk/store/iidtool-range-rover-sport-2-7l-tdv6-remap/>

## Open-source reverse-engineering precedent

- `ohenriquet/lr-scanner` (jlr-open-diag) — <https://github.com/ohenriquet/lr-scanner>
  - Rust core + Flutter UI; Mongoose Pro JLR J2534 driver; UDS/ISO-TP working on car; CCF read works, CCF write blocked on SBL.
- `5555l/sdd_engineer_code` — SDD engineering-access calculator (referenced; legacy password scheme, treat with caution re: malware history)
- `5555l/ccf_parser` — CCF parser (GPL, behaviour reference)

## JLR security / gateway / programming files (context, mostly sellers)

- JLR TOPIx Cloud Diagnostics — Toolbox & Applications user guide (JLR-hosted) — <https://topix.jaguar.jlrext.com/topix/service/document/1242750>
- Autologic — JLR J2534 Pass-Thru branded doc (PDF) — <https://static.autologic.com/J2534/JLR/JLR_PassThru_Branded_Nov16.pdf>
- Freelander2 forum — VBF files as BCM/ICM secondary bootloaders (user recollection) — <https://www.freel2.com/forum/post349548.html>
- ANCIT — UDS bootloader overview — <https://www.ancitconsulting.com/udsbootloader.html>
- PiEST Systems — UDS ECU flashing sequence (10 steps) — <https://piestsystems.com/blog/uds-ecu-flashing-sequence/>

## JLR engine ECUs (platform background; bench-tool sources, verify on module)

- Discovery IV 3.0 SDV6 → Bosch EDC17CP11 (TC1796) — <http://blog.obdexpress.co.uk/2016/12/27/readwrite-land-rover-ecu-data-mpps-v18-or-kess-or-ktag/>
- EDC17CP11 read/write (FoxFlash) — <http://www.pcmtuner.org/foxflash-read-and-write-discovery-4-edc17cp11/>
- EDC17 CP11 pinout & boot guide (Scribd) — <https://www.scribd.com/document/849733317/Tricore-Jaguar-Edc17-Cp11-Hw2-1796-Intextflash>
- Autoflasher — Land Rover TDV6 / Ingenium / ZF chiptuning — <https://www.autoflasher.co.uk/chiptuning-land-rover>
- Understanding ECU types EDC15/16/17, MED17 — <https://www.tuning-database.co.uk/understanding-ecu-types-edc15-edc16-edc17-med17/>

## Transmission (TCM) tuning — ZF 8HP / 6HP

- Viezu — JLR 8-speed ZF 8HP gearbox tuning — <https://viezu.com/shop/gearbox-tuning-jaguar-land-rover-8-speed-zf-8hp/>
- ZF 8HP transmission (Wikipedia, applications) — <https://en.wikipedia.org/wiki/ZF_8HP_transmission>
- HP Tuners forum — ZF8 shift pressures & timing (ramp-rate/firmness) — <https://forum.hptuners.com/printthread.php?t=81943&pp=40>
- TCU tuning explained (what it changes) — <https://gulfeuroclinic.com/tcu-tuning-explained/>

## Flashing access methods (OBD vs bench vs boot)

- OBD vs Bench vs Boot Mode: reading/writing ECUs — <https://www.tuning-database.co.uk/obd-vs-bench-vs-boot-mode-ecu-reading-writing/>
- EDC17 control guide — tuning hardware / bench setup — <https://electronics.alibaba.com/buyingguides/edc17-control-guide-tuning-tools-bench-setup>
- EDC17 chip tuning FAQ (TriCore, boot/BSL) — <https://ktagecu.blogspot.com/2017/03/edc17-ecu-chip-tuning-faq.html>

## Live data (UDS services)

- UDS data-transmission services (0x22/0x2A/0x2C) — pyUDSKit docs — <https://pyudskit.readthedocs.io/en/latest/services/data-transmission/>
- UDS SID 0x2A ReadDataByPeriodicIdentifier — <https://uds-simulation.vercel.app/docs/sid_0x2a>

## Standards (for implementation)

- UDS — ISO 14229 (Unified Diagnostic Services)
- ISO-TP — ISO 15765-2 (CAN transport/segmentation)
- DoIP — ISO 13400 (Diagnostics over IP)
- OBD-II — ISO 15765-4 / SAE J1979
- J2534 — SAE pass-thru API

---

### Notes on content boundaries

Two research threads were intentionally not pursued to a how-to level:

1. **UDS SecurityAccess (0x27) seed-key derivation** for JLR modules — the
   reference project reports it working but does not publish the algorithm, and
   this project ships none.
2. **EGR/DPF/SCR defeat** — out of scope and illegal on road vehicles in many
   jurisdictions.

Both are documented in `TECHNICAL_SPEC.md` §6 and §10 as *constraints/walls*, not
as procedures.
