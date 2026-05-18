#!/bin/sh

###############################################################################
# Qidi Q2 – "Just Faster" Installer
# This variant keeps the stock screen and only applies the lightweight
# performance improvements: faster macros, cleaner configs, and KAMP tweaks.
#
# It does NOT install Bunny Box or HelixScreen.
###############################################################################

# Safety check — running as root will break permissions on the Q2.
if [ "$(id -u)" -eq 0 ]; then
  echo "Do not run this script as root. Run it as the printer user (usually 'mks')."
  exit 1
fi

echo ""
echo "========================================================="
echo "   Qidi Q2 – Applying 'Just Faster' Configuration"
echo "========================================================="
echo ""

###############################################################################
# 1. BACKUP CURRENT CONFIGS
###############################################################################

echo "Backing up current configs to /home/mks/mudstockbackups ..."
mkdir -p /home/mks/mudstockbackups

rsync -a /home/mks/printer_data/config/ /home/mks/mudstockbackups/

echo "Backup complete."
echo ""

###############################################################################
# 2. APPLY UPDATED CONFIG FILES
###############################################################################

echo "Updating gcode_macro.cfg ..."
curl -sSL "https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/refs/heads/main/Install%20Script/gcode_macro%28no.box.no.hs%29.cfg" \
  -o /home/mks/printer_data/config/gcode_macro.cfg

echo "Updating printer.cfg ..."
curl -sSL "https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/refs/heads/main/Install%20Script/Just%20Faster%20printer.cfg" \
  -o /home/mks/printer_data/config/printer.cfg

echo "Applying KAMP settings ..."
curl -sSL "https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/refs/heads/main/Install%20Script/KAMP_settings.cfg" \
  -o /home/mks/printer_data/config/KAMP_Settings.cfg

echo ""
echo "Config files updated."
echo ""

###############################################################################
# 3. FINISH
###############################################################################

echo "========================================================="
echo "   Install Complete – Your Q2 is now 'Just Faster'"
echo "========================================================="
echo ""
echo "No UI changes, no Bunny Box, no HelixScreen — just a cleaner,"
echo "faster OEM+ experience with improved macros and KAMP tweaks."
echo ""
