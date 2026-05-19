#!/bin/bash
# =====================================================================
# Qidi Q2 Superuser - All-in-One (AIO) Installer / Manager
#
# A single entry point for the ChanceVegas/Qidi-Q2-superuser_helpinghands
# toolkit. Drives every supported install path and uninstall path from
# one ANSI-colored menu:
#
#   * Install BunnyBox & HelixScreen   (Q2 with Qidi Box)
#   * Install Just Faster Printer      (Q2 without Box, stock screen)
#   * Uninstall BunnyBox only
#   * Uninstall HelixScreen only
#   * Uninstall both
#   * Revert to Backup                 (uninstall both + restore stock)
#   * About
#
# Target: Qidi Q2, ARM Linux, user 'mks', running Klipper. Do NOT run
# as root - this script will refuse to.
# =====================================================================

set -uo pipefail

# ---------- repo / installer URLs ------------------------------------
REPO_BASE='https://raw.githubusercontent.com/ChanceVegas/Qidi-Q2-superuser_helpinghands/refs/heads/main/Install-Script'
BUNNYBOX_INSTALLER='https://raw.githubusercontent.com/Camden-Winder/Bunny-Box/refs/heads/main/Q2/install-bb-q2.sh'
HELIXSCREEN_INSTALLER='https://raw.githubusercontent.com/prestonbrown/helixscreen/main/scripts/install.sh'
HELIX_UNINSTALLER='https://releases.helixscreen.org/install.sh'
BUNNYBOX_UNINSTALLER='https://raw.githubusercontent.com/Camden-Winder/Bunny-Box/refs/heads/main/Q2/install-bb-q2.sh'

# ---------- paths ----------------------------------------------------
CONFIG_DIR='/home/mks/printer_data/config'
MMU_PARAMS="${CONFIG_DIR}/mmu/base/mmu_parameters.cfg"
BACKUP_ROOT='/home/mks/mudstockbackups'
HELIX_DIR='/home/mks/helixscreen'
HELIX_CONFIG_DIR="${HELIX_DIR}/config"
HAPPY_HARE_DIR='/home/mks/Happy-Hare'

