#!/bin/bash

fuzzel --dmenu --lines=0 --prompt="Search: " | xargs -I {} xdg-open "https://search.brave.com/search?q={}"
