#!/usr/bin/env bash
set -euo pipefail

echo "📦 Setting up swapfile..."

SWAPFILE="/swapfile"
MAX_SWAP_MB=8192
SUDO=()

if [[ "$EUID" -ne 0 ]]; then
  SUDO=(sudo)
fi

DETECTED_RAM_MB=$(awk '/MemTotal/ {print int($2 / 1024)}' /proc/meminfo)

ROUNDED_RAM_MB=""

for SIZE in 512 1024 2048 3072 4096 6144 8192 12288 16384 24576 32768 49152 65536; do
  if [ "$DETECTED_RAM_MB" -le "$SIZE" ]; then
    ROUNDED_RAM_MB="$SIZE"
    break
  fi
done

if [ -z "$ROUNDED_RAM_MB" ]; then
  ROUNDED_RAM_MB="$DETECTED_RAM_MB"
fi

SWAP_MB=$((ROUNDED_RAM_MB / 2))

if [ "$SWAP_MB" -gt "$MAX_SWAP_MB" ]; then
  SWAP_MB="$MAX_SWAP_MB"
fi

if [ "$SWAP_MB" -lt 512 ]; then
  SWAP_MB=512
fi

echo "Detected RAM: ${DETECTED_RAM_MB}MB"
echo "Rounded VPS RAM: ${ROUNDED_RAM_MB}MB"
echo "Target swap size: ${SWAP_MB}MB"

if swapon --show | awk '{print $1}' | grep -qx "$SWAPFILE"; then
  CURRENT_SWAP_SIZE=$(swapon --show --bytes --noheadings --output SIZE "$SWAPFILE" | awk '{print int($1 / 1024 / 1024)}')
  echo "Swapfile already active at $SWAPFILE"
  echo "Current swap size: ${CURRENT_SWAP_SIZE}MB"

  if [ "$CURRENT_SWAP_SIZE" -eq "$SWAP_MB" ]; then
    echo "✅ Existing swapfile already has the correct size."
    free -h
    exit 0
  else
    echo "Recreating swapfile with correct size..."
    "${SUDO[@]}" swapoff "$SWAPFILE"
  fi
fi

if [ -f "$SWAPFILE" ]; then
  "${SUDO[@]}" rm -f "$SWAPFILE"
fi

if command -v fallocate >/dev/null 2>&1; then
  "${SUDO[@]}" fallocate -l "${SWAP_MB}M" "$SWAPFILE"
else
  "${SUDO[@]}" dd if=/dev/zero of="$SWAPFILE" bs=1M count="$SWAP_MB"
fi

"${SUDO[@]}" chmod 600 "$SWAPFILE"
"${SUDO[@]}" mkswap "$SWAPFILE"
"${SUDO[@]}" swapon "$SWAPFILE"

if ! grep -qE "^${SWAPFILE}[[:space:]]" /etc/fstab; then
  echo "$SWAPFILE none swap sw 0 0" | "${SUDO[@]}" tee -a /etc/fstab >/dev/null
fi

"${SUDO[@]}" sysctl vm.swappiness=10
"${SUDO[@]}" sysctl vm.vfs_cache_pressure=50

"${SUDO[@]}" sed -i '/^vm.swappiness=/d' /etc/sysctl.conf
"${SUDO[@]}" sed -i '/^vm.vfs_cache_pressure=/d' /etc/sysctl.conf

echo "vm.swappiness=10" | "${SUDO[@]}" tee -a /etc/sysctl.conf >/dev/null
echo "vm.vfs_cache_pressure=50" | "${SUDO[@]}" tee -a /etc/sysctl.conf >/dev/null

echo "✅ Swap setup complete!"
free -h
swapon --show