# ---------- ANSI colors ----------------------------------------------
if [ -t 1 ]; then
    C_RESET=$'\033[0m'
    C_BOLD=$'\033[1m'
    C_RED=$'\033[31m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_CYAN=$'\033[36m'
    C_MAGENTA=$'\033[35m'
else
    C_RESET=''; C_BOLD=''; C_RED=''; C_GREEN=''; C_YELLOW=''; C_CYAN=''; C_MAGENTA=''
fi

ok()    { printf '%s[OK]%s   %s\n'    "$C_GREEN"  "$C_RESET" "$*"; }
info()  { printf '%s[INFO]%s %s\n'    "$C_CYAN"   "$C_RESET" "$*"; }
warn()  { printf '%s[WARN]%s %s\n'    "$C_YELLOW" "$C_RESET" "$*"; }
err()   { printf '%s[ERR]%s  %s\n'    "$C_RED"    "$C_RESET" "$*" >&2; }

banner() {
    echo ""
    printf '%s=================================================================%s\n' "$C_BOLD" "$C_RESET"
    printf '%s  %s%s\n' "$C_BOLD" "$1" "$C_RESET"
    printf '%s=================================================================%s\n' "$C_BOLD" "$C_RESET"
}

press_enter() {
    echo ""
    printf '%sPress Enter to return to the menu...%s' "$C_CYAN" "$C_RESET"
    read -r _ </dev/tty || true
}

# ---------- safety: refuse root --------------------------------------
if [ "$(id -u)" -eq 0 ]; then
    err "Do not run this script as root."
    err "Run as the printer user (usually 'mks'). It will sudo only where needed."
    exit 1
fi

# ---------- helpers --------------------------------------------------
fetch() {
    local url="$1"
    local dest="$2"
    if ! curl --fail --silent --show-error --location "$url" --output "$dest"; then
        err "Download failed: $url"
        return 1
    fi
    if [ ! -s "$dest" ]; then
        err "Downloaded file is empty: $dest"
        err "URL: $url"
        return 1
    fi
    return 0
}

bunnybox_installed() {
    [ -d "${CONFIG_DIR}/mmu" ] && [ -f "${CONFIG_DIR}/mmu/base/mmu_machine.cfg" ]
}

# Scan every path the BunnyBox installer's own detection logic looks at,
# plus a few extras. Returns 0 if any artifact is present (and prints
# what was found), 1 if the slate is truly clean.
detect_bunnybox_artifacts() {
    local found=0
    local paths=(
        "$HAPPY_HARE_DIR"
        "${CONFIG_DIR}/mmu"
        "${CONFIG_DIR}/bunnybox_macros.cfg"
        "${CONFIG_DIR}/box_drying.cfg"
        "${HOME}/klipper/klippy/extras/mmu.py"
        "${HOME}/klipper/klippy/extras/mmu_machine.py"
        "${HOME}/klipper/klippy/extras/mmu_leds.py"
        "${HOME}/moonraker/moonraker/components/mmu_server.py"
    )
    for p in "${paths[@]}"; do
        if [ -e "$p" ]; then
            warn "Stale artifact present: $p"
            found=1
        fi
    done
    return $((1 - found))
}

helixscreen_installed() {
    [ -d "$HELIX_DIR" ] || systemctl is-enabled helixscreen &>/dev/null
}

preflight() {
    banner "Pre-flight checks"

    if ! curl --fail --silent --head --max-time 10 \
         'https://raw.githubusercontent.com' >/dev/null 2>&1; then
        err "Cannot reach raw.githubusercontent.com"
        err "Check your network connection and try again."
        return 1
    fi
    ok "Network connectivity"

    if [ ! -d "$CONFIG_DIR" ]; then
        err "Config directory not found: $CONFIG_DIR"
        err "Is this a Qidi Q2 running Klipper?"
        return 1
    fi
    ok "Config directory present"

    if [ -f "${CONFIG_DIR}/printer.cfg" ]; then
        if grep -q 'enable_force_move.*True' "${CONFIG_DIR}/printer.cfg" 2>/dev/null; then
            ok "force_move enabled in printer.cfg"
        else
            warn "force_move not found in printer.cfg (spool rotation may not work)"
        fi
    fi

    ok "Pre-flight complete"
    return 0
}

do_backup() {
    banner "Backing up current configs"
    BACKUP_DIR="${BACKUP_ROOT}/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    if ! rsync -a "${CONFIG_DIR}/" "${BACKUP_DIR}/"; then
        err "Backup failed"
        return 1
    fi
    ok "Backup written to ${BACKUP_DIR}"

    # One-time permanent snapshot of the very first observed state. This
    # is what "Revert to Backup" should restore - assuming the user ran
    # the AIO before tinkering, it's their true stock. Once written, it
    # is never overwritten.
    if [ ! -d "${BACKUP_ROOT}/_FIRST_STOCK" ]; then
        mkdir -p "${BACKUP_ROOT}/_FIRST_STOCK"
        if rsync -a "${CONFIG_DIR}/" "${BACKUP_ROOT}/_FIRST_STOCK/"; then
            ok "First-run stock snapshot saved to ${BACKUP_ROOT}/_FIRST_STOCK"
        else
            warn "Could not write _FIRST_STOCK snapshot (revert will fall back to oldest timestamped backup)"
        fi
    fi
    return 0
}

# ---------- uninstall primitives -------------------------------------
uninstall_bunnybox() {
    banner "Uninstalling BunnyBox / Happy Hare"

    if [ -f "${HAPPY_HARE_DIR}/install.sh" ]; then
        info "Running Happy Hare uninstaller..."
        sudo bash "${HAPPY_HARE_DIR}/install.sh" -d || \
            warn "Happy Hare uninstaller returned non-zero"
    fi

    # Belt-and-braces: even if the uninstaller ran, force-remove the dir
    # so no trace is left.
    info "Removing leftover files..."
    rm -rf "${CONFIG_DIR}/mmu"
    sudo rm -rf "${HAPPY_HARE_DIR}"
    for f in mmu.py mmu_machine.py mmu_leds.py; do
        rm -f "${HOME}/klipper/klippy/extras/${f}"
    done
    rm -f "${HOME}/moonraker/moonraker/components/mmu_server.py"
    rm -f "${CONFIG_DIR}/bunnybox_macros.cfg"
    rm -f "${CONFIG_DIR}/box_drying.cfg"

    ok "BunnyBox / Happy Hare uninstalled (directory removed)"
    warn "printer.cfg may still reference [include mmu/base/*.cfg]"
    warn "and [include bunnybox_macros.cfg]. Klipper will error until you"
    warn "restore stock printer.cfg from backup or reinstall."
    info "Backups: ${BACKUP_ROOT}/"
}

uninstall_helixscreen() {
    banner "Uninstalling HelixScreen"

    sudo systemctl stop helixscreen 2>/dev/null || true
    sudo systemctl disable helixscreen 2>/dev/null || true
    sudo rm -f /etc/systemd/system/helixscreen.service
    sudo systemctl daemon-reload 2>/dev/null || true
    rm -rf "$HELIX_DIR"

    ok "HelixScreen uninstalled"
}

# Full upstream-style revert: re-enables lightdm + makerbase-client and
# restores from /home/mks/mudstockbackups via rsync (mirrors Camden-Winder
# uninstall.sh).
revert_to_backup() {
    banner "Revert to Backup (full stock restore)"

    info "Backing up current state to /home/mks/mudinstallbackups..."
    mkdir -p /home/mks/mudinstallbackups
    rsync -a "${CONFIG_DIR}/" /home/mks/mudinstallbackups/ && \
        ok "Pre-revert backup complete"

    if [ -d "$HELIX_DIR" ]; then
        info "HelixScreen detected - removing..."
        curl --silent --show-error --location "$HELIX_UNINSTALLER" | sudo sh -s -- --remove || \
            warn "HelixScreen uninstaller returned non-zero"

        info "Re-enabling stock Qidi screen services..."
        sudo systemctl stop helixscreen     2>/dev/null || true
        sudo systemctl disable helixscreen  2>/dev/null || true
        sudo systemctl mask helixscreen     2>/dev/null || true
        sudo systemctl enable lightdm       2>/dev/null || true
        sudo systemctl restart lightdm      2>/dev/null || true
        sudo systemctl enable makerbase-client  2>/dev/null || true
        sudo systemctl restart makerbase-client 2>/dev/null || true
        ok "Stock screen restored"
    else
        info "HelixScreen not present, skipping"
    fi

    if [ -d "/home/mks/Happy-Hare" ] || bunnybox_installed; then
        info "BunnyBox / Happy Hare detected - removing..."
        wget -qO - "$BUNNYBOX_UNINSTALLER" | bash -s -- --revert || \
            warn "BunnyBox revert returned non-zero"

        if [ -f "/home/mks/Happy-Hare/install.sh" ]; then
            sudo bash /home/mks/Happy-Hare/install.sh -d || \
                warn "Happy Hare -d returned non-zero"
        fi
        # Belt-and-braces cleanup
        rm -f "${CONFIG_DIR}/bunnybox_macros.cfg"
        rm -f "${CONFIG_DIR}/box_drying.cfg"
        ok "BunnyBox removed"
    else
        info "BunnyBox not present, skipping"
    fi

    info "Restoring configs from ${BACKUP_ROOT}..."
    local restore_ok=false
    if [ -d "$BACKUP_ROOT" ]; then
        # Prefer the one-time _FIRST_STOCK snapshot (closest to factory).
        # Fall back to the OLDEST timestamped backup - the first one
        # written is closer to stock than the newest, which captured
        # whatever broken state was on disk right before the last action.
        local src=""
        if [ -d "${BACKUP_ROOT}/_FIRST_STOCK" ] && \
           [ -n "$(ls -A "${BACKUP_ROOT}/_FIRST_STOCK" 2>/dev/null)" ]; then
            src="${BACKUP_ROOT}/_FIRST_STOCK"
            info "Using first-run stock snapshot: $src"
        else
            local oldest
            oldest=$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d \
                     -not -name '_FIRST_STOCK' 2>/dev/null | sort | head -n 1)
            if [ -n "$oldest" ]; then
                src="$oldest"
                warn "_FIRST_STOCK missing - falling back to OLDEST timestamped backup"
                info "Restoring from: $src"
            else
                src="$BACKUP_ROOT"
                warn "No timestamped backups found - restoring from flat ${BACKUP_ROOT}/"
            fi
        fi
        if rsync -a --no-owner --no-group "${src}/" "${CONFIG_DIR}/"; then
            ok "Config restore complete"
            restore_ok=true
        else
            err "Restore failed"
        fi
    else
        warn "No ${BACKUP_ROOT} folder found - nothing to restore"
    fi

    # Final cleanup: remove every directory the toolkit ever created so
    # the Q2 is left in a clean state. Only run if the restore actually
    # succeeded (or there was nothing to restore from) - we don't want
    # to nuke the only safety net after a failed restore.
    if [ "$restore_ok" = true ] || [ ! -d "$BACKUP_ROOT" ]; then
        banner "Cleaning up AIO/BunnyBox/HelixScreen directories"
        for d in "$HAPPY_HARE_DIR" "$HELIX_DIR" \
                 /home/mks/mudstockbackups /home/mks/mudinstallbackups; do
            if [ -d "$d" ]; then
                sudo rm -rf "$d" && ok "Removed $d" || warn "Could not remove $d"
            fi
        done
    else
        warn "Restore failed - leaving backup directories in place for recovery."
        info "Inspect: ${BACKUP_ROOT}/ and /home/mks/mudinstallbackups/"
    fi

    banner "Revert complete"
    info "FIRMWARE_RESTART or reboot the printer to apply."
}

