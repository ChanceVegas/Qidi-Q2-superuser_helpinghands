#!/usr/bin/env bash
# Check the newest HelixScreen release against the pinned Happier Hare patch.
#
# Exit codes:
#   0  Pin is current, or the selected tag matches the pin and applies cleanly.
#   10 A newer release exists and the patch applies cleanly.
#   20 A newer release exists but needs manual attention.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
AIO_SCRIPT="${ROOT_DIR}/All_in_One_Installer/aio_menu.sh"
PATCH_FILE="${SCRIPT_DIR}/patches/helixscreen-happier-hare.patch"
HELIXSCREEN_REPO="${HELIXSCREEN_REPO:-https://github.com/prestonbrown/helixscreen.git}"
HELIXSCREEN_API="${HELIXSCREEN_API:-https://api.github.com/repos/prestonbrown/helixscreen/releases/latest}"
WORK_ROOT="${HAPPIER_HARE_CHECK_ROOT:-${TMPDIR:-/tmp}}"
CHECK_FORCE="${HELIXSCREEN_CHECK_FORCE:-0}"
CHECK_WORK_DIR=''

info() { printf '[INFO] %s\n' "$*"; }
ok() { printf '[OK]   %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
err() { printf '[ERR]  %s\n' "$*" >&2; }

cleanup() {
    [ -z "$CHECK_WORK_DIR" ] || rm -rf "$CHECK_WORK_DIR"
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        err "Missing required command: $1"
        return 1
    }
}

read_pin() {
    sed -n "s/^HELIXSCREEN_PIN='\\([^']*\\)'$/\\1/p" "$AIO_SCRIPT" | head -n 1
}

read_latest_tag() {
    curl --fail --silent --show-error --location "$HELIXSCREEN_API" |
        python3 -c 'import json, sys; print(json.load(sys.stdin)["tag_name"])'
}

main() {
    require_cmd curl
    require_cmd git
    require_cmd patch
    require_cmd python3

    local pinned_tag target_tag archive_url work_dir status
    pinned_tag="$(read_pin)"
    [ -n "$pinned_tag" ] || {
        err "Could not read HELIXSCREEN_PIN from ${AIO_SCRIPT}"
        return 20
    }

    target_tag="${HELIXSCREEN_TAG:-}"
    if [ -z "$target_tag" ]; then
        info "Querying the latest official HelixScreen release"
        target_tag="$(read_latest_tag)"
    fi

    printf 'PINNED_TAG=%s\n' "$pinned_tag"
    printf 'LATEST_TAG=%s\n' "$target_tag"

    if [ "$target_tag" = "$pinned_tag" ] && [ "$CHECK_FORCE" != '1' ]; then
        printf 'PATCH_STATUS=not-needed\n'
        ok "HelixScreen pin is current: ${pinned_tag}"
        return 0
    fi

    archive_url="https://github.com/prestonbrown/helixscreen/releases/download/${target_tag}/helixscreen-pi.zip"
    info "Checking official Pi archive: ${archive_url}"
    if ! curl --fail --silent --show-error --location --head --output /dev/null "$archive_url"; then
        printf 'PATCH_STATUS=missing-pi-archive\n'
        err "Official ${target_tag} Pi archive is not available"
        return 20
    fi

    work_dir="$(mktemp -d "${WORK_ROOT%/}/happier-hare-check.XXXXXX")"
    CHECK_WORK_DIR="$work_dir"
    trap cleanup EXIT

    info "Cloning HelixScreen ${target_tag}"
    if ! git clone --quiet --branch "$target_tag" --depth 1 "$HELIXSCREEN_REPO" "${work_dir}/helixscreen"; then
        printf 'PATCH_STATUS=clone-failed\n'
        err "Could not clone HelixScreen ${target_tag}"
        return 20
    fi

    info "Dry-running the Happier Hare patch set"
    status=0
    patch --dry-run -d "${work_dir}/helixscreen" -p1 --forward < "$PATCH_FILE" >/dev/null || status=$?
    if [ "$status" -ne 0 ]; then
        printf 'PATCH_STATUS=manual-rebase-required\n'
        warn "Happier Hare patch does not apply cleanly to ${target_tag}"
        return 20
    fi

    printf 'PATCH_STATUS=clean\n'
    ok "Happier Hare patch applies cleanly to ${target_tag}"
    if [ "$target_tag" = "$pinned_tag" ]; then
        return 0
    fi
    return 10
}

main "$@"
