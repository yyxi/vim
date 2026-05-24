# AGENTS.md

This file records only non-obvious guidance for coding agents. Do not treat it as a repo overview or command reference.

## Critical non-obvious constraints
- Treat `manage`, `init.lua`, and `lua/yyxi/utilities/` as the source of truth for current behavior.
- Keep `manage` as a standalone Python 3 standard-library CLI. It must stay safe to run from any working directory, and runtime behavior must not depend on uv or project dependencies being present.
- uv is optional at runtime. If uv is available, only run the production sync when both production and development sync checks fail, so a usable dev-synced environment is not downgraded.
- Neovim must not clone, update, compile, or repair managed dependencies at startup. That lifecycle belongs to `manage`.
- For sources with declared `plugin.nativeBuild`, `manage` may write generated build outputs into the Git worktree only under explicitly allowed `allowedDirtyPaths`. Do not reintroduce a separate published native-runtime layer.
- Vendored plugins are checked-in, trimmed source snapshots, not install-time acquisitions. `manage install` must not fetch, copy, update, or repair them. Keep runtime code plus docs/README/LICENSE, and do not reintroduce tests/examples/CI scaffolding or commit vendored `doc/tags`.

## Known landmines and misleading patterns
- Despite repository names and paths containing “vim”, this repository supports Neovim only.
- `lazy.nvim` and `nvim-treesitter` are managed as locked local Git worktrees. Do not reintroduce lazy bootstrap cloning, do not add them back to `lazy-lock.json`, and do not create duplicate runtime checkouts under `vendor/lazy/` or a separate native-runtime directory.
- `nvim-treesitter-textobjects` is query-corpus-only here. Do not load it as a plugin; `manage` copies selected `textobjects.scm` queries for `mini.ai`.
- `tree-sitter-sql` is the current Tree-sitter released-source exception. Do not switch it back to `main` or `generate = true`; `manage` intentionally installs its released queries with a small SQL-only normalization step.

## Ask before doing
- Ask before adding any plugin or language workflow that requires runtime network access or self-installation. Also ask before introducing writes into checked-out dependency sources beyond declared `plugin.nativeBuild` outputs covered by `allowedDirtyPaths`.
- Ask before introducing any new plugin acquisition path besides checked-in vendored source or declared pinned Git worktrees.

## Task routing
- For a new plugin, keep the lazy spec in `init.lua`, put plugin setup in `lua/yyxi/plugins/`, and put reusable helpers in `lua/yyxi/utilities/`.
- Prefer local `dir` plugin specs for plugins managed by `manage`, whether they come from pinned Git worktrees or checked-in vendored sources.
- For a new language, keep filetype detection and Tree-sitter alias policy in `lua/yyxi/utilities/filetypes.lua`, keep parser/query pinning in `source-manifest.json`, prefer minimal grammar-source `files` entries that include only build-required paths, and keep parser/query sources aligned when the grammar ships its own queries or uses a released-source exception. Update the supplemental `textobjects` language allowlist only when `nvim-treesitter-textobjects` is the actual query source for that parser. Neovim should consume the managed Tree-sitter runtime rather than install anything itself.

## Maintenance note
- Remove lines from this file once the underlying constraint is enforced in code, tests, lint, CI, comments, or repository structure.