# ---------- post-install verification --------------------------------
verify_bunnybox_install() {
    banner "Verifying installation"
    local all_ok=true

    for f in printer.cfg gcode_macro.cfg box_drying.cfg KAMP_Settings.cfg; do
        if [ -s "${CONFIG_DIR}/${f}" ]; then
            ok "${f}"
        else
            err "${f} missing"
            all_ok=false
        fi
    done

    if [ -f "$MMU_PARAMS" ]; then
        if grep -q '^heater_vent_macro: _QIDI_BOX_VENT' "$MMU_PARAMS" && \
           grep -q '^heater_vent_interval: 5' "$MMU_PARAMS"; then
            ok "mmu_parameters.cfg (vent macro configured)"
        else
            warn "mmu_parameters.cfg - vent macro not set correctly"
            all_ok=false
        fi
    else
        err "mmu_parameters.cfg missing"
        all_ok=false
    fi

    if [ -s "${HELIX_CONFIG_DIR}/settings.json" ]; then
        ok "helixscreen settings.json"
    else
        err "helixscreen settings.json missing"
        all_ok=false
    fi

    if [ "$all_ok" = true ]; then
        ok "All files verified"
    else
        warn "Some files are missing or misconfigured - install may not work correctly."
    fi
}

verify_jfp_install() {
    banner "Verifying installation"
    local all_ok=true
    for f in printer.cfg gcode_macro.cfg KAMP/KAMP_Settings.cfg; do
        if [ -s "${CONFIG_DIR}/${f}" ]; then
            ok "${f}"
        else
            err "${f} missing"
            all_ok=false
        fi
    done
    if [ "$all_ok" = true ]; then
        ok "All files verified"
    else
        warn "Some files are missing - install may not work correctly."
    fi
}

