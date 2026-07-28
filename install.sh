#!/bin/sh
# Installs the global Claude Code config into $HOME/.claude.
# Runs as dotfiles.installCommand in every dev container.
# POSIX sh only: /bin/sh is dash in Debian and Ubuntu images.
set -eu

here="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
dest="$HOME/.claude"

mkdir -p "$dest"

# Symlink, so an edit to the clone in this container applies without a re-run.
ln -sf "$here/.claude/CLAUDE.md" "$dest/CLAUDE.md"
echo "claude: linked $dest/CLAUDE.md -> $here/.claude/CLAUDE.md"

# ln -sfn is GNU only. Remove first, so busybox ln does not put the link inside the directory.
if [ -d "$here/.claude/rules" ]; then
  if [ -L "$dest/rules" ] || [ ! -e "$dest/rules" ]; then
    rm -f "$dest/rules"
    ln -s "$here/.claude/rules" "$dest/rules"
    echo "claude: linked $dest/rules -> $here/.claude/rules"
  else
    echo "claude: kept existing $dest/rules"
  fi
fi

# Copy, do not symlink. Container permission churn must not write back to the repo.
if [ -f "$dest/settings.json" ]; then
  echo "claude: kept existing $dest/settings.json"
else
  cp "$here/.claude/settings.json" "$dest/settings.json"
  echo "claude: seeded $dest/settings.json"
fi
