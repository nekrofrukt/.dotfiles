#!/bin/bash

IFACE="se-sto-wg-001"

toggle() {
    if sudo wg show "$IFACE" 2>/dev/null | grep -q "latest handshake"; then
        sudo wg-quick down "$IFACE"
    else
        sudo wg-quick up "$IFACE"
    fi
}

status() {
    if sudo wg show "$IFACE" 2>/dev/null | grep -q "latest handshake"; then
        location=$(curl -s --max-time 3 https://am.i.mullvad.net/json 2>/dev/null | grep -o '"country":"[^"]*"' | cut -d'"' -f4)
        city=$(curl -s --max-time 3 https://am.i.mullvad.net/json 2>/dev/null | grep -o '"city":"[^"]*"' | cut -d'"' -f4)
        [ -z "$location" ] && location="Mullvad"
        [ -n "$city" ] && location="$city, $location"
        printf '{"text": "WRG ↑", "tooltip": "WireGuard: Connected — %s", "class": "on"}\n' "$location"
    else
        echo '{"text": "WRG ↓", "tooltip": "WireGuard: Disconnected", "class": "off"}'
    fi
}

case "${1:-}" in
    --toggle) toggle ;;
    *) status ;;
esac
