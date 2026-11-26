# Headless Neovim config check: can CI prove the config loads cleanly?

Researched 2026-11-26. Question: can a non-interactive run of
`nvim/.config/nvim` (Neovim >= 0.12, `vim.pack` + `nvim-pack-lock.json`,
`init.lua` pcall-loop over `lua/plugins/*.lua`, `MiniMisc.safely('later', ...)`
bodies, mason installs) install plugins at the locked revisions and fail with a
non-zero exit when anything reports an error? Also: lint tooling (stylua,
shellcheck) and getting Neovim >= 0.12 on GitHub Actions.

**Short answer: yes, with three gaps.** A `--cmd`-sourced harness that wraps
`vim.notify` and `vim.api.nvim_echo`, appends a sentinel to the end of the
`safely('later')` queue, and then calls `:cquit` was run against a scratch copy of
this config on Neovim v0.12.6. It caught every kind of injected failure. The gaps:

1. A bad lockfile revision is not reported by `vim.pack` itself.
2. Mason's package installs are not exercised.
3. Nothing triggered only by `FileType` or `LspAttach` runs unless the check opens files.

## How confident each part is

| Source | Method | Confidence |
|---|---|---|
| `vim.pack` behaviour | Read `runtime/lua/vim/pack.lua` from the official v0.12.6 Linux tarball, then ran it | **High**: read the source and ran it |
| `MiniMisc.safely` | Read `lua/mini/misc.lua` at the locked mini.nvim rev `9ee72c2` | **High**: source plus test runs |
| mason / mason-lspconfig / mason-nvim-dap | Read the source at the locked revs (`2a6940a`, `e17625c`, `9a10e09`) | **High** |
| Harness | Ran with an isolated `XDG_*` against a scratch copy of the config. The repo was not touched. | **High** for the cases tried (listed below) |
| Ubuntu packages | Read `Packages.xz` for `noble` and `resolute`, `main` + `universe`, from `archive.ubuntu.com` | **High** |
| Debian / Arch packages | `packages.debian.org`, `archlinux.org` and every mirror tried were blocked by this session's network policy. The versions come from search snippets of those pages. | **Medium** |
| stylua | Upstream README and `Cargo.toml` at tag `v2.6.0`, plus crates.io and npm registry metadata | **High** for the docs. I could not run the binary: the session's permission policy denied executing it, so stylua's actual diff on this repo was not measured. |
| GitHub Actions | The two actions' READMEs and source at HEAD. Checked the Neovim release asset URLs with HTTP status. | **High** |

## 1. Does `vim.pack` install at the lockfile revisions when headless?

**Yes.** I verified it with a fresh `XDG_DATA_HOME`. All 15 plugins were installed,
and `git rev-parse HEAD` in every
`$XDG_DATA_HOME/nvim/site/pack/core/opt/<name>` matched `rev` in
`nvim-pack-lock.json`. The lockfile was byte-identical afterwards. A cold run
took about 6 s.

Why it works (source: `runtime/lua/vim/pack.lua`, v0.12.6):

- The module docs say: "all plugins from the lockfile will be installed at once
  and at lockfile's revision (instead of inferring from `version`). This is done
  on the very first `vim.pack` function call" (lines 21-24). In this config that
  first call is `require('core.pack')({ mini.nvim })` in `init.lua`. Plugins
  that are only `add`ed inside `'later'` bodies are therefore already on disk
  before those bodies run.
- `M.add` passes `opts.confirm` to `lock_read`, which calls
  `lock_sync(confirm, ...)` and then `install_list(..., confirm)`.
  `confirm_install` would call `vim.fn.confirm()`. `core/pack.lua` passes
  `confirm = false`, so no prompt can block a headless run (lines 561-585,
  706-729, 953-967, 1016).
