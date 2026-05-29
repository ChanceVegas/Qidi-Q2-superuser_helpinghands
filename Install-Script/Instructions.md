# Install Scripts – Qidi Q2 Superuser

There are multiple install scripts in this repo. Make sure you run the one that matches what you want to install.

**Warning** this script is actively being modified. All install scripts may not work. If you would like to see the status and get updates, join the Discord listed at top of readme

All scripts will:

- Back up your current config (backup system is being improved)
- Apply faster PRINT_START and PRINT_END macros
- Lower the bed fully at print end
- Install the `screw_tilt_adjust` macro  
  [Documentation](https://github.com/bluedrool/Qidi-Q2-tuning-tweaks-and-mods/blob/main/docs/tramming.md)

To use any install script:

1. SSH into your printer  
   ```sh
   ssh mks@<printer.ip.address>
   ```
2. Enter the password:  
   ```sh
   makerbase
   ```

---

## Whole 9 Yards Install

**Installs:** Bunny Box + HelixScreen + my custom config changes  
This is the full setup I run on my own Q2.

**Compatibility** Q2 with Qid Box, doesn't work with non-qidi box printers. 

### Pros

- **Bunny Box** adds improved box functionality, faster loading, and better multicolor behavior.  
  [Bunny Box Documentation](https://github.com/Wazzup77/Bunny-Box)
- **HelixScreen** replaces the stock UI and works seamlessly with Bunny Box.  
  [Helixscreen Documentation](https://github.com/prestonbrown/helixscreen) 
- Ships with a preconfigured screen layout.

### Cons

- Bunny Box currently requires HelixScreen.  
- HelixScreen is working on stock screen support, but it’s not ready yet.

### Install command

```sh
curl -sSL https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/refs/heads/main/Install-Script/BunnyBox%26HelixScreen.sh | sh
```

After installation, download and import the Orca slicer presets:

[Presets](https://github.com/Camden-Winder/Qidi-Q2-superuser/blob/main/Install-Script/Printer%20Presets/1.%20Presets.md)

---

## Just Faster

**Installs:** Only the macro and config improvements  

**Compatibility** Q2's without the box, doesn't work on printers with the box.

This is for users who want to keep the stock screen and avoid modifying (or don't have) the Qidi Box.  
It’s the clean OEM+ setup — faster starts, cleaner macros, nothing extra.

### Pros

- Keeps the stock screen  
- Faster PRINT_START  
- Cleaner macros  
- No UI changes  
- No Bunny Box or HelixScreen required

### Cons

- You don’t get Bunny Box  
- You don’t get HelixScreen

### Install command

```sh
curl -sSL https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/refs/heads/main/Install-Script/JustFasterPrinter.sh | sh
```

---

## Uninstall and Revert

If you want to remove everything and go back to your previous configuration, use the AIO menu's **Option 4 - Revert to Backup**. The AIO restore path is the maintained path for this fork.

This removes:

- Bunny Box  
- HelixScreen  
- All applied config changes  
- And restores your backed-up configs (if available), including the stock `/home/mks/printer_data/config/KAMP` directory when it was present in the first AIO backup

### Recommended revert command

```sh
curl -sSL https://raw.githubusercontent.com/ChanceVegas/Qidi-Q2-superuser_helpinghands/refs/heads/main/All_in_One_Installer/aio_menu.sh | bash
```

Then choose option 4.

---

## Notes

- All scripts are designed for the Qidi Q2’s default user (`mks`).  
- Do **not** run these scripts as root — it will break permissions.  
- AIO backups are stored in `/home/mks/mudstockbackups`; the first clean stock snapshot is preserved there so Revert to Backup can restore stock behavior.
- More variants will be added as the project evolves.

---