# ---------- install: BunnyBox & HelixScreen --------------------------
install_bunnybox_helixscreen() {
    banner "Install: BunnyBox & HelixScreen (Q2 with Qidi Box)"

    preflight || { press_enter; return 1; }
    do_backup || { press_enter; return 1; }

    # Preserve the stock Qidi box.cfg so the Qidi UI's "Control Box"
    # panel keeps working after Happy Hare strips its include.
    local BOX_CFG_PRESERVED=""
    if [ -f "${CONFIG_DIR}/box.cfg" ]; then
        BOX_CFG_PRESERVED="${BACKUP_DIR}/box.cfg.preserved"
        cp "${CONFIG_DIR}/box.cfg" "$BOX_CFG_PRESERVED"
        ok "Preserved stock box.cfg → ${BOX_CFG_PRESERVED}"
    else
        warn "No stock box.cfg found - Qidi Control Box UI will not be restored"
    fi

    local INSTALL_LOG="${BACKUP_ROOT}/install_$(date +%Y%m%d_%H%M%S).log"
    info "Install log: ${INSTALL_LOG}"

    {
        banner "Pre-install: scanning for stale BunnyBox artifacts"
        if detect_bunnybox_artifacts; then
            warn "Stale BunnyBox artifacts found (listed above)."
            warn "Their presence will make BunnyBox's installer think an"
            warn "install already exists and prompt you for Reinstall / Revert."
            if confirm "Remove all stale artifacts now for a clean install?"; then
                rm -rf "${CONFIG_DIR}/mmu"
                sudo rm -rf "$HAPPY_HARE_DIR"
                rm -f "${CONFIG_DIR}/bunnybox_macros.cfg"
                rm -f "${CONFIG_DIR}/box_drying.cfg"
                for f in mmu.py mmu_machine.py mmu_leds.py; do
                    rm -f "${HOME}/klipper/klippy/extras/${f}"
                done
                rm -f "${HOME}/moonraker/moonraker/components/mmu_server.py"
                ok "Stale artifacts removed - BunnyBox installer will run as a fresh install"
            else
                info "Leaving artifacts in place - BunnyBox will offer its own Reinstall/Revert menu"
            fi
        else
            ok "No stale artifacts - clean slate"
        fi

        banner "Installing BunnyBox (Happy Hare MMU)"
        set +e
        wget -qO - "$BUNNYBOX_INSTALLER" | bash
        local bb_exit=$?
        set -e
        if [ $bb_exit -ne 0 ]; then
            warn "BunnyBox installer exited ${bb_exit} (may be normal for reinstalls)"
        fi

        # Detect cancellation: BunnyBox exits 0 if the user picks
        # "Cancel" from its sub-menu, so an exit-code check alone
        # would silently continue. Confirm by file detection.
        if ! bunnybox_installed; then
            warn "BunnyBox did not finish installing - no mmu/base/mmu_machine.cfg on disk."
            warn "This usually means you picked 'Cancel' or 'Revert to stock' in BunnyBox's menu."
            if confirm "Abort the rest of the AIO install (recommended)?"; then
                info "Install aborted. Returning to main menu."
                exit 99  # caught after the tee pipeline below
            else
                warn "Continuing - HelixScreen will install but MMU won't work."
            fi
        else
            ok "BunnyBox install step complete"
        fi

        banner "Installing HelixScreen"
        set +e
        curl --fail --silent --show-error --location "$HELIXSCREEN_INSTALLER" | sh
        local hs_exit=$?
        set -e
        if [ $hs_exit -ne 0 ]; then
            warn "HelixScreen installer exited ${hs_exit} (may be normal for reinstalls)"
        fi
        ok "HelixScreen install step complete"

        banner "Installing unified gcode_macro.cfg & printer.cfg"
        fetch "${REPO_BASE}/gcode_macro-BunnyBox%26HelixScreen.cfg" \
              "${CONFIG_DIR}/gcode_macro.cfg" || return 1
        fetch "${REPO_BASE}/printer(BunnyBox%26HelixScreen).cfg" \
              "${CONFIG_DIR}/printer.cfg" || return 1

        # Safety net: fix the KAMP double-nesting bug if it lands.
        if grep -q '\[include \./KAMP/KAMP_Settings\.cfg\]' "${CONFIG_DIR}/printer.cfg" 2>/dev/null; then
            sed -i 's|\[include \./KAMP/KAMP_Settings\.cfg\]|[include KAMP_Settings.cfg]|' \
                "${CONFIG_DIR}/printer.cfg"
            ok "Fixed KAMP include path"
        fi

        # Restore the Qidi Control Box UI: put box.cfg back and
        # re-enable its include line in printer.cfg.
        if [ -n "$BOX_CFG_PRESERVED" ] && [ -f "$BOX_CFG_PRESERVED" ]; then
            cp "$BOX_CFG_PRESERVED" "${CONFIG_DIR}/box.cfg"
            ok "Restored stock box.cfg"
        fi
        if [ -f "${CONFIG_DIR}/box.cfg" ]; then
            if grep -q '^# *\[include box\.cfg\]' "${CONFIG_DIR}/printer.cfg" 2>/dev/null; then
                sed -i 's|^# *\[include box\.cfg\].*|[include box.cfg]  # Re-enabled by AIO for Qidi Control Box UI|' \
                    "${CONFIG_DIR}/printer.cfg"
                ok "Re-enabled [include box.cfg] for Qidi Control Box UI"
            elif ! grep -q '^\[include box\.cfg\]' "${CONFIG_DIR}/printer.cfg" 2>/dev/null; then
                # No include line at all - add one alongside box_drying.cfg
                sed -i '/^\[include box_drying\.cfg\]/i\[include box.cfg]  # Re-enabled by AIO for Qidi Control Box UI' \
                    "${CONFIG_DIR}/printer.cfg"
                ok "Added [include box.cfg] for Qidi Control Box UI"
            fi
        else
            warn "box.cfg not on disk - Qidi Control Box UI will not work"
        fi
        ok "Unified configs installed"

        banner "Installing box_drying.cfg"
        fetch "${REPO_BASE}/box_drying.cfg" "${CONFIG_DIR}/box_drying.cfg" || return 1
        ok "box_drying.cfg installed"

        banner "Configuring Happy Hare Environment Manager"
        if [ -f "$MMU_PARAMS" ]; then
            local changed=0
            if grep -q '^heater_vent_macro:' "$MMU_PARAMS"; then
                if ! grep -q '^heater_vent_macro: _QIDI_BOX_VENT' "$MMU_PARAMS"; then
                    sed -i 's/^heater_vent_macro:.*/heater_vent_macro: _QIDI_BOX_VENT/' "$MMU_PARAMS"
                    changed=1
                fi
            else
                echo "heater_vent_macro: _QIDI_BOX_VENT" >> "$MMU_PARAMS"
                changed=1
            fi
            if grep -q '^heater_vent_interval:' "$MMU_PARAMS"; then
                if ! grep -q '^heater_vent_interval: 5' "$MMU_PARAMS"; then
                    sed -i 's/^heater_vent_interval:.*/heater_vent_interval: 5/' "$MMU_PARAMS"
                    changed=1
                fi
            else
                echo "heater_vent_interval: 5" >> "$MMU_PARAMS"
                changed=1
            fi
            if [ $changed -eq 1 ]; then
                ok "mmu_parameters.cfg patched (heater_vent_macro + interval)"
            else
                ok "mmu_parameters.cfg already correct"
            fi
        else
            warn "${MMU_PARAMS} not found"
            warn "Manually set heater_vent_macro: _QIDI_BOX_VENT and heater_vent_interval: 5"
        fi

        banner "Applying KAMP settings"
        fetch "${REPO_BASE}/KAMP_settings.cfg" "${CONFIG_DIR}/KAMP_Settings.cfg" || return 1
        ok "KAMP settings applied"

        banner "Applying HelixScreen settings"
        mkdir -p "$HELIX_CONFIG_DIR"
        fetch "${REPO_BASE}/helixscreen_settings.json" \
              "${HELIX_CONFIG_DIR}/settings.json" || return 1
        ok "HelixScreen settings applied"

        verify_bunnybox_install
    } 2>&1 | tee -a "$INSTALL_LOG"

    # If the install block exited 99, the user aborted after BunnyBox
    # was cancelled. Bail before we print "Install complete".
    if [ "${PIPESTATUS[0]}" = "99" ]; then
        press_enter
        return 1
    fi

    banner "Install complete"
    cat <<EOF
${C_BOLD}Next steps:${C_RESET}
  1. FIRMWARE_RESTART (Klipper console or HelixScreen)
  2. Verify:    systemctl status klipper
  3. First-time only - calibrate MMU gear steppers:
        ${C_CYAN}MMU_CALIBRATE_GEAR GATE=0 LENGTH=100${C_RESET}
     Mark filament, measure travel, re-run with MEASURED=<mm>
  4. Start drying:
        ${C_CYAN}BOX_DRY TEMP=45 TIME=300${C_RESET}
     or auto-select from gate filament types:
        ${C_CYAN}MMU_HEATER DRY=1${C_RESET}
  5. Check status:   ${C_CYAN}BOX_DRY_STATUS${C_RESET}
  6. Stop drying:    ${C_CYAN}BOX_DRY_STOP${C_RESET}

Install log:    ${INSTALL_LOG}
Config backup:  ${BACKUP_DIR}
EOF

    press_enter
}

