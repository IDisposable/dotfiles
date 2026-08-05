#!/bin/sh
# Refreshes the repo copy from the live config on the WSL host.
# Host only. These paths do not exist inside a container.
# Override the Windows path with WIN_CLAUDE=/mnt/c/Users/<name>/.claude
set -eu

src="${WIN_CLAUDE:-/mnt/c/Users/idisp/.claude}"
dest="$(CDPATH= cd -- "$(dirname -- "$0")/.claude" && pwd)"

if [ ! -d "$src" ]; then
	echo "error: $src not found. Is the Windows drive mounted?" >&2
	exit 1
fi

cp "$src/CLAUDE.md" "$dest/CLAUDE.md"
echo "claude: synced CLAUDE.md from $src"

# Mirror, not merge, so a rule deleted on the host also leaves the repo.
if [ -d "$src/rules" ]; then
	rm -rf "$dest/rules"
	cp -R "$src/rules" "$dest/rules"
	echo "claude: synced rules/ from $src"
fi

# The repo copy seeds Linux containers, so drop what only resolves on this host:
# additionalDirectories, any allow rule holding a WSL mount or a Windows drive letter,
# and any marketplace that reads a local directory, with the plugins it serves.
if ! command -v jq >/dev/null 2>&1; then
	echo "warn: jq not found. settings.json unchanged. Install jq, or edit it by hand." >&2
	exit 0
fi

# Outside the repo, so a failed jq leaves nothing behind.
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

jq '
	del(.permissions.additionalDirectories)
	| .permissions.allow |= map(select(test("/mnt/|//[a-zA-Z]/|[a-zA-Z]:\\\\") | not))
	| [(.extraKnownMarketplaces // {}) | to_entries[] | select(.value.source.source == "directory") | .key] as $local
	| .extraKnownMarketplaces |= with_entries(select(.value.source.source != "directory"))
	| .enabledPlugins |= with_entries(select((.key | split("@") | last) as $m | ($local | index($m)) == null))
' "$src/settings.json" > "$tmp"
cp "$tmp" "$dest/settings.json"

echo "claude: synced settings.json from $src, host paths and local marketplaces removed"
