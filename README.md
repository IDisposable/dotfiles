# dotfiles

Global Claude Code configuration for dev containers and WSL.

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

## Verify

In a new container, run `/context` and confirm `CLAUDE.md` appears under Memory files, or
run `/memory` to open it.

## Contents

| Path | Purpose | Why |
| ---- | ------- | --- |
| `.claude/CLAUDE.md` | Global preferences. Path independent | Loads in every project, every machine |
| `.claude/rules/` | Preferences scoped by a `paths:` glob in frontmatter | Loads only when Claude reads a matching file |
| `.claude/settings.json` | Permissions, plugins, effort level | Seeds a new container with approved defaults |
| `install.sh` | Links `CLAUDE.md` and `rules/`, seeds `settings.json`, into `$HOME/.claude` | Container creation |
| `sync.sh` | Copies the host config back into this repo | Run on the WSL host after a config change |
| `setup-wsl.sh` | Links a WSL `~/.claude` at the Windows `.claude` | Run once per distribution |
| `.gitattributes` | Forces LF | A CRLF shebang fails in every container |
| `.gitignore` | Excludes `.claude/settings.local.json` | Keeps session approvals out of the seed |

This repo carries a `.claude/` directory, so its own contents also load as project
configuration when you work on it.

## Rules

`CLAUDE.md` loads in full every session, so it must hold only what applies every session.
Anything that applies to one kind of file belongs in `.claude/rules/` with a `paths:` glob.
It loads when Claude reads a matching file and costs no context until then.

| File | Scope | Holds |
| --- | --- | --- |
| `markdown.md` | `**/*.md` | ASD-STE100, American spelling word list, doc terseness |
| `shell.md` | `**/*.sh` | POSIX sh limits. `/bin/sh` is dash in Debian and Ubuntu |

A rule with no `paths:` field loads at launch, at the same priority as `CLAUDE.md`. User
rules in `~/.claude/rules/` load before project rules, so a project rule wins.

## How each file installs

| File | Method | Constraint |
| --- | --- | --- |
| `CLAUDE.md`, `rules/` | Symlink | Claude does not write them, so a repo edit reaches the container at once |
| `settings.json` | Copy when absent | Claude writes it during a session. A symlink sends every runtime toggle back into this repo. An unconditional copy erases approvals |

A fresh container has no `~/.claude/settings.json`, so the seed lands. An existing one is
left alone.

`.credentials.json` is a separate file and is never touched, so seeding does not disturb
the login.

`sync.sh` strips `additionalDirectories` and every allow rule that holds a WSL mount or a
Windows drive letter (`/mnt/c/...`, `//d/...`, `C:\...`), because they are dead config
inside a Linux container. That step needs `jq`. Without it `sync.sh` leaves
`settings.json` alone and says so.

## Host setup (WSL)

