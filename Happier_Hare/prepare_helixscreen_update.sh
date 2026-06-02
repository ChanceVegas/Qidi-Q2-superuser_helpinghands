#!/usr/bin/env bash
# Prepare a guarded HelixScreen pin update and build the patched Pi archive.
#
# This intentionally stops before commit, push, or release publication.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CHECK_SCRIPT="${SCRIPT_DIR}/check_helixscreen_update.sh"
BUILD_SCRIPT="${SCRIPT_DIR}/build_patched_helixscreen_zip_docker.sh"

info() { printf '[INFO] %s\n' "$*"; }
ok() { printf '[OK]   %s\n' "$*"; }
err() { printf '[ERR]  %s\n' "$*" >&2; }

usage() {
    cat <<'EOF'
Usage:
  ./Happier_Hare/prepare_helixscreen_update.sh <helix-tag> <aio-version>

Example:
  ./Happier_Hare/prepare_helixscreen_update.sh v0.99.72 RC2.18
EOF
}

main() {
    local target_tag="${1:-}" next_rc="${2:-}" release_tag check_status

    if ! [[ "$target_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
       ! [[ "$next_rc" =~ ^RC[0-9]+\.[0-9]+$ ]]; then
        usage
        return 2
    fi

    release_tag="happier-hare-${next_rc,,}"

    info "Checking whether the existing patch applies to ${target_tag}"
    check_status=0
    HELIXSCREEN_TAG="$target_tag" HELIXSCREEN_CHECK_FORCE=1 "$CHECK_SCRIPT" || check_status=$?
    if [ "$check_status" -ne 0 ] && [ "$check_status" -ne 10 ]; then
        err "Compatibility check failed. Rebase the source patch before changing pins."
        return "$check_status"
    fi

    info "Updating the HelixScreen pin and release labels"
    TARGET_TAG="$target_tag" NEXT_RC="$next_rc" RELEASE_TAG="$release_tag" ROOT_DIR="$ROOT_DIR" python3 <<'PY'
import os
import re
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
tag = os.environ["TARGET_TAG"]
rc = os.environ["NEXT_RC"]
release = os.environ["RELEASE_TAG"]

def update(path, transforms):
    file_path = root / path
    text = file_path.read_text()
    for pattern, replacement in transforms:
        text, count = re.subn(pattern, replacement, text, count=1, flags=re.MULTILINE)
        if count != 1:
            raise SystemExit(f"Expected one match for {pattern!r} in {path}, found {count}")
    file_path.write_text(text)

update("All_in_One_Installer/aio_menu.sh", [
    (r"^AIO_VERSION='[^']+'$", f"AIO_VERSION='{rc}'"),
    (r"^HELIXSCREEN_PIN='[^']+'$", f"HELIXSCREEN_PIN='{tag}'"),
    (r'^HAPPIER_HARE_RELEASE_TAG="\$\{HAPPIER_HARE_RELEASE_TAG:-[^}]+\}"$',
     f'HAPPIER_HARE_RELEASE_TAG="${{HAPPIER_HARE_RELEASE_TAG:-{release}}}"'),
])
update("Happier_Hare/install_happier_hare.sh", [
    (r"^HAPPIER_HARE_VERSION='[^']+'$", f"HAPPIER_HARE_VERSION='{rc}'"),
    (r"^HELIXSCREEN_PIN='[^']+'$", f"HELIXSCREEN_PIN='{tag}'"),
])
update("Happier_Hare/build_patched_helixscreen_zip_docker.sh", [
    (r"^HAPPIER_HARE_VERSION='[^']+'$", f"HAPPIER_HARE_VERSION='{rc}'"),
    (r'^HELIXSCREEN_PIN="\$\{HELIXSCREEN_PIN:-[^}]+\}"$',
     f'HELIXSCREEN_PIN="${{HELIXSCREEN_PIN:-{tag}}}"'),
])
update(".github/workflows/build-happier-hare.yml", [
    (r"(description: HelixScreen tag to patch\n\s+default:) \S+", rf"\1 {tag}"),
    (r"(description: Artifact version label\n\s+default:) \S+", rf"\1 {release}"),
])

readme = root / "All_in_One_Installer/README.md"
text = readme.read_text()
row = (
    f"| {rc} | Updates the validated HelixScreen pin to `{tag}` and refreshes "
    f"the Happier Hare patched archive target `{release}` |\n"
)
if f"| {rc} |" not in text:
    marker = "|---------|------------------|\n"
    if marker not in text:
        raise SystemExit("Could not find release-history table in All_in_One_Installer/README.md")
    text = text.replace(marker, marker + row, 1)
    readme.write_text(text)
PY

    info "Running shell validation"
    bash -n "${ROOT_DIR}/All_in_One_Installer/aio_menu.sh"
    bash -n "${ROOT_DIR}/Happier_Hare/install_happier_hare.sh"
    bash -n "${ROOT_DIR}/Happier_Hare/build_patched_helixscreen_zip_docker.sh"
    bash -n "${ROOT_DIR}/Happier_Hare/check_helixscreen_update.sh"
    bash -n "${ROOT_DIR}/Happier_Hare/prepare_helixscreen_update.sh"
    shellcheck -S warning \
        "${ROOT_DIR}/All_in_One_Installer/aio_menu.sh" \
        "${ROOT_DIR}/Happier_Hare/install_happier_hare.sh" \
        "${ROOT_DIR}/Happier_Hare/build_patched_helixscreen_zip_docker.sh" \
        "${ROOT_DIR}/Happier_Hare/check_helixscreen_update.sh" \
        "${ROOT_DIR}/Happier_Hare/prepare_helixscreen_update.sh"
    ok "Shell validation passed"

    info "Building the patched Pi archive locally"
    HELIXSCREEN_PIN="$target_tag" "$BUILD_SCRIPT"

    cat <<EOF

[OK] Prepared ${next_rc} for HelixScreen ${target_tag}.
[INFO] Review the diff and local archive, then commit on a claude/* branch.
[INFO] Publish Happier_Hare/dist/helixscreen-pi.zip as:
       ${release_tag}/helixscreen-pi.zip
EOF
}

main "$@"
