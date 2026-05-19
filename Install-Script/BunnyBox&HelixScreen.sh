#!/bin/bash
# =====================================================================
# BunnyBox & HelixScreen installer for Qidi Q2
# (with box_drying.cfg fix for spool rotation during filament drying)
#
# Features:
#   * Detects existing BunnyBox / HelixScreen installs and offers an
#     interactive menu: reinstall, clean reinstall, individual or
#     combined uninstall, or cancel
#   * read </dev/tty so the interactive prompt works when piped from curl
#   * curl --fail on every download - 404s abort instead of writing
#     HTML error pages over your config files
#   * Timestamped backups - re-running never destroys the original
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

    if [ -f "${HAPPY_HARE_DIR}/install.sh" ]; then
        echo "Running Happy Hare uninstaller..."
        bash "${HAPPY_HARE_DIR}/install.sh" -u
    else
        echo "Happy Hare uninstaller not found, removing manually..."
        rm -rf "${CONFIG_DIR}/mmu"
        rm -rf "${HAPPY_HARE_DIR}"
        for f in mmu.py mmu_machine.py mmu_leds.py; do
            rm -f "${HOME}/klipper/klippy/extras/${f}"
        done
        rm -f "${HOME}/moonraker/moonraker/components/mmu_server.py"
    fi

    rm -f "${CONFIG_DIR}/bunnybox_macros.cfg"
    rm -f "${CONFIG_DIR}/box_drying.cfg"

    echo ""
    echo "BunnyBox / Happy Hare uninstalled."
    echo ""
    echo "  NOTE: Your printer.cfg still references [include mmu/base/*.cfg]"
    echo "  and [include bunnybox_macros.cfg]. Klipper will error on restart"
    echo "  until you either:"
    echo "    a) Restore your stock printer.cfg from backup, or"
    echo "    b) Reinstall BunnyBox"
    echo ""
    echo "  Backups are in: ${BACKUP_ROOT}/"
}

uninstall_helixscreen() {
    banner "Uninstalling HelixScreen"

    sudo systemctl stop helixscreen 2>/dev/null || true
    sudo systemctl disable helixscreen 2>/dev/null || true
    sudo rm -f /etc/systemd/system/helixscreen.service
    sudo systemctl daemon-reload 2>/dev/null || true
    rm -rf "$HELIX_DIR"

    echo "HelixScreen uninstalled."
}

# ---------- backup (used by both install and uninstall) ---------------
do_backup() {
    banner "Backing up current configs"
    BACKUP_DIR="${BACKUP_ROOT}/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    rsync -a "${CONFIG_DIR}/" "${BACKUP_DIR}/"
    echo "Backup written to ${BACKUP_DIR}"
}

# ---------- interactive menu -----------------------------------------
show_menu() {
    local has_bb has_hs
    has_bb=$(bunnybox_installed && echo true || echo false)
    has_hs=$(helixscreen_installed && echo true || echo false)

    echo ""
    echo "  Existing installation detected:"
    if [ "$has_bb" = true ]; then
        echo "    BunnyBox / Happy Hare : INSTALLED"
    else
        echo "    BunnyBox / Happy Hare : not found"
    fi
    if [ "$has_hs" = true ]; then
        echo "    HelixScreen           : INSTALLED"
    else
        echo "    HelixScreen           : not found"
    fi
    echo ""
    echo "  What would you like to do?"
    echo ""
    echo "    1) Reinstall over existing  (keeps current MMU calibration)"
    echo "    2) Clean reinstall          (uninstall all, then reinstall)"

    # Show individual uninstall options only for what's detected
    if [ "$has_bb" = true ] && [ "$has_hs" = true ]; then
        echo "    3) Uninstall BunnyBox only"
        echo "    4) Uninstall HelixScreen only"
        echo "    5) Uninstall both           (remove all and exit)"
        echo "    6) Cancel"
    elif [ "$has_bb" = true ]; then
        echo "    3) Uninstall BunnyBox only"
        echo "    4) Cancel"
    elif [ "$has_hs" = true ]; then
        echo "    3) Uninstall HelixScreen only"
        echo "    4) Cancel"
    fi

    echo ""
    printf "  Enter choice: "

    local choice
    read -r choice </dev/tty

    # Map choices based on what's installed
    if [ "$has_bb" = true ] && [ "$has_hs" = true ]; then
        case "$choice" in
            1) ACTION="reinstall" ;;
            2) ACTION="clean_reinstall" ;;
            3) ACTION="uninstall_bb" ;;
            4) ACTION="uninstall_hs" ;;
            5) ACTION="uninstall_both" ;;
            6) ACTION="cancel" ;;
            *) echo "  Invalid choice '${choice}'."; exit 1 ;;
        esac
    elif [ "$has_bb" = true ]; then
        case "$choice" in
            1) ACTION="reinstall" ;;
            2) ACTION="clean_reinstall" ;;
            3) ACTION="uninstall_bb" ;;
            4) ACTION="cancel" ;;
            *) echo "  Invalid choice '${choice}'."; exit 1 ;;
        esac
    elif [ "$has_hs" = true ]; then
        case "$choice" in
            1) ACTION="reinstall" ;;
            2) ACTION="clean_reinstall" ;;
            3) ACTION="uninstall_hs" ;;
            4) ACTION="cancel" ;;
            *) echo "  Invalid choice '${choice}'."; exit 1 ;;
        esac
    fi
}

# ---------- main flow ------------------------------------------------
banner "BunnyBox & HelixScreen Installer for Qidi Q2"

ACTION="fresh_install"

if bunnybox_installed || helixscreen_installed; then
    show_menu
else
    echo "  No existing installation detected. Proceeding with fresh install."
fi

# -- handle the chosen action -----------------------------------------
case "$ACTION" in
    cancel)
        echo "  Cancelled. Nothing changed."
        exit 0
        ;;

    uninstall_bb)
        do_backup
        uninstall_bunnybox
        banner "Done"
        echo "  BunnyBox removed. HelixScreen was not changed."
        echo "  Backup at: ${BACKUP_DIR}"
        exit 0
        ;;

    uninstall_hs)
        do_backup
        uninstall_helixscreen
        banner "Done"
        echo "  HelixScreen removed. BunnyBox was not changed."
        echo "  Backup at: ${BACKUP_DIR}"
        exit 0
        ;;

    uninstall_both)
        do_backup
        bunnybox_installed  && uninstall_bunnybox
        helixscreen_installed && uninstall_helixscreen
        banner "Done (uninstall complete)"
        echo "  Both BunnyBox and HelixScreen removed."
        echo "  Restore stock configs from: ${BACKUP_DIR}"
        exit 0
        ;;

    clean_reinstall)
        do_backup
        bunnybox_installed  && uninstall_bunnybox
        helixscreen_installed && uninstall_helixscreen
        echo "  Uninstall complete. Proceeding with fresh install..."
        ;;

    reinstall)
        echo "  Reinstalling over existing installation."
        ;;

    fresh_install)
        ;;
esac

# -- backup (for install paths that didn't already backup) ------------
if [ -z "${BACKUP_DIR:-}" ]; then
    do_backup
fi

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
