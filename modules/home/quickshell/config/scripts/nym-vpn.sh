#!/usr/bin/env bash
set -euo pipefail

nymvpnc="/run/current-system/sw/bin/nym-vpnc"
notify="/etc/profiles/per-user/honey/bin/notify-send"

notify_user() {
  if [ -x "$notify" ]; then
    "$notify" "VPN" "$1"
  fi
}

connected() {
  "$nymvpnc" status 2>/dev/null | grep -q '^State: Connected'
}

route() {
  "$nymvpnc" gateway get 2>/dev/null | awk -F'"' '
    /^Entry point/ { entry = NF > 1 ? $2 : "random" }
    /^Exit point/ { exit_country = NF > 1 ? $2 : "random" }
    END { print entry " -> " exit_country }
  '
}

connect() {
  "$nymvpnc" connect --wait >/dev/null 2>&1 || true

  if connected; then
    notify_user "VPN on: $(route)"
  else
    # Leaving the daemon in its error state would keep the kill switch blocking all traffic
    "$nymvpnc" disconnect --wait >/dev/null 2>&1 || true
    notify_user "VPN connection failed"
    exit 1
  fi
}

disconnect() {
  "$nymvpnc" disconnect --wait >/dev/null 2>&1 || true
  notify_user "VPN off"
}

case "${1:-toggle}" in
  toggle)
    if connected; then
      disconnect
    else
      connect
    fi
    ;;
  off)
    disconnect
    ;;
  set)
    "$nymvpnc" gateway set --entry-country "$2" --exit-country "$3" >/dev/null
    "$nymvpnc" disconnect --wait >/dev/null 2>&1 || true
    connect
    ;;
  *)
    echo "Usage: nym-vpn.sh [toggle|off|set ENTRY EXIT]" >&2
    exit 1
    ;;
esac
