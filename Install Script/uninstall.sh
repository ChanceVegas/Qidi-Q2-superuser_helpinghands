#!/bin/sh

echo "Starting universal uninstall / revert tool..."
echo ""

###############################################################################
# 1. BACK UP CURRENT CONFIGS BEFORE ANYTHING IS REMOVED
###############################################################################

echo "Backing up current configs before uninstall..."

mkdir -p /home/mks/mudinstallbackups

# rsync:
#   -a = archive mode (preserves structure, permissions, timestamps)
rsync -a /home/mks/printer_data/config/ /home/mks/mudinstallbackups/

echo "Backup complete."
echo ""

###############################################################################
# 2. UNINSTALL HELIXSCREEN (IF INSTALLED)
###############################################################################

echo "Checking for HelixScreen installation..."

if [ -d "/home/mks/helixscreen" ]; then
    echo "HelixScreen detected. Uninstalling..."

    # IMPORTANT:
    # --remove = uninstall ONLY (no reinstall)
    curl -fL https://releases.helixscreen.org/install.sh | sudo sh -s -- --remove

    echo "HelixScreen uninstall complete."
else
    echo "HelixScreen not detected. Skipping uninstall."
fi

echo ""

###############################################################################
# 3. UNINSTALL BUNNY BOX (HAPPY-HARE FORK)
###############################################################################

echo "Checking for Bunny Box installation..."

if [ -d "/home/mks/Happy-Hare" ]; then
    echo "Bunny Box detected at /home/mks/Happy-Hare"
    echo "Attempting uninstall..."

    # IMPORTANT:
    # Happy-Hare requires bash, not sh
    if [ -f "/home/mks/Happy-Hare/install.sh" ]; then
        sudo bash /home/mks/Happy-Hare/install.sh -d
        echo "Bunny Box uninstall complete."
    else
        echo "ERROR: install.sh not found inside Happy-Hare."
        echo "Skipping Bunny Box uninstall."
    fi
else
    echo "Bunny Box not detected. Skipping uninstall."
fi

echo ""

###############################################################################
# 4. RESTORE FULL CONFIG FOLDER FROM mudstockbackups
###############################################################################

echo "Restoring full config folder from mudstockbackups..."

if [ ! -d "/home/mks/mudstockbackups" ]; then
    echo "WARNING: No mudstockbackups folder found."
    echo "Skipping config restore."
else
    rsync -a /home/mks/mudstockbackups/ /home/mks/printer_data/config/
    echo "Config restore complete."
fi

echo ""

###############################################################################
# 5. FINAL MESSAGE
###############################################################################

echo "Universal uninstall / revert complete."
echo "Your system is now restored as much as possible."
