#!/usr/bin/env bash
# Shared XRDP setup. Sourcing this file only defines functions.
# prepare_xrdp sets the account, network, browser, and password choices.

XRDP_LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=desktop-apps.sh
. "$XRDP_LIB_DIR/desktop-apps.sh"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=xrdp-network.sh
. "$XRDP_LIB_DIR/xrdp-network.sh"

info() { printf '\n%s\n' "$*"; }
warn() { printf 'Warning: %s\n' "$*" >&2; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

cleanup_xrdp() {
  unset XRDP_PASSWORD
  if [ -n "${CONFIG_TEMP:-}" ]; then
    $SUDO rm -f -- "$CONFIG_TEMP"
  fi
  if [ "${SERVICES_MASKED:-false}" = true ]; then
    $SUDO systemctl mask --now xrdp.service xrdp-sesman.service || warn "Could not stop XRDP after setup failed."
    warn "XRDP remains masked because setup failed. Fix the error and rerun this installer."
  fi
}

prepare_xrdp() {
  local tool session_path
  SUDO=""
  SERVICES_MASKED=false
  SESSION_BACKUP=".xsession.before-xrdp-$1"
  RDP_PORT="$2"
  trap cleanup_xrdp EXIT
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
  for session_path in "$TARGET_HOME/.xsession" "$TARGET_HOME/$SESSION_BACKUP"; do
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
  [[ "$RDP_PORT" =~ ^[1-9][0-9]{0,4}$ ]] && [ "$RDP_PORT" -le 65535 ] ||
    die "RDP port must be a number from 1 to 65535."
  prepare_xrdp_network "$RDP_PORT"

  BROWSER_PACKAGE="$(desktop_browser_package "$ID")"
  choose_xrdp_password
}

choose_xrdp_password() {
  local answer password confirmation
  CHANGE_PASSWORD=true
  GENERATED_PASSWORD=false
  if [ "$($SUDO passwd -S "$TARGET_USER" | awk '{ print $2 }')" = P ]; then
    while true; do
      IFS= read -r -p "Keep the existing Linux account password for XRDP? [Y/n]: " answer ||
        die "No password choice received."
      case "$answer" in
        ""|y|Y|yes|YES) CHANGE_PASSWORD=false; break ;;
        n|N|no|NO) break ;;
        *) warn "Enter y or n." ;;
      esac
    done
  fi
  if [ "$CHANGE_PASSWORD" = true ]; then
    printf 'This sets your Linux account password, which XRDP uses to log in. SSH key login is unaffected.\n'
    while true; do
      IFS= read -s -r -p "New password (empty = generate): " password || die "No password input received."
      printf '\n'
      if [ -z "$password" ]; then
        # Read a fixed amount of entropy so pipefail cannot see a SIGPIPE.
        XRDP_PASSWORD="$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')"
        [[ "$XRDP_PASSWORD" =~ ^[0-9a-f]{32}$ ]] || die "Failed to generate a password."
        GENERATED_PASSWORD=true
        break
      fi
      IFS= read -s -r -p "Confirm password: " confirmation || die "No password confirmation received."
      printf '\n'
      if [ "$password" = "$confirmation" ]; then
        XRDP_PASSWORD="$password"
        break
      fi
      warn "Passwords did not match. Try again."
    done
  fi
}

install_xrdp() {
  info "Installing XRDP and desktop apps"
  $SUDO apt-get update
  prepare_desktop_browser "$ID"
  local packages=(
    xrdp xorgxrdp xserver-xorg-core xauth x11-xserver-utils
    dbus-x11 dbus-daemon dbus-user-session libpam-systemd ssl-cert
    "$BROWSER_PACKAGE" vlc zip unzip xz-utils
    xdg-utils xdg-user-dirs shared-mime-info desktop-file-utils
    fonts-dejavu fonts-liberation
    "$@"
  )
  # Resolve packages before stopping a working desktop.
  $SUDO apt-get -s install --no-install-recommends "${packages[@]}" >/dev/null
  # Keep package post-install scripts from starting a public RDP listener.
  SERVICES_MASKED=true
  $SUDO systemctl mask --now xrdp.service xrdp-sesman.service
  install_native_desktop_browser "$ID"
  $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${packages[@]}"
  prepare_desktop_user_dirs "$TARGET_USER" "$TARGET_HOME"
}

