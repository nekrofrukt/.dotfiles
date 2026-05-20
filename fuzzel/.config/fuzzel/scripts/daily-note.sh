#!/bin/bash

#fuzzel --dmenu --lines=0 --prompt="Note: " | xargs -I {} sh -c 'obsidian daily:append content="$(printf "%s" "$1")"' _ {}

#obsidian template:insert name=time

note=$(fuzzel --dmenu --lines=0 --prompt="Note: ")

[ -n "$note" ] && \
obsidian daily:append content="$(printf -- "%s" "$note")" && \
obsidian daily:append content="$(printf -- " ")"
