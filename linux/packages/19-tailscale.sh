#!/usr/bin/env bash
# Tailscale installer for Debian 13 (Trixie)
# Run: chmod +x tailscale.sh && ./tailscale.sh
# Optional unattended login: sudo TS_AUTHKEY='tskey-auth-...' ./tailscale.sh

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
else
  command -v sudo >/dev/null 2>&1 || die "sudo is required. Install it or run this script as root."
  SUDO="sudo"
  $SUDO -v
fi

[ -r /etc/os-release ] || die "/etc/os-release was not found."
# shellcheck disable=SC1091
. /etc/os-release

[ "${ID:-}" = "debian" ] || die "This installer supports Debian only. Detected: ${PRETTY_NAME:-unknown OS}"
[ "${VERSION_ID:-}" = "13" ] || die "Debian 13 is required. Detected: ${PRETTY_NAME:-Debian ${VERSION_ID:-unknown}}"

info "Detected ${PRETTY_NAME:-Debian 13}"
info "Installing prerequisites"
$SUDO apt-get update
$SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl

info "Downloading and running Tailscale's official Linux installer"
TMP_SCRIPT="$(mktemp)"
trap 'rm -f "$TMP_SCRIPT"' EXIT HUP INT TERM
curl -fsSL --proto '=https' --tlsv1.2 https://tailscale.com/install.sh -o "$TMP_SCRIPT"
[ -s "$TMP_SCRIPT" ] || die "The official installer download was empty."
$SUDO sh "$TMP_SCRIPT"

info "Enabling the Tailscale service at boot"
$SUDO systemctl enable --now tailscaled
$SUDO systemctl is-active --quiet tailscaled || die "tailscaled did not start successfully."

if [ -n "${TS_AUTHKEY:-}" ]; then
  info "Authenticating with TS_AUTHKEY"
  # The key is read from the environment and is not printed by this script.
  $SUDO tailscale up --auth-key="$TS_AUTHKEY"
else
  info "Tailscale is installed. Complete authentication using the URL below"
  $SUDO tailscale up
fi

info "Installation complete"
printf 'Tailscale IPv4: '
$SUDO tailscale ip -4 || true
printf '\nDevice status:\n'
$SUDO tailscale status || true
printf '\nUse the Tailscale IPv4 address in Windows App on your Mac.\n'
