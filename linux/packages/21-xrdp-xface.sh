#!/usr/bin/env bash
# Install XRDP + XFCE (X11) on Debian/Ubuntu.
# Run as your login user. XRDP_LAN_IP enables LAN access; off disables it.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../lib/xrdp.sh
. "$SCRIPT_DIR/../lib/xrdp.sh"

# XRDP, Firefox, VLC, fonts, and archive tools are shared by both desktops.
PACKAGES=(
  xfce4 xfce4-goodies xfce4-terminal
  thunar thunar-archive-plugin thunar-volman mousepad ristretto file-roller
  xfce4-screenshooter xfce4-taskmanager galculator atril
)

prepare_xrdp xfce 3389
install_xrdp "${PACKAGES[@]}"
command -v startxfce4 >/dev/null 2>&1 || die "The XFCE (X11) launcher (startxfce4) is missing."

write_xrdp_session <<'SESSION'
#!/bin/sh
unset SESSION_MANAGER DBUS_SESSION_BUS_ADDRESS WAYLAND_DISPLAY
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=XFCE
export DESKTOP_SESSION=xfce
exec dbus-run-session -- startxfce4
SESSION

configure_xrdp
start_xrdp
print_xrdp_summary "XFCE (X11)"