- `install_list` sets `sha_target` from the lockfile `rev` ("Prefer revision
  from the lockfile instead of using `version`"), then runs
  `git checkout <rev>` (lines 717-721, 687).
- The progress reporter only skips `redraw` when `#nvim_list_uis() == 0`
  (lines 497-508). Progress still goes to stderr through `nvim_echo`.

Caveats:

- **A bad or missing revision fails silently at the `vim.pack` level.** I set
  `tokyonight.nvim`'s rev to `000…0` and ran the install. `vim.pack` printed no
  error. The plugin directory was left containing only `.git`, with no worktree,
  and the only failure was the downstream
  `Colorscheme tokyonight-night not found`. The cause is in `lock_sync`: its
  install errors land in `p.info.err` on plug objects that nothing reports. Only
  `M.add` raises its own plugins' errors (lines 1046-1063). The safeguard is an
  explicit post-run check that each plugin's `HEAD` equals the lockfile rev
  (see the script below).
- **No revision check on cached plugins.** The `M.add` docs say: "If plugin is
  already present on disk, there are no checks about its current revision"
  (around lines 990-995). A CI cache of `XDG_DATA_HOME` would hide lockfile
  changes. Either don't cache it, or key the cache on
  `hashFiles('**/nvim-pack-lock.json')`.
- **Lockfile drift.** `lock_write()` rewrites `nvim-pack-lock.json` when a
  spec's `version` differs from the lockfile or a new plugin is installed
  (lines 1027-1037). Running `git diff --exit-code -- nvim-pack-lock.json` after
  the check catches a spec added without updating the lockfile.
- `git` is required (`git_ensure_exec`). Clones use `--filter=blob:none` with
  git >= 2.27 (lines 268-290). Clones need `github.com` to be reachable.
- Side finding (not tested further): the `PackChanged` autocmd in
  `plugins/treesitter.lua` is created inside a `'later'` body. On a fresh clone,
  every plugin is installed by the first `vim.pack` call in `init.lua`, before
  that autocmd exists, so its `update()` never fires for the initial install.
  `ts.install(parsers)` covers that case anyway.

## 2. Capturing `vim.notify` errors and exiting non-zero

Facts from the sources:

- **`--cmd` runs before `init.lua`** ("{command} will be executed before
  processing any vimrc file", `:h --cmd`). Overriding `vim.notify` there also
  catches `init.lua`'s own pcall loop.
- **`MiniMisc.safely` reports at WARN, not ERROR.** `H.execute_now` calls
  `H.notify('Error during safe execution: ' .. err .. trace, 'WARN')`, which is
  `vim.notify('(mini.misc) ' .. msg, vim.log.levels.WARN)`. The threshold must
  therefore be `>= WARN` (`misc.lua` lines 360-366, 928).
- **`'later'` is a FIFO queue.** The first `safely('later')` calls
  `vim.schedule(H.execute_later)`. Each callback is then popped from
  `H.safely_cache.later` and run on a 1 ms libuv timer, one after another
  (`misc.lua` lines 313-316, 370-386). The queue is private, but a sentinel
  queued with `safely('later', ...)` from `VimEnter` runs after every body that
  `init.lua` queued. Only `'now'` and `'later'` are used in this config (checked
  with grep).
- **Async work inside `'later'` bodies outlives the queue.** Examples are
  `ts.install(parsers)`, which is async (nvim-treesitter README: "this function
  runs asynchronously … you need to `wait()`"), and mason's registry refresh.
  The sentinel therefore defers `finish()` by a grace period.
- **Not everything goes through `vim.notify`.** nvim-treesitter's logger calls
  `nvim_echo({{msg, 'ErrorMsg'}}, true, {})` with no `err` flag
  (`lua/nvim-treesitter/log.lua` lines 71-75). The harness also wraps
  `vim.api.nvim_echo` and flags `ErrorMsg`/`WarningMsg` chunks or `opts.err`.
  The logger captures `nvim_echo` at require time, which is after `--cmd`, so
  the wrapper is in place. Bare errors from `vim.schedule` callbacks set
  `v:errmsg`.

Results with the harness below, against a scratch copy of the config:

| Injected failure | Caught by | Exit |
|---|---|---|
| none (treesitter.lua removed to avoid sandbox network noise) | — | 0 |
| syntax error in a `plugins/*.lua` | `vim.notify` ERROR from the init.lua pcall loop | 1 |
| `error()` inside `safely('later')` | `(mini.misc) Error during safe execution` WARN | 1 |
| `vim.cmd('nonexistentcmd')` inside `safely('later')` | same (E492) | 1 |
| `:echoerr` at plugin top level | pcall loop | 1 |
| `vim.schedule(function() error() end)` | `v:errmsg` | 1 |
| treesitter parser download failing | `nvim_echo` ErrorMsg wrapper | 1 |
| bad lockfile rev | only indirectly (colorscheme WARN); see §1 | 1 |

`--headless` alone does not exit, and the `finish()` path always quits. A hard
timeout (`CHECK_TIMEOUT_MS`) turns a hang, such as an unexpected prompt, into a
failure.

### Recommended harness (tested on v0.12.6)

`scripts/nvim-check.lua`: keep it outside the `nvim/` stow package so it is
not symlinked into `~/.config/nvim`.

```lua
-- Sourced with --cmd, i.e. BEFORE init.lua. Fails on any WARN+ notify, any
-- ErrorMsg/WarningMsg echo, or v:errmsg, after the 'later' queue drains.
local problems = {}
local orig_notify = vim.notify
vim.notify = function(msg, level, opts)
  if (level or vim.log.levels.INFO) >= vim.log.levels.WARN then
    table.insert(problems, tostring(msg))
  end
  return orig_notify(msg, level, opts)
end

-- nvim-treesitter's logger echoes with ErrorMsg and no `err` flag.
local bad_hl = { ErrorMsg = true, WarningMsg = true }
local orig_echo = vim.api.nvim_echo
vim.api.nvim_echo = function(chunks, history, opts)
  local flagged = opts and opts.err
  local text = {}
  for _, c in ipairs(chunks) do
    table.insert(text, c[1])
    if bad_hl[c[2]] then flagged = true end
  end
  if flagged then table.insert(problems, 'echo: ' .. table.concat(text)) end
  return orig_echo(chunks, history, opts)
end

local function finish()
  if vim.v.errmsg ~= '' then
    table.insert(problems, 'v:errmsg: ' .. vim.v.errmsg)
  end
  if #problems == 0 then
    io.stdout:write('config-check: OK\n')
    vim.cmd('qall!')
  else
    io.stderr:write('config-check: FAILED\n' .. table.concat(problems, '\n---\n') .. '\n')
    vim.cmd('cquit 1')
  end
end

vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    local grace = tonumber(vim.env.CHECK_GRACE_MS) or 3000
    local ok, misc = pcall(require, 'mini.misc')
    if not ok then
      table.insert(problems, 'mini.misc not loadable: ' .. misc)
      return finish()
    end
    -- FIFO: every 'later' queued while sourcing init.lua runs before this.
    misc.safely('later', function() vim.defer_fn(finish, grace) end)
  end,
})

-- Hard cap so a hang (e.g. a prompt) fails instead of blocking CI forever.
vim.defer_fn(function()
  table.insert(problems, 'timeout')
  finish()
end, tonumber(vim.env.CHECK_TIMEOUT_MS) or 300000)
```

Driver, run from the repo root:

```sh
#!/bin/sh
set -eu
root=$(pwd)
tmp=$(mktemp -d)
# Config straight from the checkout; everything Neovim writes goes to $tmp.
export XDG_CONFIG_HOME="$root/nvim/.config"
export XDG_DATA_HOME="$tmp/data" XDG_STATE_HOME="$tmp/state" XDG_CACHE_HOME="$tmp/cache"

nvim --headless --cmd "luafile $root/scripts/nvim-check.lua"

# vim.pack does not report a failed checkout of a locked rev (see section 1).
lock="$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json"
opt="$XDG_DATA_HOME/nvim/site/pack/core/opt"
nvim --headless --clean -l /dev/stdin "$lock" "$opt" <<'EOF'
local lock = vim.json.decode(table.concat(vim.fn.readfile(_G.arg[1]), '\n'))
local bad = 0
for name, d in pairs(lock.plugins) do
  local head = vim.trim(vim.fn.system({ 'git', '-C', _G.arg[2] .. '/' .. name, 'rev-parse', 'HEAD' }))
  if head ~= d.rev then print(('%s: HEAD %s ~= lock %s'):format(name, head, d.rev)); bad = 1 end
end
os.exit(bad)
EOF

# A spec added without updating the lockfile makes vim.pack rewrite it.
git diff --exit-code -- "$lock"
```

`nvim -l` passes script arguments in `_G.arg` (`:h -l`). I tested the
rev-check snippet on v0.12.6. It exits 0 on the clean install and exits 1 with
`tokyonight.nvim: HEAD cdc07ac… ~= lock 0000…` when given a lockfile with a
corrupted rev.

Set `CHECK_GRACE_MS` high enough for async parser builds, or have the
treesitter body `:wait()` when headless. In CI, the treesitter body needs
`tree-sitter-cli` >= 0.26.1 and a C compiler (nvim-treesitter `main` README,
"Requirements": "installed via your package manager, **not npm**"). Without
them, its ErrorMsg echoes fail the check. That is correct behaviour, but you
must decide whether CI provides those tools or treats parsers as out of scope.

## 3. What does mason skipping headless installs leave untested?

The premise is only half true at the locked revisions:

- **mason-lspconfig skips.** `setup()` refreshes the registry, then runs
  `ensure_installed` only `if not platform.is_headless`
  (`mason-lspconfig/init.lua` line 31). `is_headless` is
  `#vim.api.nvim_list_uis() == 0` (`mason-core/platform.lua` line 38).
- **mason-nvim-dap does NOT skip.** `setup()` calls `ensure_installed()`
  whenever the list is non-empty, with no headless check
  (`mason-nvim-dap/init.lua` lines 78-80). That function refreshes the registry
  and calls `pkg:install()` asynchronously for each missing package
  (`ensure_installed.lua`). The comment in `plugins/debug.lua` ("ensure_installed
  is skipped when headless") is therefore wrong. A headless CI run will start
  downloading codelldb and debugpy in the background, racing the grace period.
  In this sandbox the registry fetch failed (`wget` blocked), and the failure
  went only to `$XDG_STATE_HOME/nvim/mason.log`, not to `vim.notify`. Mason's
  network failures are therefore invisible to the harness either way. Options:
  guard the list with `#vim.api.nvim_list_uis() > 0` in `debug.lua`, or accept
  the noise.

Left untested by a startup check:

- That the mason package names (`pyright`, `ruff`, `clangd`, `neocmake`,
  `lua_ls`, `codelldb`, `python`→`debugpy`) resolve and install on this platform.
- That LSP servers start and attach: `vim.lsp.enable` only registers configs.
  Servers start on `FileType`, so `lsp/pyright.lua`, `lsp/ruff.lua`, the
  `LspAttach` keymaps, inlay hints, `vim.lsp.completion.enable` and the clangd
  mapping never run without a buffer of the right filetype and an installed
  server.
- DAP: the codelldb adapter is resolved with `exepath()` and needs the binary.
  The debugpy path is built from `install_root_dir`, so it is computed but never
  exercised.
- The treesitter `FileType` autocmd (`vim.treesitter.start`, folds, indentexpr).

If you want to cover these, mason has a blocking headless path. `:MasonInstall`
runs `a.run_blocking` and does `1cq` if any package name is invalid
(`mason/api/command.lua` lines 50-57). A second CI step could run
`nvim --headless -c 'MasonInstall pyright ruff clangd neocmake lua-language-server codelldb debugpy' -c q`.
Then open fixture files, e.g. `nvim --headless --cmd 'luafile …' t.py`, and
assert `#vim.lsp.get_clients() > 0` before `finish()`. I did not run this here
because mason could not reach GitHub from this sandbox.

## 4. stylua and shellcheck availability; stylua.toml

| Tool | Arch | Debian 13 trixie (stable) | Ubuntu 24.04 noble | Ubuntu 26.04 resolute | Upstream |
|---|---|---|---|---|---|
| shellcheck | 0.11.0 (`extra`) [medium] | 0.10.0-1; 0.11.0 in trixie-backports [medium] | 0.9.0-1 (`universe`) [high] | 0.11.0-2 (`universe`) [high] | 0.11.0; PyPI `shellcheck-py` 0.11.0.1 |
| stylua | 2.x in `extra` (snippets show 2.1.0 to 2.4.1) [medium] | **not found** [medium: no package page found] | **not packaged** (absent from main/universe) [high] | **not packaged** [high] | v2.6.0 (git tag, crates.io, npm `@johnnymorganz/stylua-bin` 2.6.0) |

- shellcheck is usable everywhere. 0.9.0 on noble is old but handles the one
  script in the repo (`tmux/.config/tmux/sessions/server.sh`, `#!/bin/sh`).
  Pin the version in CI for reproducibility.
- stylua is only reliably available from upstream. Use the GitHub release zip,
  `cargo install stylua`, or `npm i -g @johnnymorganz/stylua-bin`. On Actions
  the common route is `JohnnyMorganz/stylua-action` (not researched here). Pin
  the version.

**A `stylua.toml` is needed.** Per the StyLua README ("Finding the
configuration"), StyLua uses `stylua.toml`/`.stylua.toml` first and falls back
to `.editorconfig` only when neither exists. The `editorconfig` feature is in
the default features (`Cargo.toml` `default = ["editorconfig", …]`), so
`.editorconfig` alone would give 2-space indentation. It would not fix quotes:
the default `quote_style` is `AutoPreferDouble`. The existing Lua is
overwhelmingly single-quoted (about 377 lines with `'` against 9 with `"`, most
of those in a nested `"…"` inside a single-quoted string). StyLua would rewrite
nearly every string. Once a `stylua.toml` exists, `.editorconfig` is ignored,
so it must restate the indentation:

```toml
column_width = 100   # no Lua line in the repo exceeds 100 columns; default is 120
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferSingle"
call_parentheses = "Always"   # default; the code already uses parens
```

`column_width` is a judgement call, since `.editorconfig` sets no
`max_line_length`. Run `stylua --check .` once and review the diff before
adopting it. I could not run it here (see the confidence table), so other
reflows, such as collapsed multi-line `vim.keymap.set` calls, are unmeasured.

## 5. Neovim >= 0.12 on GitHub Actions

- **`rhysd/action-setup-vim@v1`** (latest tag v1.6.1, last commit 2026-06-28)
  is maintained. Use `with: { neovim: true, version: v0.12.6 }` (or `stable`).
  On Linux it downloads the release asset and picks `nvim-linux-x86_64` /
  `nvim-linux-arm64` for >= 0.10.4 (`src/neovim.ts` lines 95-115). It exposes
  `nvim` on PATH and an `executable` output. Prefer a pinned `vX.Y.Z` over
  `stable` so a new release can't change the result.
- **`MunifTanjim/setup-neovim-action`** is unmaintained: last commit
  2022-07-18, v1.1.0. Its `setup.sh` hardcodes `nvim-${platform}.tar.gz` with
  `platform="linux64"`. For v0.12.6 that asset returns **404**; only
  `nvim-linux-x86_64.tar.gz` exists. Do not use it.
- An alternative with no action at all is to `curl` the release tarball
  `https://github.com/neovim/neovim/releases/download/v0.12.6/nvim-linux-x86_64.tar.gz`
  (200 OK) and add `nvim-linux-x86_64/bin` to `$GITHUB_PATH`. That is what this
  research did. Latest 0.12.x tag on 2026-11-26: v0.12.6.

## Sources

- Neovim v0.12.6 release tarball: `runtime/lua/vim/pack.lua`, `runtime/doc/starting.txt` (`--cmd`); https://github.com/neovim/neovim/releases/tag/v0.12.6
- mini.nvim `lua/mini/misc.lua` @ 9ee72c26: https://github.com/nvim-mini/mini.nvim/blob/9ee72c26ac1440ee6c95ce708c1d739684be316a/lua/mini/misc.lua
- mason.nvim @ 2a6940a (`lua/mason-core/platform.lua`, `lua/mason/api/command.lua`): https://github.com/mason-org/mason.nvim
- mason-lspconfig.nvim @ e17625c (`lua/mason-lspconfig/init.lua`): https://github.com/mason-org/mason-lspconfig.nvim
- mason-nvim-dap.nvim @ 9a10e09 (`lua/mason-nvim-dap/init.lua`, `ensure_installed.lua`): https://github.com/jay-babu/mason-nvim-dap.nvim
- nvim-treesitter `main` README and `lua/nvim-treesitter/log.lua` (as installed from the lockfile): https://github.com/nvim-treesitter/nvim-treesitter/tree/main
- StyLua v2.6.0 README and Cargo.toml: https://github.com/JohnnyMorganz/StyLua/blob/v2.6.0/README.md
- crates.io `stylua`; npm `@johnnymorganz/stylua-bin`; PyPI `shellcheck-py`
- Ubuntu archive indexes: http://archive.ubuntu.com/ubuntu/dists/{noble,resolute}/universe/binary-amd64/Packages.xz
- Debian (search snippets, medium): https://tracker.debian.org/pkg/shellcheck, https://packages.debian.org/sv/trixie/amd64/shellcheck, https://dyn.manpages.debian.org/trixie/shellcheck/shellcheck.1.en.html
- Arch (search snippets, medium): https://archlinux.org/packages/extra/x86_64/shellcheck/, https://archlinux.org/packages/extra/x86_64/stylua, https://www.archlinux.de/packages/x86_64/stylua
- rhysd/action-setup-vim README and `src/neovim.ts`: https://github.com/rhysd/action-setup-vim
- MunifTanjim/setup-neovim-action `setup.sh`: https://github.com/MunifTanjim/setup-neovim-action

## Tested scripts

The harness and lockfile revision check exactly as tested are kept beside this
file: [`headless-nvim-check/check.lua`](headless-nvim-check/check.lua) and
[`headless-nvim-check/revcheck.lua`](headless-nvim-check/revcheck.lua). The
`scripts/` paths above are the proposed home if verification adopts them.