# ---------- install: Just Faster Printer -----------------------------
install_just_faster() {
    banner "Install: Just Faster Printer (Q2 without Box)"

    preflight || { press_enter; return 1; }
    do_backup || { press_enter; return 1; }

    info "Updating gcode_macro.cfg..."
    fetch "${REPO_BASE}/gcode_macro(JustFasterPrinter).cfg" \
          "${CONFIG_DIR}/gcode_macro.cfg" || { press_enter; return 1; }
    ok "gcode_macro.cfg installed"

    info "Updating printer.cfg..."
    fetch "${REPO_BASE}/JustFasterPrinter.cfg" \
          "${CONFIG_DIR}/printer.cfg" || { press_enter; return 1; }
    ok "printer.cfg installed"

    info "Applying KAMP settings (KAMP subdir layout)..."
    mkdir -p "${CONFIG_DIR}/KAMP"
    fetch "${REPO_BASE}/KAMP_settings.cfg" \
          "${CONFIG_DIR}/KAMP/KAMP_Settings.cfg" || { press_enter; return 1; }
    ok "KAMP settings applied"

    verify_jfp_install

    banner "Install complete"
    cat <<EOF
${C_BOLD}Your Q2 is now running the 'Just Faster' setup.${C_RESET}
  No Bunny Box, no HelixScreen - just cleaner macros and faster starts.

${C_BOLD}Next steps:${C_RESET}
  1. FIRMWARE_RESTART (Klipper console or stock screen)
  2. Run a bed level + screws_tilt_adjust before your first print.

Config backup:  ${BACKUP_DIR}
EOF

    press_enter
}

