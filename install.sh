#!/bin/sh
# Installs the global Claude Code config into $HOME/.claude.
# Runs as dotfiles.installCommand in every dev container.
set -eu

src="$(CDPATH= cd -- "$(dirname -- "$0")/claude" && pwd)"
dest="$HOME/.claude"

mkdir -p "$dest"

# Copy, do not symlink. Container permission churn must not write back to the repo.
cp "$src/CLAUDE.md" "$dest/CLAUDE.md"
cp "$src/settings.json" "$dest/settings.json"

echo "claude: installed CLAUDE.md and settings.json to $dest"
