#!/bin/sh

LID=/proc/acpi/button/lid/LID/state

grep -q closed "$LID" 2>/dev/null || exit 0

for c in /sys/class/drm/card*-*/status; do
    case "$c" in
        *eDP-*|*LVDS-*|*DSI-*) continue ;;
    esac
    [ "$(cat "$c" 2>/dev/null)" = "connected" ] && found=1 && break
done

[ "$found" ] || exit 0

for out in $(xrandr --query | awk '/ connected/ {print $1}'); do
    case "$out" in
        eDP-*|LVDS-*|DSI-*) xrandr --output "$out" --off ;;
    esac
done
