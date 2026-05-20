#!/bin/bash

fuzzel --dmenu --lines=0 --prompt="Todo: " | xargs -I {} sh -c 'obsidian daily:append content="$(printf -- "- [ ] %s" "$1")"' _ {}
