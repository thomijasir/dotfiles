#!/usr/bin/env bash
# XRDP + XFCE installer for Debian/Ubuntu servers.
#
# Remote desktop is meant to be reached over Tailscale only, so this
# installer refuses to proceed unless Tailscale is installed and up.
#
# XFCE is used deliberately: it is the lightest practical full desktop
# for an RDP session over a tailnet, so CPU/RAM on the server stay low.
#
# The login user normally authenticates with an SSH PEM key and has no
# password set. XRDP needs a password, so at the end of the run you are
# prompted to set one for the current user.

set -euo pipefail

info() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\n\033[1;33mWarning: %s\033[0m\n' "$*" >&2; }
die() {
  printf '\n\033[1;31mError: %s\033[0m\n' "$*" >&2
  exit 1
}

# Obtain root once, while still supporting execution as root.
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
  TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
else
  command -v sudo >/dev/null 2>&1 || die "sudo is required. Install it or run this script as root."
  SUDO="sudo"
  # Prefer passwordless (NOPASSWD) sudo: validate without prompting. Only
  # fall back to an interactive prompt when a password is actually required.
  $SUDO -n true 2>/dev/null || $SUDO -v
  TARGET_USER="$(id -un)"
fi

[ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ] || die "Refusing to configure XRDP for root. Run this as your normal login user."
id "$TARGET_USER" >/dev/null 2>&1 || die "Target user '$TARGET_USER' does not exist."
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
[ -n "$TARGET_HOME" ] && [ -d "$TARGET_HOME" ] || die "Could not determine home directory for '$TARGET_USER'."

# ---------------------------------------------------------------------------
# Precheck: Tailscale must be installed and authenticated, because XRDP
# traffic is expected to flow over the tailnet only.
# ---------------------------------------------------------------------------
info "Checking Tailscale prerequisite"
if ! command -v tailscale >/dev/null 2>&1; then
  die "Tailscale is not installed. Run the '19-tailscale.sh' installer first, then re-run this script."
fi
if ! $SUDO tailscale status >/dev/null 2>&1; then
  die "Tailscale is installed but not authenticated (or tailscaled is not running). Run 'sudo tailscale up', then re-run this script."
fi
TS_IP="$($SUDO tailscale ip -4 2>/dev/null | head -n1 || true)"
[ -n "$TS_IP" ] || warn "Could not detect a Tailscale IPv4 address. XRDP will still be installed, but you will need the tailnet IP to connect."
info "Tailscale OK (IP: ${TS_IP:-unknown})"

# ---------------------------------------------------------------------------
# Install XRDP + XFCE (lightweight, optimized for an RDP-over-Tailscale
# server) plus a set of essential GUI applications.
# ---------------------------------------------------------------------------
info "Installing XRDP, the XFCE desktop and essential GUI apps"
$SUDO apt-get update
$SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  xrdp \
  dbus-x11 \
  xfce4 \
  xfce4-goodies \
  xfce4-terminal \
  thunar \
  thunar-archive-plugin \
  thunar-volman \
  firefox-esr \
  mousepad \
  ristretto \
  file-roller \
  xfce4-screenshooter \
  xfce4-taskmanager \
  galculator \
  gnome-system-monitor \
  network-manager-gnome \
  dbus-x11 \
  fonts-dejavu \
  fonts-liberation

# ---------------------------------------------------------------------------
# Configure the XRDP session for the login user
# ---------------------------------------------------------------------------
info "Configuring XRDP session for user '$TARGET_USER'"

# Start the XFCE session from the user's ~/.xsession so xrdp picks it up.
echo "startxfce4" > "$TARGET_HOME/.xsession"
$SUDO chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.xsession"
chmod 644 "$TARGET_HOME/.xsession"

# Allow xrdp to read the snakeoil TLS certificate on Debian/Ubuntu.
$SUDO usermod -aG ssl-cert xrdp

# ---------------------------------------------------------------------------
# Enable and (re)start the XRDP service
# ---------------------------------------------------------------------------
info "Enabling and starting the XRDP service"
$SUDO systemctl enable xrdp
$SUDO systemctl restart xrdp
$SUDO systemctl is-active --quiet xrdp || die "xrdp did not start successfully."

# ---------------------------------------------------------------------------
# Firewall: if ufw is active, allow RDP only on the Tailscale interface so
# port 3389 is never exposed to the public internet.
# ---------------------------------------------------------------------------
if command -v ufw >/dev/null 2>&1 && $SUDO ufw status >/dev/null 2>&1; then
  if $SUDO ufw status | grep -qi "Status: active"; then
    info "ufw is active - allowing port 3389 on the tailscale0 interface only"
    $SUDO ufw allow in on tailscale0 to any port 3389 proto tcp || warn "Failed to add ufw rule for tailscale0."
  fi
fi

# ---------------------------------------------------------------------------
# Set a login password for the current user.
# PEM-key users usually have no password set; XRDP requires one.
# ---------------------------------------------------------------------------
info "Setting an XRDP login password for user '$TARGET_USER'"
printf 'Your SSH PEM key login is unaffected. This password is only used by the XRDP login screen.\n'
printf 'Leave both prompts empty to auto-generate a strong password.\n'

while true; do
  IFS= read -s -r -p "Enter XRDP password for '$TARGET_USER' (empty = generate): " PW1; printf '\n'

  # Empty input -> generate a strong, random password and stop prompting.
  if [ -z "$PW1" ]; then
    # Prefer openssl; fall back to /dev/urandom if it is missing.
    if command -v openssl >/dev/null 2>&1; then
      XRDP_PASSWORD="$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9' | cut -c1-24)"
    else
      XRDP_PASSWORD="$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24)"
    fi
    [ -n "$XRDP_PASSWORD" ] || die "Failed to generate a password."
    info "Generated a strong password for '$TARGET_USER'"
    printf '\n\033[1;32m  %s\033[0m\n\n' "$XRDP_PASSWORD"
    printf 'Save this now - it will not be shown again.\n'
    break
  fi

  IFS= read -s -r -p "Confirm password: " PW2; printf '\n'
  if [ "$PW1" = "$PW2" ]; then
    XRDP_PASSWORD="$PW1"
    break
  fi
  warn "Passwords did not match. Please try again."
done

# chpasswd reads "user:password" on stdin; the password never appears in
# the process list or shell history because it arrives via a pipe.
printf '%s:%s\n' "$TARGET_USER" "$XRDP_PASSWORD" | $SUDO chpasswd
unset PW1 PW2 XRDP_PASSWORD

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
info "XRDP installation complete"
cat <<EOF

Connect with an RDP client (Remmina, Microsoft Remote Desktop, etc.):

  Host:     ${TS_IP:-<your-tailscale-IP>}
  Port:     3389
  User:     $TARGET_USER
  Password: the one you just set

Make sure your client machine is on the same tailnet. RDP is not exposed
to the public internet; it is reachable only over Tailscale.

EOF
