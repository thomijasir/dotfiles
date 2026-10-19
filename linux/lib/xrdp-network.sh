#!/usr/bin/env bash
# Shared optional LAN access for the KDE and XFCE XRDP installers.
# Callers provide SUDO, TS_IP, info(), and die().

xrdp_private_ipv4() {
  local address="$1" octet a b c d
  [[ "$address" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  IFS=. read -r a b c d <<< "$address"
  for octet in "$a" "$b" "$c" "$d"; do
    [ "$((10#$octet))" -le 255 ] && [ "$((10#$octet))" = "$octet" ] || return 1
  done
  [ "$a" = 10 ] || { [ "$a" = 172 ] && [ "$b" -ge 16 ] && [ "$b" -le 31 ]; } ||
    { [ "$a" = 192 ] && [ "$b" = 168 ]; }
}

xrdp_saved_lan_ip() {
  local value endpoint address
  local endpoints=()
  $SUDO test -f /etc/xrdp/xrdp.ini || return 0
  # shellcheck disable=SC2016
  value="$($SUDO awk '
    /^[[:space:]]*\[/ {
      header = tolower($0)
      gsub(/^[[:space:]]*\[|\][[:space:]]*$/, "", header)
      globals = (header == "globals")
    }
    globals && tolower($0) ~ /^[[:space:]]*port[[:space:]]*=/ {
      sub(/^[^=]*=[[:space:]]*/, "")
      sub(/[;#].*$/, "")
      print
      exit
    }
  ' /etc/xrdp/xrdp.ini)"
  read -r -a endpoints <<< "${value//,/ }"
  for endpoint in "${endpoints[@]}"; do
    address="${endpoint#tcp://}"
    address="${address%:*}"
    if xrdp_private_ipv4 "$address"; then
      printf '%s\n' "$address"
      return 0
    fi
  done
}

xrdp_detect_lan_ip() {
  local interface cidr address default_interface
  default_interface="$(ip -4 route show default | awk '
    { for (i = 1; i < NF; i++) if ($i == "dev") { print $(i + 1); exit } }
  ')"
  if [ -n "$default_interface" ]; then
    while read -r interface cidr; do
      address="${cidr%/*}"
      if xrdp_private_ipv4 "$address"; then printf '%s\n' "$address"; return 0; fi
    done < <(ip -o -4 addr show dev "$default_interface" up scope global | awk '{ print $2, $4 }')
  fi
  while read -r interface cidr; do
    case "$interface" in lo|tailscale0|docker*|veth*|br-*|virbr*) continue ;; esac
    address="${cidr%/*}"
    if xrdp_private_ipv4 "$address"; then printf '%s\n' "$address"; return 0; fi
  done < <(ip -o -4 addr show up scope global | awk '{ print $2, $4 }')
}

xrdp_lan_details() {
  local details cidr prefix minimum a b c d number network mask
  xrdp_private_ipv4 "$LAN_IP" || die "LAN access requires a private IPv4 address in 10/8, 172.16/12, or 192.168/16."
  details="$(ip -o -4 addr show up scope global | awk -v address="$LAN_IP" '
    { split($4, parts, "/"); if (parts[1] == address) print $2, $4 }
  ')"
  [ -n "$details" ] && [[ "$details" != *$'\n'* ]] ||
    die "LAN address '$LAN_IP' must be assigned to exactly one active interface. Set XRDP_LAN_IP to its current address, or off."
  read -r LAN_INTERFACE cidr <<< "$details"
  LAN_INTERFACE="${LAN_INTERFACE%%@*}"
  [[ "$LAN_INTERFACE" =~ ^[a-zA-Z0-9_.:-]+$ ]] && [ "$LAN_INTERFACE" != tailscale0 ] ||
    die "Could not use the LAN interface '$LAN_INTERFACE'."
  prefix="${cidr#*/}"
  IFS=. read -r a b c d <<< "$LAN_IP"
  case "$a" in 10) minimum=8 ;; 172) minimum=12 ;; *) minimum=16 ;; esac
  [[ "$prefix" =~ ^[0-9]{1,2}$ ]] && [ "$prefix" -ge "$minimum" ] && [ "$prefix" -le 32 ] ||
    die "The LAN interface subnet must stay within its private IPv4 range."
  number=$(((a << 24) | (b << 16) | (c << 8) | d))
  mask=$(((0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF))
  network=$((number & mask))
  printf -v LAN_NETWORK '%s.%s.%s.%s/%s' "$(((network >> 24) & 255))" "$(((network >> 16) & 255))" \
    "$(((network >> 8) & 255))" "$((network & 255))" "$prefix"
}

prepare_xrdp_network() {
  local port="$1" saved candidate answer
  LAN_IP="" LAN_INTERFACE="" LAN_NETWORK=""
  if [ "${XRDP_LAN_IP+x}" = x ]; then
    LAN_IP="$XRDP_LAN_IP"
  else
    saved="$(xrdp_saved_lan_ip)"
    if [ -n "$saved" ]; then
      LAN_IP="$saved"
      info "Keeping LAN access at $LAN_IP"
    elif [ -t 0 ]; then
      candidate="$(xrdp_detect_lan_ip)"
      if [ -n "$candidate" ]; then
        IFS= read -r -p "Also allow RDP on your local network ($candidate)? [y/N]: " answer ||
          die "No network choice received."
        case "$answer" in
          y|Y|yes|YES)
            IFS= read -r -p "Local IPv4 address [$candidate]: " LAN_IP || die "No LAN address received."
            LAN_IP="${LAN_IP:-$candidate}"
            ;;
          ""|n|N|no|NO) ;;
          *) die "Enter y or n, or set XRDP_LAN_IP to a private address or off." ;;
        esac
      fi
    fi
  fi
  [ "$LAN_IP" != off ] || LAN_IP=""
  RDP_LISTEN="tcp://$TS_IP:$port"
  if [ -n "$LAN_IP" ]; then
    xrdp_lan_details
    RDP_LISTEN="$RDP_LISTEN,tcp://$LAN_IP:$port"
    info "RDP access: Tailscale $TS_IP and LAN $LAN_IP ($LAN_INTERFACE)"
  else
    info "RDP access: Tailscale $TS_IP only"
  fi
}

allow_xrdp_firewall() {
  local port="$1"
  if command -v ufw >/dev/null 2>&1 && $SUDO env LC_ALL=C ufw status | grep -q '^Status: active'; then
    $SUDO ufw allow in on tailscale0 to any port "$port" proto tcp
    if [ -n "$LAN_IP" ]; then
      $SUDO ufw allow in on "$LAN_INTERFACE" from "$LAN_NETWORK" to "$LAN_IP" port "$port" proto tcp \
        comment 'dotfiles XRDP LAN'
    fi
  fi
}

xrdp_listeners_match() {
  local port="$1" lan=""
  [ -z "$LAN_IP" ] || lan="$LAN_IP:$port"
  ss -H -ltn "sport = :$port" | awk -v tailnet="$TS_IP:$port" -v lan="$lan" '
    $4 == tailnet { tailnet_count++; next }
    lan != "" && $4 == lan { lan_count++; next }
    { bad = 1 }
    END { exit bad || tailnet_count != 1 || (lan != "" && lan_count != 1) }
  '
}

print_xrdp_network() {
  printf 'Tailscale host: %s\n' "$TS_IP"
  [ -z "$LAN_IP" ] || printf 'LAN host: %s\n' "$LAN_IP"
}
