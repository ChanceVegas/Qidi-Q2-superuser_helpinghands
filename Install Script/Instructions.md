There are **multiple** install scripts, ensure you run the right one

All scripts will: back up the current config changes, apply the config changes to make print start macro faster, lower bed all the way down for print end, and install the screw_tilt_adjust macro ([here is documentation for that](https://github.com/bluedrool/Qidi-Q2-tuning-tweaks-and-mods/blob/main/docs/tramming.md))

To use the install script, ssh into your printer using `ssh mks@<printer.ip.address>` and enter `makerbase` as the password

### Whole 9 yards
This install will install Bunny Box, Helixscreen, and install my custom config changes for a better experience.

Pros and Cons: [Bunny Box](https://github.com/Wazzup77/Bunny-Box) adds improved box functionality, specifically things like faster loading times and improved multicolor.

[Helixscreen](https://github.com/prestonbrown/helixscreen) makes using the box with Bunny Box installed possible. It has low resource use and is very configurable. The install script ships with a base screen setup configured.
```
curl -sSL https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/refs/heads/main/Install%20Script/BB%20%26%20HS.sh | sh
```

After install, make sure to [download](https://github.com/Camden-Winder/Qidi-Q2-superuser/blob/main/Install%20Script/Printer%20Presets/Presets.md) and import the presets to Orca.

### Just faster
This install is for non-box users who wish to retain the stock screen. Barebones changes that only involve the adjustments listed for all scripts.
```
curl -sSL https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/refs/heads/main/Install%20Script/No%20Box%20-%20No%20HS.sh | sh
```
