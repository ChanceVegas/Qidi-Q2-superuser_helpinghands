# KlipperScreen Display Investigation

## Goal

Re-enable AIO menu option 2 so it installs KlipperScreen Happy Hare Edition on the Qidi Q2 Pro and renders correctly on the physical display.

Upstream install path:

```bash
git clone https://github.com/moggieuk/KlipperScreen-Happy-Hare-Edition ~/KlipperScreen
cd ~/KlipperScreen && ./scripts/KlipperScreen-install.sh
cd ~/KlipperScreen/happy_hare && ./install_ks.sh -g 4
```

## Current AIO State

Current version:

```bash
AIO_VERSION='RC1.30'
```

`install_klipperscreen()` currently:

1. Clones `moggieuk/KlipperScreen-Happy-Hare-Edition` to `/home/mks/KlipperScreen`.
2. Strips `xserver-xorg-legacy` from the installer because it is unavailable on Debian Bullseye ARM.
3. Runs `NETWORK=N bash KlipperScreen-install.sh`.
4. Runs `/home/mks/KlipperScreen/happy_hare/install_ks.sh -g 4`.
5. Writes a systemd drop-in clearing `ConditionPathExists=/dev/tty0` and creating `/dev/tty0` if absent.
6. Calls `prepare_display_for_klipperscreen()`, which masks `makerbase-client` and `helixscreen`.

The menu disables option 2 until the display issue is solved.

## Observed Symptoms

- `systemctl status KlipperScreen` shows active/running, with PID owned by `xinit`.
- `ps aux` shows `[Xorg] <defunct>`.
- The Qidi boot splash stays frozen on the physical display.
- KlipperScreen never renders.
- Xorg log fatal error:

```text
(EE) parse_vt_settings: Cannot open /dev/tty0 (No such file or directory)
```

Creating `/dev/tty0` with `mknod` is not enough because the kernel lacks VT state behind it.

## Root Cause Working Theory

The Q2 kernel has no real VT subsystem:

- `/dev/tty0` does not exist at boot.
- `logind` reports the seat has no VTs.
- The active serial console is `ttyFIQ0`.
- Upstream KlipperScreen starts Xorg through `xinit`, which takes a VT-dependent path.
- Bare `/dev/tty0` creation may satisfy a path check but cannot make VT ioctls work.

The stock display path works through `lightdm`, which appears to launch Xorg with explicit VT handling and a different startup path.

## Approaches Tried

| Version | Approach | Result |
|---|---|---|
| RC1.23-RC1.25 | Connect KlipperScreen as X client to lightdm `:0` | Abandoned because upstream installer disables lightdm and switches target |
| RC1.28 | Clear `ConditionPathExists=/dev/tty0` | Service starts but Xorg still crashes |
| RC1.29 | Create `/dev/tty0` before service start | Xorg starts briefly but still cannot use VT ioctls |
| RC1.30 | Disable menu option 2 | Prevents users from hitting broken display path |

## Promising Paths

### Option A: Cage / Wayland

Use Cage as a DRM/KMS kiosk compositor. This avoids Xorg and VTs.

Questions:

- Is `cage` installed?
- Can it be installed on the printer without breaking stock packages?
- Does it render to `/dev/dri/card0` on the Q2 display?

Potential implementation:

```bash
cat >/home/mks/KlipperScreen/scripts/launch_KlipperScreen.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
SCRIPTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPTPATH/KlipperScreen-env.sh"
exec /usr/bin/cage -ds "$KS_XCLIENT"
EOF
chmod +x /home/mks/KlipperScreen/scripts/launch_KlipperScreen.sh
```

Use the script's existing launch override hook rather than patching upstream files heavily.

### Option B: Xorg with Explicit Options

Try bypassing VT auto-detection from the launch override:

```bash
exec /usr/bin/xinit "$KS_XCLIENT" -- :0 -keeptty -novtswitch -nolisten tcp
```

Questions:

- Does `-keeptty` avoid the failing VT path on this build?
- Does Xorg still require a controlling tty or root privileges?
- Does modesetting claim the correct Rockchip DRM device?

### Option C: Keep or Restore lightdm

Let lightdm own the X server and launch KlipperScreen as a client on `:0`.

Potential launch logic:

```bash
export DISPLAY=:0
xhost +local:
exec "$KS_XCLIENT"
```

Questions:

- Can upstream `KlipperScreen-install.sh` be run without permanently disabling lightdm?
- If not, can AIO restore `graphical.target` and lightdm after install?
- Which stock service owns the boot splash and needs masking: `makerbase-client`, `helixscreen`, or both?

### Option D: Weston

Try Weston as another DRM/KMS compositor if Cage is unavailable.

Questions:

- Is `weston` available or installable?
- Does it work without VTs on this kernel?

## Printer Diagnostics Checklist

Run as `mks`:

```bash
which cage || true
which weston || true
ls -la /dev/dri/
ls /dev/tty[0-9]* 2>/dev/null || true
loginctl seat-status seat0 || true
systemctl get-default
systemctl status lightdm --no-pager
systemctl status makerbase-client --no-pager
systemctl status helixscreen --no-pager
systemctl status KlipperScreen --no-pager
journalctl -u KlipperScreen -b --no-pager | tail -120
```

If Xorg has been attempted:

```bash
find /var/log -maxdepth 2 -iname 'Xorg*.log' -print
sed -n '1,220p' /var/log/Xorg.0.log 2>/dev/null || true
```

If KlipperScreen exists:

```bash
ls -la /home/mks/KlipperScreen/scripts/
sed -n '1,220p' /home/mks/KlipperScreen/scripts/KlipperScreen-start.sh
```

## Acceptance Criteria

Option 2 can be re-enabled only when:

1. Fresh option 2 install completes without service failure.
2. KlipperScreen renders on the physical Q2 display.
3. The Qidi splash is cleared or fully covered by the working UI.
4. Reboot returns to the intended display mode.
5. Revert to Backup restores stock display behavior.
6. `bash -n All_in_One_Installer/aio_menu.sh` passes.
7. `AIO_VERSION` is bumped from `RC1.30`.
