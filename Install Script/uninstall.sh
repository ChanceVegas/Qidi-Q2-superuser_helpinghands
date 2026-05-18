#!/bin/sh

echo "Starting universal uninstall / revert tool..."
echo ""

###############################################################################
# 1. BACK UP CURRENT CONFIGS BEFORE ANYTHING IS REMOVED
###############################################################################

echo "Backing up current configs before uninstall..."

# Create the backup directory for pre-uninstall backups.
mkdir -p /home/mks/mudinstallbackups

# rsync:
#   -a = archive mode (preserves structure, permissions, timestamps)
# This overwrites previous backups in mudinstallbackups.
rsync -a /home/mks/printer_data/config/ /home/mks/mudinstallbackups/

echo "Backup complete."
echo ""

###############################################################################
# 2. UNINSTALL HELIXSCREEN (IF INSTALLED)
###############################################################################

echo "Checking for HelixScreen installation..."

# HelixScreen installs into /home/mks/helixscreen
if [ -d "/home/mks/helixscreen" ]; then
    echo "HelixScreen detected. Uninstalling..."

    # curl:
    #   -f = fail on server errors
    #   -S = show errors
    #   -L = follow redirects
    curl -fSL https://releases.helixscreen.org/install.sh | sudo sh -s -- --clean

    echo "HelixScreen uninstall complete."
else
    echo "HelixScreen not detected. Skipping uninstall."
fi

echo ""

###############################################################################
# 3. UNINSTALL BUNNY BOX (HAPPY-HARE FORK)
###############################################################################

echo "Checking for Bunny Box installation..."

# Your Q2 uses: /home/mks/Happy-Hare
if [ -d "/home/mks/Happy-Hare" ]; then
    echo "Bunny Box detected at /home/mks/Happy-Hare"
    echo "Attempting uninstall..."

    # Happy-Hare uninstall:
    #   install.sh -d
    if [ -f "/home/mks/Happy-Hare/install.sh" ]; then
        sudo sh /home/mks/Happy-Hare/install.sh -d
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

# Ensure the backup folder exists before restoring.
if [ ! -d "/home/mks/mudstockbackups" ]; then
    echo "ERROR: No mudstockbackups folder found."
    echo "Cannot restore stock configs."
    exit 1
fi

# rsync:
#   -a = archive mode
# This overwrites the entire config folder with the stock backup.
rsync -a /home/mks/mudstockbackups/ /home/mks/printer_data/config/

echo "Config restore complete."
echo ""

###############################################################################
# 5. FINAL MESSAGE
###############################################################################

echo "Universal uninstall / revert complete."
echo "Your system is now restored to the state saved in mudstockbackups."
