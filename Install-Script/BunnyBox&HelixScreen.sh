#!/bin/bash
# =====================================================================
# BunnyBox & HelixScreen installer for Qidi Q2
# (with box_drying.cfg fix for spool rotation during filament drying)
#
# CHANGES vs upstream:
#   * Shebang #!/bin/sh -> #!/bin/bash (dash choked on URLs with parens)
#   * REPO_BASE defined once at the top - fork-friendly
#   * curl --fail on every download - 404s abort cleanly instead of
#     writing HTML error pages over your config files
#   * Timestamped backups - re-running never destroys the original
#   * Detects existing BunnyBox / HelixScreen installs and offers an
#     interactive menu: reinstall over top, clean reinstall (uninstall
#     first), uninstall only, or cancel
#   * read </dev/tty so the interactive prompt works even when the
#     script is piped from curl
#   * box_drying.cfg restores Qidi Box spool rotation during drying
# =====================================================================

set -euo pipefail

# ---------- repo bases (edit these if you fork) ----------------------
REPO_BASE='https://raw.githubusercontent.com/ChanceVegas/Qidi-Q2-superuser_helpinghands/refs/heads/main/Install-Script'
BUNNYBOX_INSTALLER='https://raw.githubusercontent.com/Camden-Winder/Bunny-Box/refs/heads/main/Q2/install-bb-q2.sh'
HELIXSCREEN_INSTALLER='https://raw.githubusercontent.com/prestonbrown/helixscreen/main/scripts/install.sh'

# ---------- paths ----------------------------------------------------
CONFIG_DIR='/home/mks/printer_data/config'
BACKUP_ROOT='/home/mks/mudstockbackups'
HELIX_DIR='/home/mks/helixscreen'
HELIX_CONFIG_DIR="${HELIX_DIR}/config"
HAPPY_HARE_DIR="${HOME}/happy_hare"

# ---------- helpers --------------------------------------------------
banner() {
    echo ""
    echo "================================================================="
    echo "  $1"
    echo "================================================================="
}

# curl --fail exits non-zero on 4xx/5xx so set -e catches bad downloads
fetch() {
    local url="$1"
    local dest="$2"
    curl --fail --silent --show-error --location "$url" --output "$dest"
}

# ---------- detection ------------------------------------------------
bunnybox_installed() {
    [ -d "${CONFIG_DIR}/mmu" ] && [ -f "${CONFIG_DIR}/mmu/base/mmu_machine.cfg" ]
}

helixscreen_installed() {
    [ -d "$HELIX_DIR" ] || systemctl is-enabled helixscreen &>/dev/null
}

# ---------- uninstall ------------------------------------------------
uninstall_bunnybox() {
    banner "Uninstalling BunnyBox / Happy Hare"

    # Use the official Happy Hare uninstaller if it exists
    if [ -f "${HAPPY_HARE_DIR}/install.sh" ]; then
        echo "Running Happy Hare uninstaller..."
        bash "${HAPPY_HARE_DIR}/install.sh" -u
    else
        echo "Happy Hare uninstaller not found, removing manually..."
        rm -rf "${CONFIG_DIR}/mmu"
        rm -rf "${HAPPY_HARE_DIR}"
        # Remove MMU Klipper extras installed as symlinks by Happy Hare
        for f in mmu.py mmu_machine.py mmu_leds.py; do
            rm -f "${HOME}/klipper/klippy/extras/${f}"
        done
        # Remove moonraker component if present
        rm -f "${HOME}/moonraker/moonraker/components/mmu_server.py"
    fi

    # Remove BunnyBox-specific files
    rm -f "${CONFIG_DIR}/bunnybox_macros.cfg"
    rm -f "${CONFIG_DIR}/box_drying.cfg"

    echo "BunnyBox / Happy Hare uninstalled."
}

uninstall_helixscreen() {
    banner "Uninstalling HelixScreen"

    systemctl stop helixscreen 2>/dev/null || true
    systemctl disable helixscreen 2>/dev/null || true
    rm -f /etc/systemd/system/helixscreen.service
    systemctl daemon-reload 2>/dev/null || true
    rm -rf "$HELIX_DIR"

    echo "HelixScreen uninstalled."
}