# ---------- about ----------------------------------------------------
show_about() {
    banner "About - Qidi Q2 Superuser AIO"
    cat <<EOF
${C_CYAN}Qidi Q2 Superuser - All-in-One Installer${C_RESET}

A community-built toolkit to unlock advanced features on the Qidi Q2
3D printer beyond stock Qidi firmware. This menu is the single entry
point for every supported install / uninstall path.

${C_BOLD}What it can install:${C_RESET}

  ${C_GREEN}BunnyBox & HelixScreen${C_RESET}  (Q2 ${C_BOLD}with${C_RESET} the Qidi Box)
    - Happy Hare MMU firmware/macros for multi-material printing
    - HelixScreen replacement touchscreen UI
    - Unified printer.cfg + gcode_macro.cfg
    - box_drying.cfg: spool rotation during filament drying using
      Happy Hare's Environment Manager, with humidity-based early
      termination via the AHT2X sensor
    - Patches mmu_parameters.cfg (heater_vent_macro + interval)
    - KAMP adaptive bed meshing

  ${C_GREEN}Just Faster Printer${C_RESET}    (Q2 ${C_BOLD}without${C_RESET} the Box, stock screen)
    - Faster, cleaner PRINT_START / PRINT_END macros
    - KAMP adaptive meshing, screws_tilt_adjust, Spoolman hooks
    - No UI changes - stock Qidi screen stays

${C_BOLD}What it can uninstall:${C_RESET}
  - BunnyBox only / HelixScreen only / Both
  - 'Revert to Backup' performs a full upstream-style restore:
    re-enables lightdm + makerbase-client, then rsyncs the newest
    timestamped backup from ${BACKUP_ROOT}/ back into place.

${C_BOLD}Safety:${C_RESET}
  Every install and uninstall first writes a timestamped backup of
  ${CONFIG_DIR}/ to ${BACKUP_ROOT}/<timestamp>/.
  Refuses to run as root.

${C_BOLD}Known limitations:${C_RESET}
  - HelixScreen has ${C_YELLOW}no native UI panel${C_RESET} for Happy Hare's dryer yet.
    Use the BOX_DRY macro (or Klipper console) as a workaround.
  - ${C_YELLOW}MMU_CALIBRATE_GEAR${C_RESET} is required after clean installs.
  - BunnyBox currently requires HelixScreen for MMU workflows; the
    stock Qidi screen does not yet expose the MMU UI.

${C_BOLD}Repo:${C_RESET}     ChanceVegas/Qidi-Q2-superuser_helpinghands
${C_BOLD}Upstream:${C_RESET} Camden-Winder/Qidi-Q2-superuser (uninstall lineage)
EOF
    press_enter
}

