#!/usr/bin/env bash
# Install XRDP + KDE Plasma (X11) on Debian/Ubuntu.
# Run as your login user. XRDP_LAN_IP enables LAN access; off disables it.
# KDE_RDP_PORT changes the RDP port (default: 3389).
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../lib/xrdp.sh
. "$SCRIPT_DIR/../lib/xrdp.sh"

# XRDP, Firefox, VLC, fonts, and archive tools are shared by both desktops.
PACKAGES=(
  plasma-desktop plasma-workspace kwin-x11 systemsettings polkit-kde-agent-1
  dolphin konsole kate ark gwenview kde-spectacle kcalc plasma-systemmonitor okular
  x11-utils libgl1-mesa-dri
)

prepare_xrdp kde "${KDE_RDP_PORT:-3389}"
install_xrdp "${PACKAGES[@]}"
command -v startplasma-x11 >/dev/null 2>&1 || die "The KDE Plasma (X11) launcher (startplasma-x11) is missing."

write_xrdp_session <<'SESSION'
#!/bin/sh
unset SESSION_MANAGER DBUS_SESSION_BUS_ADDRESS WAYLAND_DISPLAY
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=KDE
export XDG_SESSION_DESKTOP=KDE
export DESKTOP_SESSION=plasma
export QT_QPA_PLATFORM=xcb
exec dbus-run-session -- startplasma-x11
SESSION

disable_native_krdp
configure_xrdp
start_xrdp
print_xrdp_summary "KDE Plasma (X11)"