# ---------- interactive menu -----------------------------------------
# NOTE: read </dev/tty is required when this script is piped from curl.
#       Without it, stdin is the pipe and read gets EOF immediately.
show_menu() {
    local bb_status hs_status
    bb_status=$(bunnybox_installed && echo "INSTALLED" || echo "not found")
    hs_status=$(helixscreen_installed && echo "INSTALLED" || echo "not found")

    echo ""
    echo "  Existing installation detected:"
    echo "    BunnyBox / Happy Hare : ${bb_status}"
    echo "    HelixScreen           : ${hs_status}"
    echo ""
    echo "  What would you like to do?"
    echo ""
    echo "    1) Reinstall over existing  (keeps current MMU calibration)"
    echo "    2) Clean reinstall          (uninstall first, then reinstall)"
    echo "    3) Uninstall only           (remove and exit)"
    echo "    4) Cancel"
    echo ""
    printf "  Enter choice [1-4]: "

    local choice
    read -r choice </dev/tty

    case "$choice" in
        1)
            echo "  Reinstalling over existing installation."
            DO_UNINSTALL=false
            DO_INSTALL=true
            ;;
        2)
            echo "  Clean reinstall: uninstalling first."
            DO_UNINSTALL=true
            DO_INSTALL=true
            ;;
        3)
            echo "  Uninstall only."
            DO_UNINSTALL=true
            DO_INSTALL=false
            ;;
        4)
            echo "  Cancelled. Nothing changed."
            exit 0
            ;;
        *)
            echo "  Invalid choice '${choice}'. Exiting."
            exit 1
            ;;
    esac
}

# ---------- main flow ------------------------------------------------
banner "BunnyBox & HelixScreen Installer for Qidi Q2"

DO_UNINSTALL=false
DO_INSTALL=true

if bunnybox_installed || helixscreen_installed; then
    show_menu
else
    echo "  No existing installation detected. Proceeding with fresh install."
fi

# -- optional uninstall -----------------------------------------------
if [ "$DO_UNINSTALL" = true ]; then
    bunnybox_installed  && uninstall_bunnybox
    helixscreen_installed && uninstall_helixscreen
fi

[ "$DO_INSTALL" = false ] && { banner "Done (uninstall only)"; exit 0; }

# -- backup -----------------------------------------------------------
banner "Backing up current configs"
BACKUP_DIR="${BACKUP_ROOT}/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
rsync -a "${CONFIG_DIR}/" "${BACKUP_DIR}/"
echo "Backup written to ${BACKUP_DIR}"

# -- BunnyBox ---------------------------------------------------------
banner "Installing BunnyBox (Happy Hare MMU)"
wget -qO - "$BUNNYBOX_INSTALLER" | bash
echo "BunnyBox installed."

# -- HelixScreen ------------------------------------------------------
banner "Installing HelixScreen"
curl --fail --silent --show-error --location "$HELIXSCREEN_INSTALLER" | sh
echo "HelixScreen installed."

# -- unified configs --------------------------------------------------
banner "Installing unified gcode_macro.cfg & printer.cfg"
fetch "${REPO_BASE}/gcode_macro-BunnyBox%26HelixScreen.cfg" \
      "${CONFIG_DIR}/gcode_macro.cfg"
fetch "${REPO_BASE}/printer(BunnyBox%26HelixScreen).cfg" \
      "${CONFIG_DIR}/printer.cfg"
echo "Unified configs installed."

# -- box_drying.cfg ---------------------------------------------------
banner "Installing box_drying.cfg (restores spool rotation during drying)"
fetch "${REPO_BASE}/box_drying.cfg" \
      "${CONFIG_DIR}/box_drying.cfg"
echo "box_drying.cfg installed."

# -- KAMP settings ----------------------------------------------------
banner "Applying KAMP settings"
fetch "${REPO_BASE}/KAMP_settings.cfg" \
      "${CONFIG_DIR}/KAMP_settings.cfg"
echo "KAMP settings applied."

# -- HelixScreen settings ---------------------------------------------
banner "Applying HelixScreen settings"
mkdir -p "$HELIX_CONFIG_DIR"
fetch "${REPO_BASE}/helixscreen_settings.json" \
      "${HELIX_CONFIG_DIR}/settings.json"
echo "HelixScreen settings applied."

# -- done -------------------------------------------------------------
banner "Install complete"
cat <<EOF

Next steps:
  1. Run FIRMWARE_RESTART (from the Klipper console or HelixScreen).
  2. Verify Klipper starts cleanly:
        systemctl status klipper
  3. Smoke-test spool rotation during drying:
        BOX_DRY TEMP=45 TIME=10
     Watch the Klipper console — within ~5 minutes you should see:
        "Box drying detected (target 45C). Rotating spools every 5.0 min."
     and hear the gear steppers tick.
  4. To stop drying at any time:
        BOX_DRY_STOP

Your prior config is preserved at:
  ${BACKUP_DIR}

EOF
