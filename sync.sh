#!/bin/sh
# Refreshes the repo copy from the live config on the WSL host.
# Host only. These paths do not exist inside a container.
set -eu

src="/mnt/c/Users/idisp/.claude"
dest="$(CDPATH= cd -- "$(dirname -- "$0")/claude" && pwd)"

cp "$src/CLAUDE.md" "$dest/CLAUDE.md"
cp "$src/settings.json" "$dest/settings.json"

echo "claude: synced repo copy from $src"
