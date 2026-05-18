#!/bin/sh

echo "Starting uninstall and restore process..."

echo "Backing up current configs..."
# Create backup folder if missing. -p prevents errors if it already exists.
mkdir -p /home/mks/mudinstallbackups

# rsync -a preserves structure, permissions, timestamps, and handles nested folders.
rsync -a /home/mks/printer_data/config/ /home/mks/mudinstallbackups/
echo "Backup complete."
echo ""

echo "Checking for HelixScreen installation..."
# HelixScreen installs into /home/mks/helixscreen, so checking that folder
if [ -d "/home/mks/helixscreen" ]; then
    echo "HelixScreen detected. Uninstalling..."

    # curl -sSL:
    #   -s  silent (no progress bar)
    #   -S  show errors even when silent
    #   -L  follow redirects (required for GitHub/raw URLs)
    # --remove tells the HelixScreen installer to uninstall instead of install
    curl -sSL https://releases.helixscreen.org/install.sh | sudo sh -s -- --remove

    echo "HelixScreen uninstall complete."
else
    echo "HelixScreen not detected. Skipping."
fi

echo ""

echo "Checking for Bunny Box installation..."
# Bunny Box installs into /home/mks/Happy-Hare
if [ -d "/home/mks/Happy-Hare" ]; then
    echo "Bunny Box detected. Attempting uninstall..."

    # Bunny Box uses a bash-based installer, not sh.
    # -d flag triggers uninstall mode.
    if [ -f "/home/mks/Happy-Hare/install.sh" ]; then
        sudo bash /home/mks/Happy-Hare/install.sh -d
        echo "Bunny Box uninstall complete."
    else
        echo "install.sh not found inside Happy-Hare. Cannot uninstall."
    fi
else
    echo "Bunny Box not detected. Skipping."
fi

echo ""

echo "Restoring configs from mudstockbackups..."
# Restore only if the backup folder exists
if [ -d "/home/mks/mudstockbackups" ]; then
    # rsync -a restores the entire config folder exactly as it was
    rsync -a /home/mks/mudstockbackups/ /home/mks/printer_data/config/
    echo "Config restore complete."
else
    echo "No mudstockbackups folder found. Skipping restore."
fi

echo ""
echo "Uninstall and restore process complete."
