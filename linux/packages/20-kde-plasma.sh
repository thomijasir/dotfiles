#!/usr/bin/env bash
# Install KDE Plasma with native KRdp screen sharing on Debian/Ubuntu.
# Requires a distribution with Plasma 6 and the krdp package.
# Sharing starts in the user's Plasma Wayland session, over Tailscale only.
# KDE_RDP_PORT optionally selects a port; otherwise keep KDE's saved port.

set -euo pipefail

info() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\n\033[1;33mWarning: %s\033[0m\n' "$*" >&2; }
die() { printf '\n\033[1;31mError: %s\033[0m\n' "$*" >&2; exit 1; }

[ -r /etc/os-release ] || die "This installer requires Debian or Ubuntu Linux."
# shellcheck source=/dev/null
. /etc/os-release
case "${ID:-}" in
  debian|ubuntu) ;;
  *) die "This installer supports Debian and Ubuntu only." ;;
esac
[ -d /run/systemd/system ] || die "This installer requires a running systemd system."

if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
  TARGET_USER="${SUDO_USER:-}"
else
  command -v sudo >/dev/null 2>&1 || die "sudo is required."
  SUDO="sudo"
  $SUDO -n true 2>/dev/null || $SUDO -v
  TARGET_USER="$(id -un)"
fi
[ -n "$TARGET_USER" ] && [ "$TARGET_USER" != root ] ||
  die "Run as your normal login user, or use sudo from that account. Screen sharing will not be configured for root."
id "$TARGET_USER" >/dev/null 2>&1 || die "Target user '$TARGET_USER' does not exist."
TARGET_UID="$(id -u "$TARGET_USER")"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
[ -n "$TARGET_HOME" ] && [ -d "$TARGET_HOME" ] || die "Could not find the home directory for '$TARGET_USER'."
for tool in tailscale ip ss runuser; do
  command -v "$tool" >/dev/null 2>&1 || die "Required command '$tool' is missing. Install Tailscale and iproute2 first."
done
as_user() {
  $SUDO runuser -u "$TARGET_USER" -- env XDG_CONFIG_HOME="$TARGET_HOME/.config" \
    XDG_RUNTIME_DIR="/run/user/$TARGET_UID" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$TARGET_UID/bus" "$@"
}
user_service() {
  as_user env XDG_RUNTIME_DIR="/run/user/$TARGET_UID" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$TARGET_UID/bus" systemctl --user "$@"
}

