# dotfiles

Global Claude Code configuration for dev containers and WSL.

VS Code clones this repo into every dev container and runs `install.sh`. No change to any
`devcontainer.json` is necessary. This is the only mechanism that reaches containers in
upstream repositories.

## One time setup

Do these steps one time per Windows machine.

1. Send `USERPROFILE` from Windows into WSL. `host-claude-config`, `setup-wsl.sh` and
   `sync.sh` need it. Look at the stored user value first:

   ```bat
   reg query HKCU\Environment /v WSLENV
   ```

   If there is no value, set it:

   ```bat
   setx WSLENV "USERPROFILE/p"
   ```

   If there is a value, put `:USERPROFILE/p` after the value that `reg query` shows, and set
   the result with `setx`. Do not use `%WSLENV%`. Windows Terminal adds
   `WT_SESSION:WT_PROFILE_ID:` to `WSLENV` in each session it starts, so `%WSLENV%` in a
   Terminal window holds those values, and `setx` would store them as permanent values.

2. Close every Windows Terminal and VS Code window, then stop WSL. This also stops the
   running containers:

   ```bat
   wsl --shutdown
   ```

   A process gets the new value only when it starts after `setx`.

3. In a new WSL shell, confirm the value:

   ```sh
   echo "$USERPROFILE"
   ```

   It must give `/mnt/c/Users/<name>`. If it is empty, look at step 1 again.

