#!/bin/sh
echo "Bunny Box is installing"

# Install Bunny Box
wget -qO - https://raw.githubusercontent.com/Camden-Winder/Bunny-Box/refs/heads/main/Q2/install-bb-q2.sh | bash

echo "Helixscreen is installing"

# Install Helixscreen
curl -sSL https://raw.githubusercontent.com/prestonbrown/helixscreen/main/scripts/install.sh | sh

echo "Config changes are now being made"

echo "gcode_macro.cfg is being changed"
curl -sSL https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/main/Install%20Script/gcode_macro.cfg \
  -o /home/mks/printer_data/config/gcode_macro.cfg

echo "printer.cfg is being changed"
curl -sSL https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/main/Install%20Script/printer.cfg \
  -o /home/mks/printer_data/config/printer.cfg

echo "KAMP settings are being adjusted"
curl -sSL https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/main/Install%20Script/KAMP_settings.cfg \
  -o /home/mks/printer_data/config/KAMP_Settings.cfg

echo "helixscreen settings are being adjusted"
curl -sSL https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/main/Install%20Script/helixscreen_settings.json \
  -o /home/mks/helixscreen/config/settings.json

echo "Congrats, everything should be installed"
