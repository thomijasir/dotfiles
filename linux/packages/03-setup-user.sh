#!/bin/bash
set -euo pipefail

echo "=== Ubuntu/Debian VPS User Setup ==="

if [[ "$EUID" -ne 0 ]]; then
  echo "Run this script as root."
  exit 1
fi

# Check prerequisites before creating or changing an account.
for command_name in adduser usermod getent ssh-keygen sudo visudo sshd passwd; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required command is missing: $command_name"
    exit 1
  fi
done

SSHD_CONFIG="/etc/ssh/sshd_config"
ROOT_KEYS="/root/.ssh/authorized_keys"
if [[ ! -s "$ROOT_KEYS" ]] || ! ssh-keygen -lf "$ROOT_KEYS" >/dev/null 2>&1; then
  echo "No usable public keys found in $ROOT_KEYS."
  exit 1
fi
visudo -c
sshd -t

reload_ssh() {
  if [[ "$(ps -p 1 -o comm=)" == "systemd" ]]; then
    systemctl reload ssh || systemctl reload sshd
  else
    service ssh reload || service sshd reload
  fi
}

if [[ "$(ps -p 1 -o comm=)" != "systemd" ]] && ! command -v service >/dev/null 2>&1; then
  echo "No supported SSH service manager found."
  exit 1
fi

read -rp "Enter sudo username: " USERNAME
if [[ ! "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
  echo "Use a username starting with a lowercase letter or underscore, followed by letters, digits, underscores or hyphens."
  exit 1
fi

if id "$USERNAME" &>/dev/null; then
  if [[ "$(id -u "$USERNAME")" -lt 1000 ]]; then
    echo "Refusing to change a system account."
    exit 1
  fi
  read -rp "User exists. Resume setup for $USERNAME? [y/N]: " RESUME
  [[ "$RESUME" == "y" || "$RESUME" == "Y" ]] || exit 0
else
  adduser "$USERNAME" --disabled-password --gecos ""
fi

USER_HOME=$(getent passwd "$USERNAME" | cut -d: -f6)
if [[ "$USER_HOME" != /* || "$USER_HOME" == "/" || "$USER_HOME" == "/root" || ! -d "$USER_HOME" ]]; then
  echo "User has no suitable home directory: $USER_HOME"
  exit 1
fi

usermod -aG sudo "$USERNAME"
USER_GROUP=$(id -gn "$USERNAME")
install -d -m 700 -o "$USERNAME" -g "$USER_GROUP" "$USER_HOME/.ssh"
if [[ ! -s "$USER_HOME/.ssh/authorized_keys" ]]; then
  install -m 600 -o "$USERNAME" -g "$USER_GROUP" "$ROOT_KEYS" "$USER_HOME/.ssh/authorized_keys"
else
  chown "$USERNAME:$USER_GROUP" "$USER_HOME/.ssh/authorized_keys"
  chmod 600 "$USER_HOME/.ssh/authorized_keys"
fi

WORK_DIR=$(mktemp -d)
SSH_PENDING=0
cleanup() {
  local status=$?
  trap - EXIT
  if [[ "$SSH_PENDING" -eq 1 ]]; then
    echo "Restoring the previous SSH configuration."
    if cp -p "$WORK_DIR/sshd_config.bak" "$SSHD_CONFIG"; then
      reload_ssh || echo "Could not reload SSH after restoring the configuration." >&2
    else
      echo "Restore failed; backup retained at $WORK_DIR/sshd_config.bak." >&2
      exit 1
    fi
  fi
  rm -rf "$WORK_DIR"
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Validate the sudo rule before installing it.
SUDO_FILE="/etc/sudoers.d/90-setup-user-$USERNAME"
printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$USERNAME" >"$WORK_DIR/sudoers"
visudo -cf "$WORK_DIR/sudoers"
install -m 440 -o root -g root "$WORK_DIR/sudoers" "$SUDO_FILE"
visudo -c

echo "Open a second terminal and log in: ssh $USERNAME@SERVER_IP"
echo "In that session, run: sudo -n true"
echo "Keep this root session open."
read -rp "Did both commands succeed? Type YES to disable root SSH and password login: " CONFIRM
if [[ "$CONFIRM" != "YES" ]]; then
  echo "User setup complete. SSH settings and root password were left unchanged."
  exit 0
fi

# Put global settings before Includes and preserve existing Match blocks.
cp -p "$SSHD_CONFIG" "$WORK_DIR/sshd_config.bak"
{
  cat <<'SSH_OPTIONS'
# BEGIN setup-user hardening
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
UsePAM yes
# END setup-user hardening
SSH_OPTIONS
  awk '
    $0 == "# BEGIN setup-user hardening" { skip = 1; next }
    $0 == "# END setup-user hardening" { skip = 0; next }
    !skip { print }
  ' "$WORK_DIR/sshd_config.bak"
} >"$WORK_DIR/sshd_config"
SSH_PENDING=1
cp "$WORK_DIR/sshd_config" "$SSHD_CONFIG"
sshd -t

check_ssh_settings() {
  local settings
  settings=$(sshd -T "$@")
  local option
  for option in 'permitrootlogin no' 'passwordauthentication no' 'kbdinteractiveauthentication no' 'pubkeyauthentication yes' 'usepam yes'; do
    if ! grep -qxF "$option" <<<"$settings"; then
      echo "SSH configuration overrides the required setting: $option"
      return 1
    fi
  done
}
check_ssh_settings
if [[ -n "${SSH_CONNECTION:-}" ]]; then
  read -r CLIENT_ADDR _ SERVER_ADDR SERVER_PORT <<<"$SSH_CONNECTION"
  for LOGIN_USER in "$USERNAME" root; do
    check_ssh_settings -C "user=$LOGIN_USER,addr=$CLIENT_ADDR,host=$CLIENT_ADDR,laddr=$SERVER_ADDR,lport=$SERVER_PORT"
  done
fi

reload_ssh
passwd -l root
SSH_PENDING=0

echo "Setup complete. Test a fresh SSH login and sudo before closing this session."
