# dotfiles

Global Claude Code configuration for dev containers.

VS Code clones this repo into every dev container and runs `install.sh`. No change to any
`devcontainer.json` is necessary. This is the only mechanism that reaches containers in
upstream repositories.

## Install

Add to VS Code user `settings.json`:

```json
"dotfiles.repository": "https://github.com/IDisposable/dotfiles",
"dotfiles.targetPath": "~/dotfiles",
"dotfiles.installCommand": "~/dotfiles/install.sh"
```

## Contents

| Path | Purpose |
| --- | --- |
| `claude/CLAUDE.md` | Global preferences. Path independent |
| `claude/settings.json` | Permissions, plugins, effort level. Copied verbatim from the host |
| `install.sh` | Copies both files to `$HOME/.claude`. Runs in the container |
| `sync.sh` | Copies both files from the host back into this repo. Runs on the WSL host |

`install.sh` copies. It does not symlink. A container appends permission rules to
`settings.json` under `dontAsk` mode, and a symlink would write that container specific
churn back into this repo.

## What this repo does not carry

| Item | Reason |
| --- | --- |
| `.credentials.json` | A secret. Never put it in git. See Authentication |
| `plugins/` | Holds absolute paths. Each container rebuilds its own cache |
| `projects/`, `sessions/`, `history.jsonl` | Machine state |
| `transcripts/` | Needs a bind mount. See Mounts |

The Windows paths in `settings.json` stay in the file. They do not exist in a Linux
container, so they are inert. `Read(/home/**)` and `Read(/workspaces/**)` cover the
container home directory and the workspace.

## Authentication

VS Code has no user level setting for mounts. See
[vscode#265651](https://github.com/microsoft/vscode/issues/265651), closed as not planned,
and [vscode-remote-release#10088](https://github.com/microsoft/vscode-remote-release/issues/10088),
open. A mount is therefore possible only in a repository you control.

| Repository | Method |
| --- | --- |
| Yours | Bind mount `.credentials.json`. See Mounts |
| Upstream | Interactive login in each container |

## Mounts

For repositories you control, add to `.devcontainer/devcontainer.json`.

Windows host, VS Code started on Windows:

```json
"mounts": [
  "source=${localEnv:USERPROFILE}/.claude/.credentials.json,target=/home/vscode/.claude/.credentials.json,type=bind",
  "source=${localEnv:USERPROFILE}/.claude/transcripts,target=/home/vscode/.claude/transcripts,type=bind"
]
```

WSL host, VS Code started through Remote WSL:

```json
"mounts": [
  "source=${localEnv:HOME}/.claude/.credentials.json,target=/home/vscode/.claude/.credentials.json,type=bind",
  "source=${localEnv:HOME}/.claude/transcripts,target=/home/vscode/.claude/transcripts,type=bind"
]
```

Set the target to the home directory of the container user. `remoteUser` is `vscode` in
most images, but not all.

## Limits

A symbolic link does not cross a container boundary. A link is an inode that holds a
target string, and the container resolves that string in its own file system. A link on
the WSL host that points to `/mnt/c/...` is therefore broken inside a container.

`install.sh` must keep LF line endings. `.gitattributes` enforces this. With CRLF the
shebang becomes `#!/bin/sh\r` and every container fails to run the script.

Plugins listed in `enabledPlugins` are fetched on first run. A container without network
access cannot install them.

A read only credential mount blocks OAuth token refresh. Mount it read write, or expect
the session to fail when the token expires.