# ---------- main menu ------------------------------------------------
show_status_line() {
    local bb_status hs_status
    if bunnybox_installed; then
        bb_status="${C_GREEN}installed${C_RESET}"
    else
        bb_status="${C_YELLOW}not found${C_RESET}"
    fi
    if helixscreen_installed; then
        hs_status="${C_GREEN}installed${C_RESET}"
    else
        hs_status="${C_YELLOW}not found${C_RESET}"
    fi
    printf '  BunnyBox: %b   |   HelixScreen: %b\n' "$bb_status" "$hs_status"
}

draw_menu() {
    clear 2>/dev/null || true
    printf '%s============================================%s\n' "$C_BOLD$C_MAGENTA" "$C_RESET"
    printf '%s   Qidi Q2 Superuser - AIO Setup Menu%s\n'        "$C_BOLD$C_MAGENTA" "$C_RESET"
    printf '%s============================================%s\n' "$C_BOLD$C_MAGENTA" "$C_RESET"
    show_status_line
    printf '%s--------------------------------------------%s\n' "$C_BOLD" "$C_RESET"
    printf '  %sINSTALL%s\n' "$C_BOLD$C_GREEN" "$C_RESET"
    printf '   %s1)%s Install BunnyBox & HelixScreen   (Q2 with Qidi Box)\n'    "$C_CYAN" "$C_RESET"
    printf '   %s2)%s Install Just Faster Printer      (Q2 without Box)\n'      "$C_CYAN" "$C_RESET"
    printf '  %sUNINSTALL%s\n' "$C_BOLD$C_YELLOW" "$C_RESET"
    printf '   %s3)%s Uninstall BunnyBox only\n'                                 "$C_CYAN" "$C_RESET"
    printf '   %s4)%s Uninstall HelixScreen only\n'                              "$C_CYAN" "$C_RESET"
    printf '   %s5)%s Uninstall Both\n'                                          "$C_CYAN" "$C_RESET"
    printf '   %s6)%s Revert to Backup                 (uninstall both + restore)\n' "$C_CYAN" "$C_RESET"
    printf '  %sINFO%s\n' "$C_BOLD$C_CYAN" "$C_RESET"
    printf '   %s7)%s About\n'                                                   "$C_CYAN" "$C_RESET"
    printf '   %s0)%s Exit\n'                                                    "$C_CYAN" "$C_RESET"
    printf '%s============================================%s\n' "$C_BOLD$C_MAGENTA" "$C_RESET"
    printf '%sEnter selection:%s ' "$C_BOLD" "$C_RESET"
}

