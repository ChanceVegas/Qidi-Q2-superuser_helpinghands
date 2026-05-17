#!/bin/sh

echo "Backing up current config..."
mkdir -p /home/mks/printer_data/config/backup
rsync -a /home/mks/printer_data/config/ /home/mks/printer_data/config/backup/

echo "gcode_macro.cfg is being changed"
curl -sSL https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/refs/heads/main/Install%20Script/gcode_macro%28no.box.no.hs%29.cfg \
  -o /home/mks/printer_data/config/gcode_macro.cfg

echo "Printer.cfg is being updated"
curl -sSL https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/refs/heads/main/Install%20Script/Just%20Faster%20printer.cfg \
  -o /home/mks/printer_data/config/printer.cfg

echo "KAMP settings are being adjusted"
curl -sSL https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/refs/heads/main/Install%20Script/KAMP_settings.cfg \
  -o /home/mks/printer_data/config/KAMP_Settings.cfg

echo "congrats, everything is now installed"