info "Checking Tailscale"
$SUDO tailscale status >/dev/null 2>&1 || die "Run 'sudo tailscale up' before running this installer."
TS_IP="$($SUDO tailscale ip -4)"
[[ "$TS_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || die "Could not determine a single Tailscale IPv4 address."
ip -o -4 addr show dev tailscale0 | awk -v address="$TS_IP" '
  { split($4, parts, "/"); if (parts[1] == address) found = 1 }
  END { exit !found }
' || die "Tailscale address '$TS_IP' is not assigned to tailscale0."
if [ -n "${KDE_RDP_PORT:-}" ]; then
  [[ "$KDE_RDP_PORT" =~ ^[1-9][0-9]{0,4}$ ]] && [ "$KDE_RDP_PORT" -le 65535 ] ||
    die "KDE_RDP_PORT must be a port number from 1 to 65535."
fi

GRAPHICS_DEVICE=false
for device in /dev/dri/renderD* /dev/dri/card*; do
  if [ -c "$device" ]; then
    GRAPHICS_DEVICE=true
    break
  fi
done
if [ "$GRAPHICS_DEVICE" = false ]; then
  warn "No DRM graphics device was found. Native screen sharing needs a working OpenGL Plasma Wayland session; installing packages alone will not provide it."
fi

info "Checking Plasma and native RDP packages"
$SUDO apt-get update
PACKAGES=(
  plasma-desktop plasma-workspace kwin-wayland systemsettings sddm krdp
  pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-kde kwallet6
  dbus-user-session libpam-systemd openssl libegl-mesa0 libgl1-mesa-dri
  dolphin konsole kate ark gwenview kde-spectacle kcalc plasma-systemmonitor
  fonts-dejavu fonts-liberation
)
for package in "${PACKAGES[@]}"; do
  candidate="$(LC_ALL=C apt-cache policy "$package" | awk '/Candidate:/ { print $2 }')"
  [ -n "$candidate" ] && [ "$candidate" != "(none)" ] ||
    die "Package '$package' has no installation candidate. Native RDP requires Plasma 6 with KRdp, for example Debian 13 or Ubuntu 26.04. No packages have been installed."
done
$SUDO apt-get -s install --no-install-recommends "${PACKAGES[@]}" >/dev/null
# Debian may enable KRdp globally during installation. Apply the listener
# restriction first so newly started user services inherit it as well.
GLOBAL_DROPIN=/etc/systemd/user/app-org.kde.krdpserver.service.d/10-tailscale.conf
$SUDO install -d -m 755 "$(dirname "$GLOBAL_DROPIN")"
[ ! -L "$GLOBAL_DROPIN" ] || die "Refusing to overwrite a symlink: $GLOBAL_DROPIN"
if $SUDO test -f "$GLOBAL_DROPIN"; then
  $SUDO cp -p --no-clobber "$GLOBAL_DROPIN" "$GLOBAL_DROPIN.before-dotfiles"
fi
printf '[Service]\nExecStart=\nExecStart=/usr/bin/krdpserver --address %s\n' "$TS_IP" |
  $SUDO tee "$GLOBAL_DROPIN" >/dev/null
$SUDO chmod 644 "$GLOBAL_DROPIN"
$SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${PACKAGES[@]}"
for tool in startplasma-wayland krdpserver kwriteconfig6 kreadconfig6; do
  command -v "$tool" >/dev/null 2>&1 || die "Expected Plasma command '$tool' was not installed."
done

SERVICE=app-org.kde.krdpserver.service
RDP_PORT="${KDE_RDP_PORT:-$(as_user kreadconfig6 --file krdpserverrc --group General --key ListenPort --default 3389)}"
[[ "$RDP_PORT" =~ ^[1-9][0-9]{0,4}$ ]] && [ "$RDP_PORT" -le 65535 ] || die "KDE's saved RDP port is invalid."
# An existing native server for this user may own the port during a rerun.
if [ -n "$(ss -H -ltn "sport = :$RDP_PORT")" ] && ! user_service is-active --quiet "$SERVICE" 2>/dev/null; then
  die "Port $RDP_PORT is already in use. Stop the other RDP server or rerun with KDE_RDP_PORT set to a free port."
fi
KRDP_WAS_ACTIVE=false
if user_service is-active --quiet "$SERVICE" 2>/dev/null; then
  KRDP_WAS_ACTIVE=true
  user_service stop "$SERVICE"
fi

info "Configuring native screen sharing for '$TARGET_USER'"
# All home-directory writes run as the target user, including config tools.
# shellcheck disable=SC2016
as_user sh -c '
  set -eu
  umask 077
  config="$HOME/.config/krdpserverrc"
  dropin="$HOME/.config/systemd/user/app-org.kde.krdpserver.service.d/tailscale.conf"
  data="$HOME/.local/share/krdpserver"
  mkdir -p "$(dirname "$config")" "$(dirname "$dropin")" "$data"
  for path in "$config" "$dropin" "$data/krdp.crt" "$data/krdp.key"; do
    [ ! -L "$path" ] || { printf "Refusing symlink: %s\n" "$path" >&2; exit 1; }
    [ ! -e "$path" ] || [ -f "$path" ] || exit 1
  done
  for path in "$config" "$dropin"; do
    if [ -f "$path" ] && [ ! -e "$path.before-dotfiles" ]; then
      cp --no-clobber --preserve=mode,timestamps -- "$path" "$path.before-dotfiles"
    fi
  done
  certificate="$(kreadconfig6 --file krdpserverrc --group General --key Certificate)"
  key="$(kreadconfig6 --file krdpserverrc --group General --key CertificateKey)"
  if [ -z "$certificate" ] && [ -z "$key" ]; then
    certificate="$data/krdp.crt"
    key="$data/krdp.key"
    if [ ! -e "$certificate" ] && [ ! -e "$key" ]; then
      openssl req -x509 -newkey rsa:3072 -sha256 -nodes -days 365 \
        -subj "/CN=KDE Remote Desktop" -keyout "$key" -out "$certificate" 2>/dev/null
    fi
    kwriteconfig6 --file krdpserverrc --group General --key Certificate "$certificate"
    kwriteconfig6 --file krdpserverrc --group General --key CertificateKey "$key"
  fi
  [ -r "$certificate" ] && [ -r "$key" ] || {
    printf "The configured KRdp certificate or key is missing or unreadable.\n" >&2
    exit 1
  }
  openssl x509 -in "$certificate" -noout -checkend 0 >/dev/null
  kwriteconfig6 --file krdpserverrc --group General --key ListenPort "$2"
  kwriteconfig6 --file krdpserverrc --group General --key Autostart true
  printf "[Service]\nExecStart=\nExecStart=/usr/bin/krdpserver --address %s\nRestart=on-failure\nRestartSec=5s\n" "$1" > "$dropin"
  SYSTEMD_OFFLINE=1 systemctl --user --no-reload enable app-org.kde.krdpserver.service
' sh "$TS_IP" "$RDP_PORT"

if command -v ufw >/dev/null 2>&1 && $SUDO env LC_ALL=C ufw status | grep -q '^Status: active'; then
  $SUDO ufw allow in on tailscale0 to any port "$RDP_PORT" proto tcp
fi
# Reload an existing user manager; otherwise systemd loads the unit at login.
if [ -S "/run/user/$TARGET_UID/bus" ]; then
  user_service daemon-reload
  if [ "$KRDP_WAS_ACTIVE" = true ]; then
    user_service restart "$SERVICE"
    user_service is-active --quiet "$SERVICE" || die "The native RDP service did not restart."
  fi
fi

info "KDE Plasma installed; native RDP enabled at Plasma login"
printf 'Host: %s\nPort: %s\nUser: %s\n' "$TS_IP" "$RDP_PORT" "$TARGET_USER"
cat <<'NEXT'

Log in to a Plasma (Wayland) desktop, then open:
  System Settings > Remote Desktop
Add an RDP username and password there, then enable the server.
Approve screen sharing if Plasma asks.

KRdp shares the logged-in desktop. It does not provide a remote login screen.
Connect from a device on the same tailnet. Automatic local login is not enabled.
NEXT
