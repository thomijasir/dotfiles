#!/usr/bin/env bash
# Shared browser setup for the KDE and XFCE installers.
# Callers provide SUDO, RUNUSER, info(), and die().
DESKTOP_APPS_LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

desktop_browser_package() {
  case "$1" in
    debian) printf 'firefox-esr\n' ;;
    ubuntu) printf 'firefox\n' ;;
    *) die "Unsupported browser platform: $1" ;;
  esac
}

desktop_verify_mozilla_key() {
  local key="$1" key_home="$2" fingerprints
  fingerprints="$(gpg --batch --homedir "$key_home" --with-colons --show-keys "$key" |
    awk -F: '$1 == "pub" { primary = 1 } primary && $1 == "fpr" { print $10; primary = 0 }')" ||
    die "Could not read the Mozilla signing key: $key"
  # Primary key published at https://support.mozilla.org/en-US/kb/install-firefox-linux.
  [ "$fingerprints" = 35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3 ] ||
    die "The Mozilla signing key fingerprint does not match. No repository key has been installed."
}

desktop_install_config() {
  local source="$1" destination="$2"
  $SUDO test ! -L "$destination" || die "Refusing a configuration symlink: $destination"
  if $SUDO test -e "$destination"; then
    $SUDO cmp -s -- "$source" "$destination" ||
      die "Conflicting configuration: $destination. The existing file has been preserved."
  else
    $SUDO install -D -m 644 -- "$source" "$destination"
  fi
}

desktop_firefox_candidate() {
  local candidate
  candidate="$(LC_ALL=C apt-cache policy firefox | awk '/Candidate:/ { print $2 }')"
  [ -n "$candidate" ] && [ "$candidate" != "(none)" ] || die "Native Firefox has no APT installation candidate."
  LC_ALL=C apt-cache madison firefox | awk -F'|' -v version="$candidate" '
    { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); gsub(/^[[:space:]]+/, "", $3) }
    $2 == version && $3 ~ /^https:\/\/packages\.mozilla\.org\/apt\/?[[:space:]]/ { found = 1 }
    END { exit !found }
  ' || die "The Firefox candidate is not from packages.mozilla.org. Check your APT sources and preferences."
  printf '%s\n' "$candidate"
}

prepare_desktop_browser() (
  [ "$1" = ubuntu ] || exit 0
  local work_dir source key has_source=false
  if ! command -v curl >/dev/null 2>&1 || ! command -v gpg >/dev/null 2>&1 ||
    ! python3 -c 'import shlex, urllib.parse' >/dev/null 2>&1; then
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg python3
  fi
  if [ ! -s /etc/ssl/certs/ca-certificates.crt ]; then
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates
  fi
  work_dir="$(mktemp -d)"
  trap 'rm -rf -- "$work_dir"' EXIT
  mkdir -m 700 "$work_dir/gnupg"
  $SUDO python3 "$DESKTOP_APPS_LIB_DIR/mozilla_sources.py" > "$work_dir/sources" ||
    die "Resolve the Mozilla APT source conflict above before rerunning this installer."
  info "Preparing native Firefox from Mozilla"
  curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
    --connect-timeout 20 --max-time 120 \
    https://packages.mozilla.org/apt/repo-signing-key.gpg > "$work_dir/key.asc"
  desktop_verify_mozilla_key "$work_dir/key.asc" "$work_dir/gnupg"
  while IFS="$(printf '\t')" read -r source key; do
    [ -n "$source" ] || continue
    $SUDO cat -- "$key" > "$work_dir/existing-key"
    desktop_verify_mozilla_key "$work_dir/existing-key" "$work_dir/gnupg"
    has_source=true
  done < "$work_dir/sources"
  if [ "$has_source" = false ]; then
    cat > "$work_dir/mozilla.sources" <<'SOURCE'
# Managed by dotfiles remote desktop installers.
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Signed-By: /etc/apt/keyrings/dotfiles-mozilla.asc
SOURCE
    desktop_install_config "$work_dir/key.asc" /etc/apt/keyrings/dotfiles-mozilla.asc
    desktop_install_config "$work_dir/mozilla.sources" /etc/apt/sources.list.d/dotfiles-mozilla.sources
  fi
  cat > "$work_dir/firefox.pref" <<'PREFERENCES'
# Managed by dotfiles remote desktop installers.
Package: firefox firefox-l10n-*
Pin: origin packages.mozilla.org
Pin-Priority: 1001

Package: firefox
Pin: release o=Ubuntu
Pin-Priority: -1
PREFERENCES
  desktop_install_config "$work_dir/firefox.pref" /etc/apt/preferences.d/dotfiles-firefox
  $SUDO apt-get update
  desktop_firefox_candidate >/dev/null
)

install_native_desktop_browser() {
  [ "$1" = ubuntu ] || return 0
  local version
  version="$(desktop_firefox_candidate)"
  # Ubuntu's transitional DEB has an epoch; allow a downgrade for Firefox alone.
  $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    --allow-downgrades "firefox=$version"
}

prepare_desktop_user_dirs() {
  $SUDO "$RUNUSER" -u "$1" -- env HOME="$2" XDG_CONFIG_HOME="$2/.config" xdg-user-dirs-update
}
