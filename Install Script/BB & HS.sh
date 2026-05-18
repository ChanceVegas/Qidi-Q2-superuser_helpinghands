#!/bin/sh

echo "Backing up current configs before install..."

# Create the backup directory if it does not already exist.
# -p prevents errors if the folder already exists.
mkdir -p /home/mks/mudstockbackups

# Copy the entire config folder into the backup folder.
# rsync is used because:
#   - It safely overwrites existing files
#   - It preserves directory structure and permissions
#   - It handles nested folders correctly
# Flags:
#   -a = archive mode (preserves structure, permissions, timestamps)
# No verbose flags are used to avoid confusing inexperienced users.
rsync -a /home/mks/printer_data/config/ /home/mks/mudstockbackups/

echo "Backup complete."
echo ""

echo "Bunny Box is installing"

# Install Bunny Box
# wget:
#   -q  = quiet mode (no output except errors)
#   -O - = write output to stdout so it can be piped into bash
# wget does NOT hide download progress unless -q is used.
wget -O - https://raw.githubusercontent.com/Camden-Winder/Bunny-Box/refs/heads/main/Q2/install-bb-q2.sh | bash

echo "Helixscreen is installing"

# Install Helixscreen
# curl:
#   -S = show errors if they occur
#   -L = follow redirects (required for GitHub raw URLs)
# No -s flag is used, so curl will show a progress meter.
curl -SL https://raw.githubusercontent.com/prestonbrown/helixscreen/main/scripts/install.sh | sh

echo "Config changes are now being made"

echo "gcode_macro.cfg is being changed"
curl -SL https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/refs/heads/main/Install%20Script/gcode_macro.cfg \
  -o /home/mks/printer_data/config/gcode_macro.cfg

echo "printer.cfg is being changed"
curl -SL https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/refs/heads/main/Install%20Script/printer.cfg \
  -o /home/mks/printer_data/config/printer.cfg

echo "KAMP settings are being adjusted"
curl -SL https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/refs/heads/main/Install%20Script/KAMP_settings.cfg \
  -o /home/mks/printer_data/config/KAMP_Settings.cfg

echo "helixscreen settings are being adjusted"
curl -SL https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/refs/heads/main/Install%20Script/helixscreen_settings.json \
  -o /home/mks/helixscreen/config/settings.json

echo "Congrats, everything is now installed"
