# AGENTS.md

This file records only non-obvious guidance for coding agents. Do not treat it as a repo overview or command reference.

## General guidance for working with `manage`

### Critical non-obvious constraints
- Keep it as a standalone Python 3 standard-library CLI; production install must not depend on uv or project dependencies being available.
- `manage` may be invoked from any working directory; it must behave as if run from the directory containing the `manage` file.
- uv is optional at runtime; when available, run production sync only if both production and development sync checks fail, so a dev-synced environment is not downgraded.

### Known landmines and misleading patterns
- Despite repository names and paths containing “vim”, this installer supports Neovim only.

### Maintenance note
- Remove these lines once the constraints are enforced by tests, CI, comments near the relevant code, or repository structure.