4. In WSL, run `./setup-wsl.sh` from this repository. See [Host setup (WSL)](#host-setup-wsl).

5. After the first push of `src/`, the `Publish features` workflow publishes
   `ghcr.io/idisposable/dotfiles/host-claude-config`. A new package on ghcr is private. On
   GitHub, open Packages, then `dotfiles/host-claude-config`, then Package settings, and set
   the visibility to Public. Or run `docker login ghcr.io` in WSL.

6. Add the settings in [Install](#install) to VS Code.

## Install

Add to VS Code user `settings.json`:

```json
"dotfiles.repository": "https://github.com/IDisposable/dotfiles",
"dotfiles.targetPath": "~/dotfiles",
"dotfiles.installCommand": "install.sh"
```

The install command is relative to the clone. The CLI quotes it, so a `~` does not expand
and the step fails.

VS Code runs the install one time per container. It writes `~/.devcontainer/.dotfilesMarker`
before the install, and the marker stops each later run, also after a failure. To run it
again in an existing container, delete the marker and reopen the container, or run
`~/dotfiles/install.sh` by hand.

Add the feature that mounts the Windows `.claude`. See [Host Claude config](#host-claude-config):

```json
"dev.containers.defaultFeatures": {
  "ghcr.io/idisposable/dotfiles/host-claude-config:1": {}
}
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
| `install.sh` | Links `CLAUDE.md` and `rules/`, seeds `settings.json`, into a container local `$HOME/.claude`. Sends GitHub SSH remotes over HTTPS, and sets `gh` as the git credential helper | Container creation |
| `src/host-claude-config/` | Dev container feature. Mounts `${localEnv:USERPROFILE}/.claude` at the same path | Makes the WSL links resolve in a container |
| `.github/workflows/publish-features.yaml` | Publishes `src/` to `ghcr.io/idisposable/dotfiles` | A user level feature must be a published reference |
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
left alone. A link whose target is gone is removed and replaced.

When `~/.claude` is a mount point, `install.sh` does not change it. The
`sliekens/devcontainer-features/claude` feature bind mounts the WSL `~/.claude`, so a write
there changes the WSL config, not a container copy.

`.credentials.json` is a separate file and is never touched, so seeding does not disturb
the login.

`sync.sh` strips `additionalDirectories` and every allow rule that holds a WSL mount or a
Windows drive letter (`/mnt/c/...`, `//d/...`, `C:\...`), because they are dead config
inside a Linux container. It also drops every entry in `extraKnownMarketplaces` whose
source is a local `directory`, and each plugin in `enabledPlugins` that the entry serves,
because the path is host native and the container cannot read it. That step needs `jq`.
Without it `sync.sh` leaves `settings.json` alone and says so.

## Bundled workflows in containers

`/deep-research` is a bundled workflow, not a skill, so a `Skill(deep-research)` permission
rule does nothing. The allow list holds `Workflow` for the tool itself.

| Need | Where |
| --- | --- |
| `"disableWorkflows": false` | `.claude/settings.json` |
| `"disableBundledSkills": false` | `.claude/settings.json`. That key removes bundled workflows too |
| `WebSearch` in the allow list | `.claude/settings.json`. `/deep-research` needs the WebSearch tool |
| Claude Code v2.1.154 or later, on a paid plan | The container image. On Pro, turn Dynamic workflows on in `/config` |

`CLAUDE_CODE_DISABLE_WORKFLOWS` and `CLAUDE_CODE_DISABLE_BUNDLED_SKILLS` override the
settings file, so keep both unset in the container environment.

The first run in a new container asks for approval. In `auto` mode it asks once and records
the answer in user settings. With `bypassPermissions` and with `claude -p` it never asks.

## Host setup (WSL)

The Windows `.claude` directory is the source of truth. A WSL distribution points at it
with symbolic links, so one edit applies to both sides. Links work here because WSL and the
Windows drive are in the same file system namespace. In a container they work only with
`host-claude-config`. See [Host Claude config](#host-claude-config).

Link these five:

| Path in `~/.claude` | Target under `$USERPROFILE/.claude` |
| --- | --- |
| `CLAUDE.md` | `CLAUDE.md` |
| `settings.json` | `settings.json` |
| `settings.local.json` | `settings.local.json` |
| `rules` | `rules` |
| `transcripts` | `transcripts` |

```sh
./setup-wsl.sh
```

The scripts take `$USERPROFILE/.claude`. `USERPROFILE` comes from `WSLENV`. See
[Host Claude config](#host-claude-config). To use a different path, set `WIN_CLAUDE`:

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
| `transcripts/` | Reached through the WSL link and `host-claude-config`. See [Host Claude config](#host-claude-config) |

The seed holds container valid paths only. `Read(//home/**)` and `Read(//workspaces/**)`
cover the container home directory and the workspace.

## Host Claude config

Docker runs in WSL, so each container builds there. That is also true when VS Code opens a
Windows folder. The `sliekens/devcontainer-features/claude` feature bind mounts the WSL
`~/.claude` and `~/.claude.json` into the container. WSL and every container therefore use
one live config.

The WSL `~/.claude` holds links to `$USERPROFILE/.claude`. A container does not
mount `/mnt/c`, so without help these links do not resolve and `CLAUDE.md`, `settings.json`
and `rules/` do not load.

VS Code has no user level setting for mounts. See
[vscode#265651](https://github.com/microsoft/vscode/issues/265651), closed as not planned,
and [vscode-remote-release#10088](https://github.com/microsoft/vscode-remote-release/issues/10088),
open. A feature can declare mounts, and `dev.containers.defaultFeatures` adds a feature to
every container. `host-claude-config` uses this to mount the Windows `.claude` at its WSL
path, so the links resolve with no change to them.

The mount source and target are `${localEnv:USERPROFILE}/.claude`. `localEnv` is the
environment of the Docker host, which is WSL. WSL gets `USERPROFILE` from Windows only
through `WSLENV`, and the `/p` flag converts it to a WSL path. See
[One time setup](#one-time-setup).

| Constraint | Effect |
| --- | --- |
| `USERPROFILE` is not set in WSL | The source becomes `/.claude`, and the container does not start. Set `WSLENV`, or remove the feature from `defaultFeatures` on that machine |
| The target must equal the target of the WSL links | `setup-wsl.sh` makes links to `$USERPROFILE/.claude`. If you set `WIN_CLAUDE` to a different path, the links do not resolve in a container |
| The package on ghcr is private when first published | Make it public in the package settings, or run `docker login ghcr.io` in WSL |
| A mount applies at container creation | Rebuild an existing container to get it |

## Authentication

| Install | Login |
| --- | --- |
| Windows | Its own `.credentials.json` |
| WSL and every container | One shared `.credentials.json`, through the bind mount |

A Claude session that runs in WSL and a container at the same time can see the token
refreshed under it. If a login is lost, look for a second session first.

`gh` keeps its token in `~/.config/gh` in the container file system. A rebuild removes it.
Run `gh auth login` again after a rebuild. `install.sh` sets `gh` as the git credential
helper when `gh` is logged in at install time.

`install.sh` sends GitHub SSH remotes over HTTPS with `url.<base>.insteadOf`. A container
has no SSH key, and VS Code forwards an agent only when the host has `SSH_AUTH_SOCK` set at
container start.

## Mounts

The claude feature mounts all of `~/.claude`, so a container with it needs no other mount.
For a repository you control that does not use the feature, add to
`.devcontainer/devcontainer.json`. Docker runs in WSL, so `${localEnv:HOME}` is the WSL
home, also when VS Code starts on Windows:

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
host that points to `/mnt/c/...` is broken inside a container, unless the container mounts
that path. `host-claude-config` mounts it.

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
