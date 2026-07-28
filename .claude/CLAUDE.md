# Global preferences

## Claude interactions

- Only report to me in ASD-STE100 Simplified English.
- Be terse and factual
- Do NOT guess, if unsure ask qualifying questions
- Do not re-flag things I manage myself once I have said I am managing them.
- When in YOLO mode
  - You can do anything except GIT PUSH
  - If I don't respond to a question within 60 seconds, assume you have permission (except GIT PUSH)

## Git

- Never `git push` and never `gh pr create`. Commit locally when asked, then stop.
- No Co-Authored-By trailer and no "generated with" footer, in commits or PR bodies.
- Wrap commit message bodies at 72 columns.

## Bash commands

- Do not chain commands with `;`, `&&`, or `|` unless ABSOLUTELY necessary. A compound command does not match a prefix permission rule, so each one appends a dead literal to the allow list. Use separate calls, or Read/Glob/Grep.

## Scripting

- For one-off, throwaway, or utility scripts, write them in **Go** (`go run`), NOT Python. The user dislikes Python. Do not reach for it unless explicitly asked for it in the moment. Prefer built-in tooling (Grep/Glob/Read) over shelling out at all when it fits.

## Language standards

- All documentation must be in ASD-STE100 Simplified English, American spelling. Word list and doc style in `rules/markdown.md`, which loads when I touch a `*.md` file.
- You can use domain-specific vocabulary, but trend toward what is idiomatic to the coding language and the repository codebase.

### Comments in code/commits

- Keep them terse and commenting on the WHAT and WHY (only if needed).
- Do NOT write "historical" notes, only explain what isn't obvious in the code and tests.

## MANDATORY

- No AI tells style (no em-dashes, en-dashes, arrows, or emoji).
- Don't use agent language, stay "senior developer with 40+ years concise.
- No Co-author in code, commit messages or PRs
