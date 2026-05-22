# Neovim Lua development environment research

This document records the current Neovim Lua development layout and the decisions behind it. The implemented direction keeps lazy.nvim bootstrap, plugin definitions, and orchestration in `init.lua`; moves plugin setup/configuration bodies into namespaced modules under `lua/yyxi/`; runs LuaLS, Stylua, and Plenary through `manage check`; and keeps plugin dependencies in a repository-local `vendor/` directory.

## Reframed task

Goal: keep the development layout, quality workflow, and plugin dependency model aligned after the Lua refactor.

Relevant inputs:

- Current repository: `init.lua`, `lua/yyxi/utilities/dotenv.lua`, `manage`, `pyproject.toml`, `stylua.toml`, `lazy-lock.json`.
- Target runtime: Neovim 0.11.5.
- Constraints: keep `manage` standalone Python standard library code; `manage` must behave as if run from the repository directory; avoid unnecessary supply-chain expansion; keep lazy.nvim orchestration in `init.lua`; move plugin configuration into separate Lua files.
- Non-goals for this stage: expand LuaLS/Stylua checks to `init.lua`, move lazy.nvim plugin specifications out of `init.lua`, or add implicit dependency installation to `manage check`.

## Version boundary

The implementation should target Neovim 0.11.5 APIs and avoid adopting 0.12-only features.

Neovim 0.12.2 news introduces the built-in `vim.pack` plugin manager and a `:packadd` Lua package-path cache improvement for init patterns with repeated `:packadd` or `vim.pack.add()` calls. Those are useful to know, but they do not change the recommended 0.11.5 layout for this repository. The current lazy.nvim approach remains compatible with the target.

`vim.pack.add()` was also tested as a possible way to load `vendor/lazy.nvim`. It is not a fit for this layout: it manages plugins under `stdpath('data')/site/pack/core/opt`, writes `nvim-pack-lock.json`, and treats local `src` values as Git clone sources rather than arbitrary directories. Directly prepending the repo-local lazy.nvim directory to `runtimepath` remains the appropriate loading primitive.

Local check: the available `nvim` binary reports `NVIM v0.11.5`.

## First-party Lua loading semantics

Neovim Lua module loading is based on `runtimepath`, not only on Lua's normal `package.path`.

From Neovim 0.11.5 `:help lua-module-load`:

- Lua modules are searched under directories in `runtimepath` and package runtime paths.
- For `require('foo.bar')`, Neovim searches `lua/foo/bar.lua`, then `lua/foo/bar/init.lua` under each runtime directory.
- The first module found wins.
- The module result is cached in `package.loaded`; later `require()` calls do not re-run the file unless the cache is cleared.

From `:help 'runtimepath'`, `stdpath('config')` is first in the default runtime path and supports `lua/` for Lua plugins/modules. Runtime directories also support `plugin/`, `ftplugin/`, `after/`, `queries/`, `lsp/`, and other special directories. `plugin/**/*.vim` and `plugin/**/*.lua` are sourced automatically during startup; `lua/` files are not sourced automatically and are the correct place for explicitly required modules.

Startup semantics matter for tests and tooling:

- `init.lua` is loaded from `stdpath('config')/init.lua` unless `-u` or modes such as `-l` change startup.
- `nvim -l script.lua` executes Lua non-interactively, exits nonzero on Lua error, and skips user config unless `-u` is given.
- `-ll` is different: the editor is not initialized and it is closer to a worker-thread Lua environment. It should not be used for tests that need normal Neovim API behavior.

## Placement strategy

Use `lua/` for refactored modules, not `plugin/`, because the goal is explicit loading from `init.lua` or from callbacks inside lazy.nvim specs rather than automatic startup sourcing.

Current layout:

```text
init.lua
vendor/
  .gitkeep
  lazy.nvim/                # ignored; restored by manage install or bootstrap
  plenary.nvim/             # ignored; restored by manage install
lua/
  yyxi/
    plugins/
      colorscheme.lua
      completion.lua
      editing.lua
      interface.lua
      language_tools.lua
      syntax.lua
    utilities/
      dotenv.lua
      dotenv_spec.lua
      environment.lua
      environment_spec.lua
      exclusions.lua
      exclusions_spec.lua
      strings.lua
      strings_spec.lua
```

Rationale:

- `lua/yyxi/...` maps directly to `require('yyxi...')` through Neovim's runtimepath-aware loader.
- A unique top-level namespace reduces accidental module-name collisions. Top-level names such as `util`, `config`, `plugins`, or `dotenv` are legal but can collide with runtime modules from plugins because `require()` uses a global module cache and first-match search order.
- Plugin definitions should remain in `init.lua`: repository, branch, event, keys, dependencies, and lazy.nvim orchestration stay visible in one file. Plugin option tables belong in the corresponding `lua/yyxi/plugins/*.lua` setup module.
- Lua files should use underscore-separated names, including plugin modules and tests. Current concern files use names such as `language_tools.lua`, `environment_spec.lua`, and `dotenv_spec.lua`.
- Plugin setup bodies live under `lua/yyxi/plugins/` and are loaded only from the relevant lazy.nvim callback. Example: `config = function() require('yyxi.plugins.colorscheme').setup() end`. Because that `require()` is inside `config`, the module is loaded when lazy.nvim loads that plugin, not when `init.lua` is first parsed.
- Do not use `lua/yyxi/plugins/` as a lazy.nvim spec-import directory for this refactor. The folder contains plugin configuration modules, not plugin definitions. lazy.nvim can import plugin-spec modules, but that would move plugin definitions out of `init.lua`, contrary to the chosen boundary.
- Utility files should live under `lua/yyxi/utilities/` and be loaded as `require('yyxi.utilities.path')`, not as startup plugin files. The dotenv loader now lives at `lua/yyxi/utilities/dotenv.lua` and is loaded as `require('yyxi.utilities.dotenv')`.
- Co-located tests should use Plenary's `*_spec.lua` suffix, for example `dotenv_spec.lua`. This follows the Lua underscore naming convention and lets `PlenaryBustedDirectory` discover all tests without monkey-patching, symlinks, or one command per file.
- Filetype-specific code should remain in `init.lua` for now unless it is part of a plugin setup body. If it later becomes truly filetype-scoped and independent, Neovim's first-party runtime location is `ftplugin/<filetype>.lua` or `after/ftplugin/<filetype>.lua`.
- Native Neovim 0.11 LSP server configs can live in `lsp/<server>.lua`; `vim.lsp.config()` merges those configs from runtimepath. For this refactor, lazy.nvim still owns LSP orchestration in `init.lua`, while the long language tooling setup body lives under `lua/yyxi/plugins/language_tools.lua`.

## lazy.nvim structure

lazy.nvim explicitly supports splitting plugin specs across modules, but this repository should not use that feature for the first refactor because the desired boundary is different: plugin definitions stay in `init.lua`; only setup bodies move out.

Use lazy.nvim callbacks as the lazy-loading boundary:

```lua
{
  'example/plugin.nvim',
  event = 'VeryLazy',
  config = function()
    require('yyxi.plugins.example_plugin').setup()
  end,
}
```

For consistency, avoid lazy.nvim `opts` in `init.lua`. Put plugin option tables in `lua/yyxi/plugins/<plugin>.lua` and expose a single `setup()` entrypoint. Avoid top-level `local cfg = require(...)` in `init.lua`, because that eagerly loads the module during startup.

lazy.nvim recommends `opts` over manual `config = function() require(...).setup(...) end` when possible. In this repository, the chosen local convention is different: keep lazy.nvim orchestration in `init.lua`, and keep all plugin setup details, including option tables, in namespaced setup modules.

`folke/dot` uses a different boundary: it moves plugin specs under `lua/plugins/`. That is useful evidence for Lua module placement and utility layout, but not the chosen structure here.

