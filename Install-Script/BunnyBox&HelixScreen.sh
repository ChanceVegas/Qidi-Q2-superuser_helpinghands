#!/bin/bash
# =====================================================================
# BunnyBox & HelixScreen installer for Qidi Q2
# (with box_drying.cfg fix for spool rotation during filament drying)
#
# CHANGES vs upstream:
#   * Shebang #!/bin/sh -> #!/bin/bash. Dash/busybox-sh refused to parse
#     the URLs containing "(" and failed with:
#         sh: 30: Syntax error: "(" unexpected
#     Bash handles them once they're properly quoted, which they now are.
#   * REPO_BASE is defined once at the top - fork-friendly.
#   * Every curl has --fail, so a 404/500 download aborts the script
#     instead of silently writing an HTML error page over your config.
#   * Backups are timestamped so re-running the installer never destroys
#     the original stock backup.
#   * Added download of box_drying.cfg - restores Qidi Box spool rotation
#     during drying, which is lost when Happy Hare's installer comments
#     out [include box.cfg].
# =====================================================================

set -euo pipefail

# ---------- repo bases (edit these if you fork) ----------------------
REPO_BASE='https://raw.githubusercontent.com/ChanceVegas/Qidi-Q2-superuser_helpinghands/refs/heads/main/Install%20Script'
BUNNYBOX_INSTALLER='https://raw.githubusercontent.com/Camden-Winder/Bunny-Box/refs/heads/main/Q2/install-bb-q2.sh'
HELIXSCREEN_INSTALLER='https://raw.githubusercontent.com/prestonbrown/helixscreen/main/scripts/install.sh'

# ---------- paths ----------------------------------------------------
CONFIG_DIR='/home/mks/printer_data/config'
BACKUP_ROOT='/home/mks/mudstockbackups'
HELIX_CONFIG_DIR='/home/mks/helixscreen/config'

# ---------- helpers --------------------------------------------------
banner() {
    echo ""
    echo "================================================================="
    echo "  $1"
    echo "================================================================="
}

# Download a file with strict failure handling. If the HTTP status is 4xx
# or 5xx, curl exits non-zero (because of --fail) and set -e aborts here.
fetch() {
    local url="$1"
    local dest="$2"
    curl --fail --silent --show-error --location "$url" --output "$dest"
}

# ---------- 1. Backup ------------------------------------------------
banner "1/7  Backing up current configs"

BACKUP_DIR="${BACKUP_ROOT}/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
rsync -a "${CONFIG_DIR}/" "${BACKUP_DIR}/"
echo "Backup written to ${BACKUP_DIR}"

# ---------- 2. Install Bunny Box -------------------------------------
banner "2/7  Installing Bunny Box (Happy Hare MMU)"
# wget -qO - downloads quietly and pipes directly into bash.
wget -qO - "$BUNNYBOX_INSTALLER" | bash
echo "Bunny Box installed."

# ---------- 3. Install HelixScreen -----------------------------------
banner "3/7  Installing HelixScreen"
curl --fail --silent --show-error --location "$HELIXSCREEN_INSTALLER" | sh
echo "HelixScreen installed."

# ---------- 4. Drop in the unified gcode_macro and printer configs ---
banner "4/7  Installing unified gcode_macro.cfg & printer.cfg"
fetch "${REPO_BASE}/gcode_macro(BunnyBox%26HelixScreen).cfg" \
      "${CONFIG_DIR}/gcode_macro.cfg"
fetch "${REPO_BASE}/printer(BunnyBox%26HelixScreen).cfg" \
      "${CONFIG_DIR}/printer.cfg"
echo "Unified configs installed."

# ---------- 5. Install box_drying.cfg --------------------------------
banner "5/7  Installing box_drying.cfg (restores spool rotation during drying)"
fetch "${REPO_BASE}/box_drying.cfg" \
      "${CONFIG_DIR}/box_drying.cfg"
echo "box_drying.cfg installed."

# ---------- 6. KAMP settings -----------------------------------------
banner "6/7  Applying KAMP settings"
fetch "${REPO_BASE}/KAMP_settings.cfg" \
      "${CONFIG_DIR}/KAMP_settings.cfg"
echo "KAMP settings applied."

# ---------- 7. HelixScreen settings ----------------------------------
banner "7/7  Applying HelixScreen settings"
mkdir -p "$HELIX_CONFIG_DIR"
fetch "${REPO_BASE}/helixscreen_settings.json" \
      "${HELIX_CONFIG_DIR}/settings.json"
echo "HelixScreen settings applied."

# ---------- Done -----------------------------------------------------
banner "Install complete"
cat <<EOF

Next steps:
  1. Run FIRMWARE_RESTART (from the Klipper console or HelixScreen).
  2. Verify Klipper starts cleanly: systemctl status klipper
  3. Smoke-test drying rotation:
        BOX_DRY TEMP=45 TIME=10
     Watch the console; within ~5 minutes you should see
     "Box drying detected (target 45C). Rotating spools..."
     and hear the gear steppers tick.
  4. To cancel drying at any time:
        BOX_DRY_STOP

If anything looks wrong, your prior config is preserved at:
  ${BACKUP_DIR}

EOF
