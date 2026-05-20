#!/bin/bash

fuzzel --dmenu --lines=0 --prompt="Note: " | xargs -I {} sh -c 'obsidian daily:append content="$(printf "%s" "$1")"' _ {}