## LuaLS without lazydev

`folke/neodev.nvim` is end-of-life. `folke/lazydev.nvim` was evaluated and later removed because the repository now keeps one source of LuaLS workspace truth: `.luarc.json`.

The live `lua_ls` configuration reads the same `.luarc.json` workspace libraries used by `manage check`, but only for Lua workspaces rooted inside this repository. The guard is `environment.is_path_within(root_dir, config_root)`, where `config_root` is the normalized repository root. This prevents this Neovim configuration's plugin libraries from leaking into unrelated Lua projects.

Neovim 0.11.5 already includes LuaLS metadata under the runtime, so Neovim API types come from `${env:VIMRUNTIME}/lua`. Plugin-owned public types come from the manually maintained `.luarc.json` `workspace.library` entries under `${env:HOME}/.vim/vendor/...`.

`manage` sets `VIMRUNTIME` before invoking LuaLS by asking the target `nvim` binary. This avoids hard-coding `/usr/share/nvim/runtime` and keeps the command-line check aligned with the Neovim binary under test.

LuaLS 3.18.2 supports CLI diagnosis with stdout output and a useful exit code:

```sh
lua-language-server --check=lua/yyxi --checklevel=Warning --check_format=pretty --configpath=<repo>/.luarc.json
```

With `--check_format=pretty`, diagnostics are printed to stdout. The command exits `0` when no diagnostics at or above `--checklevel` are found and exits `1` when matching diagnostics are found. `manage check` runs this command directly and uses its exit status; no log parsing is needed.

The repository `.luarc.json` includes `"runtime.version": "LuaJIT"`, `"diagnostics.disable": ["deprecated"]`, and the manually maintained plugin library paths. Relative `vendor/...` paths were tested but did not resolve plugin types reliably in LuaLS, so `${env:HOME}/.vim/vendor/...` is currently used.

## Lua type annotation strategy

Use LuaLS annotations where they improve checking or editor feedback, but avoid annotating obvious local values. Annotations are comments and have no runtime effect, so they are compatible with Neovim config loading and lazy.nvim.

Recommended defaults:

- Annotate module APIs: exported `setup()`, parser helpers, path helpers, and any function called from `init.lua`.
- Prefer plugin-owned public option types for plugin configuration tables when the plugin ships LuaLS annotations. This is the main confidence check that extracted configuration still matches the plugin API.
- Annotate project-owned option table shapes with `---@class` and `---@field` only when no upstream plugin type exists and the shape is reused or non-trivial.
- Annotate callbacks passed to Neovim APIs or plugin APIs when parameters are not obvious from the body.
- Use `---@type` for ambiguous empty tables and tables whose shape matters to LuaLS.
- Use narrow `---@diagnostic disable: ...` / `---@diagnostic enable: ...` blocks when upstream plugin types are useful but overly strict or incomplete, and document why.
- Do not create broad fake copies of plugin schemas. Prefer upstream plugin types from lazy-managed plugin libraries, targeted project-owned `---@class` declarations for local module boundaries, and `any` only at integration edges.

Example plugin module shape:

```lua
local M = {}

function M.setup()
  ---@type Flash.Config
  local opts = {
    search = {},
    modes = {},
  }

  require('flash').setup(opts)
end

return M
```

Example utility module shape:

```lua
local M = {}

---@param path string
---@return string
function M.dirname(path)
  -- implementation
end

return M
```

For lazy.nvim plugin definitions kept in `init.lua`, annotate the top-level plugin spec and lazy options tables with plugin-owned types (`LazySpec` and `LazyConfig`). Keep detailed option annotations in the extracted `plugins` and `utilities` modules, where they are stable, testable, and covered by `.luarc.json` workspace libraries.

`manage check` and `.luarc.json` include the repo-local plugin libraries whose public types are used by `lua/yyxi/plugins/*.lua`. If one of those libraries is missing under `vendor/`, `manage check` fails with `run ./manage install` instead of silently dropping type coverage or fetching plugins.

