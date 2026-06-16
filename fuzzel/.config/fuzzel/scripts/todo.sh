#!/bin/bash

#fuzzel --dmenu --lines=0 --prompt="Todo: " | xargs -I {} sh -c 'hey todo add "$(printf -- "%s" "$1")"' _ {}
fuzzel --dmenu --lines=0 --prompt="Todo: " | hey todo add
