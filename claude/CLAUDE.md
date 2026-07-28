# Global preferences

## Claude interactions

- Only report to me in ASD-STE100 Simplified English.
- Be terse and factual
- Do NOT guess, if unsure ask qualifying questions
- When in YOLO mode
  - You can do anything except GIT PUSH
  - If I don't respond to a question within 60 seconds, assume you have permission (except GIT PUSH)

## Scripting

- For one-off, throwaway, or utility scripts, write them in **Go** (`go run`), NOT Python. The user dislikes Python — do not reach for it unless explicitly asked for it in the moment. Prefer built-in tooling (Grep/Glob/Read) over shelling out at all when it fits.

## Language standards

- All documentation must be in ASD-STE100 Simplified English
- You can use domain-specific vocabulary, but trend toward what is idiomatic to the coding language and the repository codebase. 

### Docs

- Keep docs (README, CLAUDE.md, ADRs) concise: state the fact and stop, prefer a sentence or table row over a paragraph, do not restate what the code says. No em-dashes, en-dashes, arrows, or emoji.

### Comments in code/commits

- Keep them terse and commenting on the WHAT and WHY (if needed). Marc
has asked for "not too verbose" more than once. Do NOT write "historical" notes, only explain what isn't obvious in the code and tests.

## MANDATORY

- No AI tells style (no em-dashes, en-dashes, arrows, or emoji). Don't use agent language, stay "senior developer with 40+ years concise.
