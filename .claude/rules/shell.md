---
paths:
  - "**/*.sh"
---

# Shell scripts

These apply when the shebang is `#!/bin/sh`. Debian and Ubuntu link `/bin/sh` to dash, so
bash syntax fails in a container even though it passes on a machine where `sh` is bash.
Use `#!/bin/bash` if you need bash, and then these limits do not apply.

- Use `$0` to find the script.
- `set -eu` only.
- Prefix `cd` with `CDPATH=`, so a `CDPATH` in the environment cannot redirect it.
- Use `command -v`, not `which`.
- No arrays, no `[[ ]]`, no `function` keyword, no `${var,,}`.
- `ln -n`, `sed -i` and `grep -P` are GNU extensions. Busybox and BSD differ.
- Keep LF line endings. A CRLF shebang makes the kernel fail to run the file.