## Formatting, linting, and type checking

Current Python development checks are already documented in `pyproject.toml`:

```sh
uv run ruff format manage
uv run ruff check manage
uv run ty check manage
```

Current Lua formatting config exists in `stylua.toml`. Local tools now available on PATH: Stylua 2.5.2 and LuaLS 3.18.2-dev. CI installs Stylua 2.5.2 and LuaLS 3.18.2 into `$HOME/.local/bin` and adds that directory through `$GITHUB_PATH`, so `manage check` resolves the tools without repository-local tool shims.

Recommended `manage` interface:

```sh
./manage check          # non-mutating: Python + Lua format checks, lint/type checks, tests
./manage check --fix    # mutating: format/fix first, then type checks and tests
```

This is still one command family and avoids mixing CI-safe checks with automatic edits. The implementation can share one ordered check list:

- Python:
  - `uv run ruff format --check manage` or `uv run ruff format manage` under `--fix`.
  - `uv run ruff check manage` or `uv run ruff check --fix manage` under `--fix`.
  - `uv run ty check manage`.
- Lua check scope:
  - `stylua --check init.lua lua/yyxi` or `stylua init.lua lua/yyxi` under `--fix`.
  - `lua-language-server --check=init.lua --checklevel=Warning --check_format=pretty --configpath=<repo>/.luarc.json`, with `VIMRUNTIME` set.
  - `lua-language-server --check=lua/yyxi --checklevel=Warning --check_format=pretty --configpath=<repo>/.luarc.json`, with `VIMRUNTIME` set.
  - `PlenaryBustedDirectory`-style headless tests over `lua/yyxi/**/*_spec.lua`.
- Later full-repository scope, after non-`yyxi` Lua files are migrated or retired:
  - Expand Stylua and LuaLS checks to include any remaining first-party Lua outside `init.lua` and `lua/yyxi/`.

Supply-chain note: `manage install` must remain production-safe and must not depend on uv or development tools. Development checks may use uv and external Lua tools, but `manage` should report missing Lua tools clearly instead of installing them implicitly. That avoids hidden network fetches in a check command.

## Testing strategy for Lua with Neovim API access

Use Neovim itself as the Lua test host for tests that require `vim`, `vim.api`, runtimepath module resolution, or Neovim options. This follows first-party semantics better than running plain `lua` or external `busted` outside Neovim.

The MVP uses plenary.nvim's Busted-style harness through the lazy.nvim-managed checkout restored under `vendor/`. `manage check` resolves plenary at `<repo>/vendor/plenary.nvim`, prepends plenary and the repository to `runtimepath`, and runs `require('plenary.test_harness').test_directory('lua/yyxi', { sequential = true })` so Plenary handles test discovery and execution in one top-level command.

The sequential mode is intentional. In CI, parallel Plenary child jobs produced a timeout where one spec process never reported results while the others passed. Running specs sequentially keeps the test runner deterministic enough for this small suite and avoids hidden inter-process races.

Test files should use Busted-style globals and explicitly require luassert:

```lua
local assert = require('luassert')
local strings = require('yyxi.utilities.strings')

describe('yyxi.utilities.strings', function()
  it('trims surrounding whitespace', function()
    assert.equals('value', strings.trim('  value  '))
  end)
end)
```

Plenary's directory runner discovers only `*_spec.lua`, so this repository uses `_spec.lua` for Lua tests.

For modules under `lua/yyxi/plugins/`, unit tests can validate pure helper functions and generated option tables without loading plugins. For behavior that requires installed plugins, add a separate integration test command that first runs `Lazy! restore` and then starts Neovim with the real config. Keep that separate from fast unit checks so supply-chain and network behavior stay explicit.

External test frameworks:

- `plenary.nvim` provides a common Neovim plugin test harness and bundled luassert. It is now used for MVP tests, but it is maintenance-only upstream, so usage should stay limited to stable test-harness behavior.
- `vusted` wraps Busted for Neovim and follows the same general spec-file convention, but it adds another toolchain dependency and is not needed now.

