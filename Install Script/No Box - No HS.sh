#!/bin/sh
echo "gcode_macro.cfg is being changed"

curl -sSL https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/refs/heads/main/Install%20Script/gcode_macro%28no.box.no.hs%29.cfg \
  -o /home/mks/printer_data/config/gcode_macro.cfg

echo "KAMP settings are being adjusted"

curl -sSL https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/refs/heads/main/Install%20Script/KAMP_settings.cfg \
  -o /home/mks/printer_data/config/KAMP_Settings.cfg

echo "congrats, everything is now installed"
