#!/usr/bin/env bash
#
# hey-notify.sh — HEY email desktop notifications for GNOME
#
# Displays stacking desktop notifications for new HEY emails via notify-send.
# Clicking "Open HEY" opens ptyxis with hey tui.
#
# Requires:
#   - hey CLI (https://github.com/basecamp/hey-cli)
#   - jq
#   - notify-send (libnotify)
#   - ptyxis (GNOME terminal)
#
# Install:
#   1. Copy to ~/.local/bin/hey-notify.sh and chmod +x
#   2. Create ~/.config/systemd/user/hey-mail.service:
#
#      [Unit]
#      Description=HEY email desktop notifications
#      After=graphical-session.target
#
#      [Service]
#      Type=simple
#      ExecStart=%h/.local/bin/hey-notify.sh
#      Restart=on-failure
#      RestartSec=10
#
#      [Install]
#      WantedBy=default.target
#
#   3. Enable and start:
#      systemctl --user daemon-reload
#      systemctl --user enable --now hey-mail.service
#
# State:
#   Timestamps in ~/.cache/hey-notify-last-start to avoid duplicate
#   notifications on restart.
#
SINCE_FILE="$HOME/.cache/hey-notify-last-start"
SINCE_FLAG=""

if [ -f "$SINCE_FILE" ]; then
    SINCE_FLAG="--since $(cat "$SINCE_FILE")"
fi

hey watch --box imbox --events added --json $SINCE_FLAG | while IFS= read -r line; do
    [ -f "$SINCE_FILE" ] || date -u +%Y-%m-%dT%H:%M:%SZ > "$SINCE_FILE"

    change=$(echo "$line" | jq -r '.change // empty')
    [ "$change" = "ready" ] && continue
    [ "$change" = "disconnected" ] && continue
    [ "$change" = "deleted" ] && continue

    thread_id=$(echo "$line" | jq -r '.thread_id // empty')
    subject=$(echo "$line" | jq -r '.posting.name // "New email"')
    sender=$(echo "$line" | jq -r '.posting.alternative_sender_name // "Unknown"')

    [ -z "$thread_id" ] && continue

    (
        response=$(notify-send -a "HEY" -i "mail-unread" -A "default=Open" -- "HEY: $sender" "$subject")
        [ "$response" = "default" ] && ptyxis --new-window -- hey tui &
    ) &
done
