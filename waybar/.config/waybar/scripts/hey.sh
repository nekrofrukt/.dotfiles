#!/bin/bash
creds="$HOME/.config/hey-cli/credentials.json"
since=$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)
token=$(python3 -c "import json; print(json.load(open('$creds'))['https://app.hey.com']['access_token'])")
unseen=$(curl -s -H "Authorization: Bearer $token" \
  "https://app.hey.com/imbox.json?updated_since=$since" |
  python3 -c "import sys,json; r=json.load(sys.stdin); print('1' if any(not p.get('seen', True) for p in r.get('postings',[])) else '0')")

if [ "$unseen" = "1" ]; then
    echo '{"text":"","class":"unread"}'
else
    exit 1
fi
