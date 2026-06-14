#!/bin/bash

status=$(nordvpn status)
connected=$(echo "$status" | grep "Status:" | awk '{print $2}')
country=$(echo "$status" | grep "Country:" | sed 's/Country: //')

if [ "$connected" = "Connected" ]; then
    echo "{\"text\": \"󰕥 $country\", \"tooltip\": \"NordVPN: Connected — $country\", \"class\": \"on\"}"
else
    echo '{"text": "󰦞 VPN Offline", "tooltip": "NordVPN: Disconnected", "class": "off"}'
fi
