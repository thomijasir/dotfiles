#!/usr/bin/env bash
# XRDP + XFCE installer for Debian/Ubuntu servers.
# XRDP listens only on the current Tailscale IPv4 address.
# Run as your normal login user, or with sudo preserving SUDO_USER.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../lib/desktop-apps.sh
. "$SCRIPT_DIR/../lib/desktop-apps.sh"

info() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\n\033[1;33mWarning: %s\033[0m\n' "$*" >&2; }
die() { printf '\n\033[1;31mError: %s\033[0m\n' "$*" >&2; exit 1; }

cleanup() {
  unset PW1 PW2 XRDP_PASSWORD
  if [ -n "${CONFIG_TEMP:-}" ]; then
    $SUDO rm -f -- "$CONFIG_TEMP"
  fi
  if [ "${SERVICES_MASKED:-false}" = true ]; then
    $SUDO systemctl mask --now xrdp.service xrdp-sesman.service || warn "Could not mask XRDP after setup failed."
    warn "XRDP services remain masked because setup did not finish. Fix the error and rerun this installer."
  fi
}
trap cleanup EXIT

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
  die "Run as your normal login user, or use sudo from that account. XRDP will not be configured for root."
id "$TARGET_USER" >/dev/null 2>&1 || die "Target user '$TARGET_USER' does not exist."
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
[ -n "$TARGET_HOME" ] && [ -d "$TARGET_HOME" ] || die "Could not find the home directory for '$TARGET_USER'."
# Administrative tools may be outside a normal login user's PATH.
export PATH="$PATH:/usr/local/sbin:/usr/sbin:/sbin"
command -v tailscale >/dev/null 2>&1 ||
  die "Required command 'tailscale' is missing. Install Tailscale before running this installer."
for tool in ip ss; do
  command -v "$tool" >/dev/null 2>&1 ||
    die "Required command '$tool' is missing. Install iproute2: sudo apt-get install iproute2"
done
RUNUSER="$(command -v runuser)" ||
  die "Required command 'runuser' is missing. Install util-linux: sudo apt-get install util-linux"
for session_path in "$TARGET_HOME/.xsession" "$TARGET_HOME/.xsession.before-xrdp-xfce"; do
  $SUDO test ! -L "$session_path" || die "Refusing to replace or back up a symlink: $session_path"
  if $SUDO test -e "$session_path"; then
    $SUDO test -f "$session_path" || die "Expected a regular file: $session_path"
  fi
done

info "Checking Tailscale"
$SUDO tailscale status >/dev/null 2>&1 || die "Run 'sudo tailscale up' before running this installer."
TS_IP="$($SUDO tailscale ip -4)"
# Require one IPv4 address and confirm it is assigned to the Tailscale interface.
[[ "$TS_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || die "Could not determine a single Tailscale IPv4 address."
ip -o -4 addr show dev tailscale0 | awk -v address="$TS_IP" '
  { split($4, parts, "/"); if (parts[1] == address) found = 1 }
  END { exit !found }
' || die "Tailscale address '$TS_IP' is not assigned to tailscale0."
info "Tailscale address: $TS_IP"

# Collect credentials before installing packages or stopping services.
CHANGE_PASSWORD=true
GENERATED_PASSWORD=false
if [ "$($SUDO passwd -S "$TARGET_USER" | awk '{ print $2 }')" = P ]; then
  while true; do
    IFS= read -r -p "Keep the existing Linux account password for XRDP? [Y/n]: " KEEP_PASSWORD ||
      die "No password choice received."
    case "$KEEP_PASSWORD" in
      ""|y|Y|yes|YES) CHANGE_PASSWORD=false; break ;;
      n|N|no|NO) break ;;
      *) warn "Enter y or n." ;;
    esac
  done
fi
if [ "$CHANGE_PASSWORD" = true ]; then
  printf 'This sets your Linux account password, which XRDP uses to log in. SSH key login is unaffected.\n'
  while true; do
    IFS= read -s -r -p "New password (empty = generate): " PW1 || die "No password input received."
    printf '\n'
    if [ -z "$PW1" ]; then
      # Read a fixed amount of entropy so pipefail cannot see a SIGPIPE.
      XRDP_PASSWORD="$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')"
      [[ "$XRDP_PASSWORD" =~ ^[0-9a-f]{32}$ ]] || die "Failed to generate a password."
      GENERATED_PASSWORD=true
      break
    fi
    IFS= read -s -r -p "Confirm password: " PW2 || die "No password confirmation received."
    printf '\n'
    if [ "$PW1" = "$PW2" ]; then
      XRDP_PASSWORD="$PW1"
      break
    fi
    warn "Passwords did not match. Try again."
  done
fi

info "Checking XRDP and XFCE packages"
$SUDO apt-get update
BROWSER_PACKAGE="$(desktop_browser_package "$ID")"
prepare_desktop_browser "$ID"
PACKAGES=(
  xrdp xorgxrdp xserver-xorg-core xauth x11-xserver-utils
  dbus-x11 dbus-daemon dbus-user-session libpam-systemd ssl-cert
  xfce4 xfce4-goodies xfce4-terminal
  thunar thunar-archive-plugin thunar-volman mousepad ristretto file-roller
  xfce4-screenshooter xfce4-taskmanager galculator
  atril "$BROWSER_PACKAGE"
  vlc zip unzip xz-utils xdg-utils xdg-user-dirs shared-mime-info desktop-file-utils
  fonts-dejavu fonts-liberation
)
for package in "${PACKAGES[@]}"; do
  candidate="$(LC_ALL=C apt-cache policy "$package" | awk '/Candidate:/ { print $2 }')"
  [ -n "$candidate" ] && [ "$candidate" != "(none)" ] ||
    die "Package '$package' has no installation candidate. Check your APT repositories. The XFCE desktop and xorgxrdp packages are required."
done
$SUDO apt-get -s install --no-install-recommends "${PACKAGES[@]}" >/dev/null

# Prevent package post-install scripts from starting a public RDP listener.
info "Stopping XRDP while configuring it"
$SUDO systemctl mask xrdp.service xrdp-sesman.service
SERVICES_MASKED=true
$SUDO systemctl stop xrdp.service xrdp-sesman.service
install_native_desktop_browser "$ID"
$SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${PACKAGES[@]}"
command -v startxfce4 >/dev/null 2>&1 || die "The XFCE X11 launcher (startxfce4) is missing."
verify_desktop_apps "$BROWSER_PACKAGE" thunar xfce4-terminal mousepad ristretto file-roller xfce4-screenshooter xfce4-taskmanager galculator atril vlc
prepare_desktop_user_dirs "$TARGET_USER" "$TARGET_HOME"

# Write as the login user so paths in their home never receive root writes.
info "Configuring the XFCE X11 session for '$TARGET_USER'"
# Variables in this script expand in the target user's shell.
# shellcheck disable=SC2016
$SUDO "$RUNUSER" -u "$TARGET_USER" -- sh -c '
  set -eu
  cd "$1"
  session_file=.xsession
  backup=.xsession.before-xrdp-xfce
  for path in "$session_file" "$backup"; do
    [ ! -L "$path" ] || { printf "Refusing symlink: %s\n" "$path" >&2; exit 1; }
    [ ! -e "$path" ] || [ -f "$path" ] || exit 1
  done
  if [ -f "$session_file" ] && [ ! -e "$backup" ]; then
    cp --no-clobber --preserve=mode,timestamps -- "$session_file" "$backup"
  fi
  session_temp="$(mktemp .xsession.xrdp.XXXXXX)"
  trap '\''rm -f -- "$session_temp"'\'' EXIT
  cat > "$session_temp"
  chmod 644 "$session_temp"
  mv -fT -- "$session_temp" "$session_file"
' sh "$TARGET_HOME" <<'SESSION'
#!/bin/sh
unset SESSION_MANAGER DBUS_SESSION_BUS_ADDRESS WAYLAND_DISPLAY
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=XFCE
export DESKTOP_SESSION=xfce
exec dbus-run-session -- startxfce4
SESSION

info "Restricting XRDP to $TS_IP:3389"
configure_ini() {
  local config="$1" section="$2"
  shift 2
  [ ! -L "$config" ] || die "Refusing to overwrite a symlink: $config"
  $SUDO test -f "$config" || die "Configuration is missing: $config"
  $SUDO cp -p --no-clobber "$config" "$config.before-dotfiles"
  CONFIG_TEMP="$($SUDO mktemp /etc/xrdp/.config.XXXXXX)"
  # Preserve other sections, including backend port values in xrdp.ini.
  # shellcheck disable=SC2016
  $SUDO awk -v section="$section" -v settings="$*" '
    BEGIN {
      count = split(settings, desired, " ")
      for (i = 1; i <= count; i++) {
        split(desired[i], pair, "=")
        keys[tolower(pair[1])] = 1
      }
    }
    function write_settings() {
      for (i = 1; i <= count; i++) print desired[i]
    }
    /^[[:space:]]*\[/ {
      if (in_section) write_settings()
      header = tolower($0)
      gsub(/^[[:space:]]*\[|\][[:space:]]*$/, "", header)
      in_section = (header == tolower(section))
      if (in_section) section_count++
    }
    in_section && /^[[:space:]]*[^;#][^=]*=/ {
      split($0, pair, "=")
      key = tolower(pair[1])
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
      if (key in keys) next
    }
    { print }
    END {
      if (in_section) write_settings()
      if (section_count != 1) exit 1
    }
  ' "$config" | $SUDO tee "$CONFIG_TEMP" >/dev/null ||
    die "Could not configure [$section] in $config."
  $SUDO chmod --reference="$config" "$CONFIG_TEMP"
  $SUDO chown --reference="$config" "$CONFIG_TEMP"
  $SUDO mv -fT -- "$CONFIG_TEMP" "$config"
  CONFIG_TEMP=""
}
configure_ini /etc/xrdp/xrdp.ini Globals "port=tcp://$TS_IP:3389" use_vsock=false security_layer=tls
configure_ini /etc/xrdp/sesman.ini Security AllowRootLogin=false
$SUDO usermod -aG ssl-cert xrdp

# Retry if tailscaled has started but its address is not ready at boot.
$SUDO install -d -m 755 /etc/systemd/system/xrdp.service.d
$SUDO tee /etc/systemd/system/xrdp.service.d/tailscale.conf >/dev/null <<'UNIT'
[Unit]
Wants=network-online.target tailscaled.service
After=network-online.target tailscaled.service

[Service]
Restart=on-failure
RestartSec=5s
UNIT

if command -v ufw >/dev/null 2>&1 && $SUDO env LC_ALL=C ufw status | grep -q '^Status: active'; then
  info "Allowing RDP through tailscale0 in UFW"
  $SUDO ufw allow in on tailscale0 to any port 3389 proto tcp
fi
if [ "$CHANGE_PASSWORD" = true ]; then
  printf '%s:%s\n' "$TARGET_USER" "$XRDP_PASSWORD" | $SUDO chpasswd
fi

info "Starting XRDP"
$SUDO systemctl unmask xrdp.service xrdp-sesman.service
$SUDO systemctl daemon-reload
$SUDO systemctl enable xrdp.service
$SUDO systemctl restart xrdp-sesman.service xrdp.service
for service in xrdp.service xrdp-sesman.service; do
  $SUDO systemctl is-active --quiet "$service" || die "Service $service did not start."
done
# Allow the forked daemon a moment to create its listening socket.
LISTENER_OK=false
for _attempt in {1..10}; do
  if ss -H -ltn 'sport = :3389' | awk -v expected="$TS_IP:3389" '
    $4 != expected { bad = 1 }
    END { exit bad || NR == 0 }
  '; then
    LISTENER_OK=true
    break
  fi
  sleep 1
done
if [ "$LISTENER_OK" != true ]; then
  $SUDO systemctl stop xrdp.service
  die "XRDP did not bind exclusively to $TS_IP:3389. The service has been stopped."
fi

SERVICES_MASKED=false
info "XRDP + XFCE installation complete"
printf 'Host: %s\nPort: 3389\nSession: Xorg\nDesktop: XFCE (X11)\nUser: %s\n' "$TS_IP" "$TARGET_USER"
printf 'Apps: Firefox, Thunar, XFCE Terminal, Mousepad, Atril, Ristretto, File Roller, Screenshooter, Task Manager, Galculator, VLC\n'
if [ "$GENERATED_PASSWORD" = true ]; then
  printf '\nGenerated Linux account password: %s\nSave it now; it will not be shown again.\n' "$XRDP_PASSWORD"
else
  printf 'Password: your Linux account password\n'
fi
printf '\nConnect from a client on the same tailnet. Log out of other graphical sessions for this user before connecting.\n'