write_xrdp_session() {
  info "Writing the desktop session for $TARGET_USER"
  # Variables in this script expand in the target user's shell.
  # shellcheck disable=SC2016
  $SUDO "$RUNUSER" -u "$TARGET_USER" -- sh -c '
    set -eu
    cd "$1"
    session_file=.xsession
    backup="$2"
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
  ' sh "$TARGET_HOME" "$SESSION_BACKUP"
}

disable_native_krdp() {
  local target_uid
  # Native KRdp can hold the RDP port or start again at login.
  # Mask only this user's native server; retain its settings and certificates.
  if command -v krdpserver >/dev/null 2>&1; then
    info "Disabling native KRdp for '$TARGET_USER'"
    target_uid="$(id -u "$TARGET_USER")"
    if [ -S "/run/user/$target_uid/bus" ]; then
      $SUDO "$RUNUSER" -u "$TARGET_USER" -- env \
        XDG_CONFIG_HOME="$TARGET_HOME/.config" XDG_RUNTIME_DIR="/run/user/$target_uid" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$target_uid/bus" \
        systemctl --user mask --now app-org.kde.krdpserver.service
    else
      $SUDO "$RUNUSER" -u "$TARGET_USER" -- env XDG_CONFIG_HOME="$TARGET_HOME/.config" \
        SYSTEMD_OFFLINE=1 systemctl --user --no-reload mask app-org.kde.krdpserver.service
    fi
  fi
}

configure_ini() {
  local config="$1" section="$2"
  shift 2
  [ ! -L "$config" ] || die "Refusing to overwrite a symlink: $config"
  $SUDO test -f "$config" || die "Configuration is missing: $config"
  $SUDO cp -p --no-clobber "$config" "$config.before-dotfiles"
  CONFIG_TEMP="$($SUDO mktemp "${config%/*}/.config.XXXXXX")"
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

configure_xrdp() {
  info "Configuring XRDP listeners: $RDP_LISTEN"
  configure_ini /etc/xrdp/xrdp.ini Globals "port=$RDP_LISTEN" use_vsock=false security_layer=tls
  configure_ini /etc/xrdp/sesman.ini Security AllowRootLogin=false
  $SUDO usermod -aG ssl-cert xrdp

  # Retry if the selected interfaces are not ready at boot.
  $SUDO install -d -m 755 /etc/systemd/system/xrdp.service.d
  $SUDO tee /etc/systemd/system/xrdp.service.d/tailscale.conf >/dev/null <<'UNIT'
[Unit]
Wants=network-online.target tailscaled.service
After=network-online.target tailscaled.service

[Service]
Restart=on-failure
RestartSec=5s
UNIT
  allow_xrdp_firewall "$RDP_PORT"
}

start_xrdp() {
  local service _attempt
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
  # Wait for the daemon to open every configured listener.
  for _attempt in {1..10}; do
    if xrdp_listeners_match "$RDP_PORT"; then
      SERVICES_MASKED=false
      return 0
    fi
    sleep 1
  done
  die "XRDP did not bind exclusively to the configured addresses ($RDP_LISTEN)."
}

print_xrdp_summary() {
  print_xrdp_network
  printf 'Port: %s\nSession: Xorg\nDesktop: %s\nUser: %s\n' "$RDP_PORT" "$1" "$TARGET_USER"
  if [ "$GENERATED_PASSWORD" = true ]; then
    printf '\nGenerated Linux account password: %s\nSave it now; it will not be shown again.\n' "$XRDP_PASSWORD"
  else
    printf 'Password: your Linux account password\n'
  fi
  printf '\nConnect through Tailscale or the enabled LAN address and select Xorg.\nLog out of other graphical sessions for this user before connecting.\n'
}

