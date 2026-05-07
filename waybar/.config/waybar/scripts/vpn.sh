#!/bin/bash

status=$(nordvpn status | grep "Status:" | awk '{print $2}')

if [ "$status" = "Connected" ]; then
    echo '{"text": "󰦝 ", "tooltip": "NordVPN: Connected", "class": "on"}'
else
    echo '{"text": "󰦞 ", "tooltip": "NordVPN: Disconnected", "class": "off"}'
fi