confirm() {
    local prompt="$1"
    local ans
    printf '%s%s [y/N]:%s ' "$C_YELLOW" "$prompt" "$C_RESET"
    read -r ans </dev/tty || return 1
    case "$ans" in
        y|Y|yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}

main_loop() {
    while true; do
        draw_menu
        local choice
        read -r choice </dev/tty || exit 0
        case "$choice" in
            1) install_bunnybox_helixscreen ;;
            2) install_just_faster ;;
            3)
                if confirm "Uninstall BunnyBox only?"; then
                    do_backup && uninstall_bunnybox
                    press_enter
                fi
                ;;
            4)
                if confirm "Uninstall HelixScreen only?"; then
                    do_backup && uninstall_helixscreen
                    press_enter
                fi
                ;;
            5)
                if confirm "Uninstall BOTH BunnyBox and HelixScreen?"; then
                    do_backup
                    if bunnybox_installed;    then uninstall_bunnybox;    fi
                    if helixscreen_installed; then uninstall_helixscreen; fi
                    press_enter
                fi
                ;;
            6)
                warn "Revert to Backup will uninstall BunnyBox + HelixScreen"
                warn "and restore configs from ${BACKUP_ROOT}/."
                if confirm "Proceed with full revert?"; then
                    revert_to_backup
                    press_enter
                fi
                ;;
            7) show_about ;;
            0|q|Q|exit) info "Bye."; exit 0 ;;
            *) err "Invalid selection: '$choice'"; sleep 1 ;;
        esac
    done
}

main_loop