The Windows `.claude` directory is the source of truth. A WSL distribution points at it
with symbolic links, so one edit applies to both sides. Links work here because WSL and the
Windows drive are in the same file system namespace. They do not work into a container. See
[Limits](#limits).

Link these five:

| Path in `~/.claude` | Target under `/mnt/c/Users/idisp/.claude` |
| --- | --- |
| `CLAUDE.md` | `CLAUDE.md` |
| `settings.json` | `settings.json` |
| `settings.local.json` | `settings.local.json` |
| `rules` | `rules` |
| `transcripts` | `transcripts` |

```sh
./setup-wsl.sh
```

Set `WIN_CLAUDE` if the Windows user name is different:

```sh
WIN_CLAUDE=/mnt/c/Users/<name>/.claude ./setup-wsl.sh
```

The script is safe to run more than once:

- It stops if the Windows drive is not mounted, so it cannot make a set of dead links.
- It keeps an existing real file as `<name>.bak-<date>` before it makes the link.
- It reports a correct link and makes no change.
- It uses `rmdir` for `rules` and `transcripts`, so it stops if either still holds files.
  Move them to Windows first.

Confirm with `ls -la ~/.claude`. Each of the five must show an arrow to the Windows path.

### Do not link the rest

| Path | Reason |
| --- | --- |
| `plugins/` | `installed_plugins.json` and `known_marketplaces.json` hold absolute, platform native paths. The second side to read them finds paths that do not exist. `marketplaces/` also holds git clones, and one work tree driven by two git builds conflicts |
| `projects/` | Session history and memory. The directory name encodes the project path, and that encoding differs per platform |
| `sessions/`, `session-env/`, `shell-snapshots/`, `ide/` | Live process state |
| `.credentials.json` | One token per installation. A drvfs mount reports mode 0777, so the 0600 permission is lost |
| `history.jsonl`, `file-history/` | Per machine |
| `cache/`, `debug/`, `backups/`, `downloads/` | Scratch data |

`plugins/` needs no link. Each distribution builds its own cache from `enabledPlugins` and
`extraKnownMarketplaces` in the shared `settings.json`, with paths that are correct for that
machine. That is the intended way to keep plugins the same.

Two properties of the mount matter:

- `/mnt/c` is a 9p drvfs mount. If the Windows drive is not mounted, every link dangles and
  no configuration loads at all, with no message. A real file survives that state.
- A bind mount through `mount --bind` or `wsl.conf` also works, but it needs root and gives
  no advantage over a link.

## Auto memory does not travel

Auto memory is per repository and machine local. It is not shared across machines or cloud
environments. Do not rely on it for preferences you want everywhere: those belong in
`.claude/CLAUDE.md` or `.claude/rules/`.

To make a container's auto memory survive a rebuild, point it at a mounted path with
`autoMemoryDirectory`, and mount that path in the repo's `devcontainer.json`. That is per
repo work, which is why preferences are better off in CLAUDE.md.

```json
{
  "autoMemoryDirectory": "~/persist/claude-memory"
}
```

## What this repo does not carry

| Item | Reason |
| --- | --- |
| `.credentials.json` | A secret. Never put it in git. See [Authentication](#authentication) |
| `plugins/`, `projects/`, `sessions/`, `history.jsonl` | Machine state. Same reasons as the table above |
| `transcripts/` | Needs a bind mount. See [Mounts](#mounts) |

The seed holds container valid paths only. `Read(//home/**)` and `Read(//workspaces/**)`
cover the container home directory and the workspace.

## Authentication

VS Code has no user level setting for mounts. See
[vscode#265651](https://github.com/microsoft/vscode/issues/265651), closed as not planned,
and [vscode-remote-release#10088](https://github.com/microsoft/vscode-remote-release/issues/10088),
open. A mount is therefore possible only in a repository you control.

| Repository | Method |
| --- | --- |
| Yours | Bind mount `.credentials.json`. See [Mounts](#mounts) |
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

Set the target to the home directory of the container user. `remoteUser` is `vscode` in most
images, but not all.

## Limits

A symbolic link does not cross a container boundary. A link is an inode that holds a target
string, and the container resolves that string in its own file system. A link on the WSL
host that points to `/mnt/c/...` is therefore broken inside a container.

The clone is per container, so the `CLAUDE.md` link that `install.sh` makes resolves inside
that container only. Editing the clone in one container does not reach another.

`install.sh` must keep LF line endings. `.gitattributes` enforces this. With CRLF the
shebang becomes `#!/bin/sh\r` and every container fails to run the script.

`install.sh` must stay POSIX sh. `/bin/sh` is dash in Debian and Ubuntu images, so bash
syntax such as `${BASH_SOURCE[0]}` aborts it there while it passes on a host where `sh` is
bash. See `.claude/rules/shell.md`.

Plugins listed in `enabledPlugins` are fetched on first run. A container without network
access cannot install them.

A read only credential mount blocks OAuth token refresh. Mount it read write, or expect the
session to fail when the token expires.

### Gotchas

- Permission path syntax: `//` is absolute and `/` anchors at the settings source, but
  `additionalDirectories` takes plain paths
- `~` in a container is container local, `${localEnv:HOME}` is the host, and
  `/workspaces/<repo>` is the only zero config host backed write path
- Editing `settings.json` mid session gets clobbered when the harness appends a rule