## Supply-chain implications

The refactor should reduce, not increase, trust surface.

- Keep `lazy-lock.json` version-controlled and continue using `:Lazy restore` in install flows; lazy.nvim documents that restore uses the lockfile revisions.
- Keep plenary.nvim as an explicit lazy.nvim plugin spec because tests now depend on it directly; `manage check` fails clearly if `vendor/plenary.nvim` is missing rather than fetching it implicitly.
- Avoid implicit tool installation in `manage check`; print missing executables and installation guidance instead.
- Keep plugin checkouts under repo-local `vendor/`, with `/vendor/*` ignored and `vendor/.gitkeep` tracked.
- Bootstrap lazy.nvim separately from plugin restore. The bootstrap reads the `lazy.nvim` commit from `lazy-lock.json` and clones it with `git clone --filter=blob:none --revision=<commit>`, so the plugin manager itself is pinned to the same lockfile as the rest of the plugins.
- Prefer source-controlled configuration files (`stylua.toml`, `.luarc.json`, `pyproject.toml`, `uv.lock`, `lazy-lock.json`) over editor-local state for checks.

## Current status and remaining scope

The MVP is implemented and green:

- `.luarc.json` is the source for both command-line LuaLS checks and live `lua_ls` workspace libraries inside this repository, including lazy.nvim types for `init.lua` annotations.
- `./manage check [--fix]` normalizes cwd behavior, checks `init.lua` and `lua/yyxi`, does not install dependencies implicitly, and reports missing tools or plugin libraries clearly.
- `./manage install` performs explicit production setup with uv, pnpm, and `Lazy! restore`.
- `nvim-lua/plenary.nvim` is an explicit lazy.nvim plugin spec because tests depend on it directly.
- Plenary-based `*_spec.lua` tests live under `lua/yyxi/` and run sequentially through `manage check`.
- Utility modules under `lua/yyxi/utilities/` cover dotenv loading, environment/path concerns, exclusion lists, and string helpers.
- Plugin configuration concern files under `lua/yyxi/plugins/` cover colorscheme, completion, editing, interface, language tooling, and syntax.
- `vendor/` is the repo-local plugin checkout root. Plugin directories are ignored; `vendor/.gitkeep` is tracked.
- CI installs Neovim 0.11.5, Stylua, LuaLS, uv, pnpm, then runs `manage install` followed by `manage check`.

Remaining scope:

- Plugin definitions intentionally remain in `init.lua`; moving them into lazy.nvim import modules is out of scope unless the chosen boundary changes.
- `.luarc.json` remains manually maintained. When plugin libraries change, update both plugin usage and the workspace library list deliberately.
- Any first-party Lua outside `init.lua` and `lua/yyxi/` should either be migrated into the current layout or added deliberately to the check scope.

## Sources

- Neovim 0.11.5 `runtime/doc/lua.txt`, especially `lua-module-load`.
- Neovim 0.11.5 `runtime/doc/starting.txt`, especially `-l`, `init.lua`, startup, and plugin loading.
- Neovim 0.11.5 `runtime/doc/options.txt`, especially `runtimepath` and runtime directory meanings.
- Neovim 0.11.5 `runtime/doc/lsp.txt`, especially `vim.lsp.config()` and `lsp/*.lua` merge semantics.
- Neovim 0.12.2 `runtime/doc/news.txt` for version-boundary changes.
- lazy.nvim docs: plugin spec, structuring, and lockfile pages.
- `folke/dot` repository: `nvim/init.lua`, `nvim/lua/config/lazy.lua`, and tree structure under `nvim/lua/`.
- `folke/neodev.nvim` README and `folke/lazydev.nvim` README for the deprecated/evaluated LuaLS helper path.
- LuaLS docs: usage, configuration, settings, formatter, and type-checking pages.
