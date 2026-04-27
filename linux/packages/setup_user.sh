#!/bin/bash
set -euo pipefail

echo "=== Secure Ubuntu/Debian VPS User Setup ==="

read -rp "Enter new sudo username: " USERNAME

if id "$USERNAME" &>/dev/null; then
  echo "❌ User already exists"
  exit 1
fi

# Create user (no password)
adduser "$USERNAME" --disabled-password --gecos ""

# Add to sudo group
usermod -aG sudo "$USERNAME"

# Setup SSH keys
mkdir -p /home/$USERNAME/.ssh

ROOT_KEYS=$(ls /root/.ssh/authorized_keys 2>/dev/null || true)

if [ -z "$ROOT_KEYS" ]; then
  echo "❌ No root authorized_keys found"
  exit 1
fi

cp "$ROOT_KEYS" /home/$USERNAME/.ssh/authorized_keys

chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
chmod 700 /home/$USERNAME/.ssh
chmod 600 /home/$USERNAME/.ssh/authorized_keys

# Passwordless sudo with validation
SUDO_FILE="/etc/sudoers.d/$USERNAME"
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >"$SUDO_FILE"
chmod 440 "$SUDO_FILE"

visudo -cf "$SUDO_FILE"

# SSH hardening (append-safe)
SSHD_CONFIG="/etc/ssh/sshd_config"
cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak"

set_sshd_option() {
  local key="$1"
  local value="$2"
  grep -qE "^\s*$key\b" "$SSHD_CONFIG" &&
    sed -i "s|^\s*$key.*|$key $value|" "$SSHD_CONFIG" ||
    echo "$key $value" >>"$SSHD_CONFIG"
}

set_sshd_option "PermitRootLogin" "no"
set_sshd_option "PasswordAuthentication" "no"
set_sshd_option "KbdInteractiveAuthentication" "no"
set_sshd_option "ChallengeResponseAuthentication" "no"
set_sshd_option "PubkeyAuthentication" "yes"
set_sshd_option "UsePAM" "yes"

# Validate SSH config BEFORE restart
sshd -t

# Restart SSH safely
systemctl restart ssh || systemctl restart sshd

# Lock root password
passwd -l root

echo ""
echo "✅ SETUP COMPLETE"
echo "➡ Test login in new terminal:"
echo "ssh -i key.pem $USERNAME@SERVER_IP"
echo ""
echo "⚠ Do NOT close this session until login works."
