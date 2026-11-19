#!/bin/sh
# Runs as dotfiles.installCommand in every dev container.
# POSIX sh only: /bin/sh is dash in Debian and Ubuntu images.
set -eu

here="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
dest="$HOME/.claude"

# True when the directory is a mount point. A mounted ~/.claude belongs to the host
# (or to a feature), and a write here changes that config, not a container copy.
is_mount() {
  im_real="$(CDPATH= cd -P -- "$1" 2>/dev/null && pwd -P)" || return 1
  awk -v p="$im_real" '$5 == p { found = 1 } END { exit !found }' /proc/self/mountinfo 2>/dev/null
}

# Removes a symbolic link whose target is gone, so ln and cp do not fail on it.
drop_dangling() {
  if [ -L "$1" ] && [ ! -e "$1" ]; then
    rm -f "$1"
  fi
}

install_claude() {
  mkdir -p "$dest"

  if is_mount "$dest"; then
    echo "claude: $dest is a mount, left unchanged"
    return 0
  fi

  # Symlink, so an edit to the clone in this container applies without a re-run.
  drop_dangling "$dest/CLAUDE.md"
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
  drop_dangling "$dest/settings.json"
  if [ -e "$dest/settings.json" ]; then
    echo "claude: kept existing $dest/settings.json"
  else
    cp "$here/.claude/settings.json" "$dest/settings.json"
    echo "claude: seeded $dest/settings.json"
  fi
}

# Adds a value to a multi-valued global git key once.
git_add_once() {
  if ! git config --global --get-all "$1" 2>/dev/null | grep -qxF "$2"; then
    git config --global --add "$1" "$2"
  fi
}

install_git() {
  if ! command -v git >/dev/null 2>&1; then
    echo "git: not installed, skipped"
    return 0
  fi

  # A container has no SSH key, and gets an agent only when the host runs one.
  # HTTPS uses the credential helper that VS Code forwards, or gh.
  git_add_once url.https://github.com/.insteadOf git@github.com:
  git_add_once url.https://github.com/.insteadOf ssh://git@github.com/
  echo "git: GitHub SSH remotes use HTTPS"

  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    gh auth setup-git
    echo "git: gh is the credential helper for github.com"
  else
    echo "git: gh not logged in. After gh auth login, run gh auth setup-git"
  fi
}

install_claude
install_git
