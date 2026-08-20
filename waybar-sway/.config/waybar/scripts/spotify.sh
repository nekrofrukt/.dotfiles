#!/usr/bin/env python3

import subprocess
import json
import sys

try:
    result = subprocess.run(
        ["spotify_player", "get", "key", "playback"],
        capture_output=True, text=True, timeout=5,
    )
    if result.returncode != 0:
        sys.exit(0)
    playback = json.loads(result.stdout)
except (subprocess.TimeoutExpired, json.JSONDecodeError, FileNotFoundError):
    sys.exit(0)

is_playing = playback.get("is_playing", False)
track = playback.get("item", {}).get("name", "")
artists = ", ".join(a["name"] for a in playback.get("item", {}).get("artists", []))

if not track or not is_playing:
    sys.exit(0)

tooltip = f"{track} • {artists}"
album = playback.get("item", {}).get("album", {}).get("name", "")
if album:
    tooltip += f"\n{album}"

print(json.dumps({"text": f"{artists} • {track}", "tooltip": tooltip}))
