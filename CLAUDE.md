# CLAUDE.md

Notes for future sessions in this repo. `README.md` documents the config for a
human reader; this file records *why* things are the way they are, what has
already been decided, and what is still outstanding.

## What this repo is

Personal dotfiles, one directory per tool at the root. Only `nvim/` is tracked so
far. The layout is GNU stow compatible on purpose, so linking a tool is
`stow --target="$HOME/.config" nvim` and there is no install script to maintain.

**Nothing is linked yet.** `~/.config/nvim` is still a separate, older git repo
(`git@github.com:Foltz124/nvim-config.git`, a vim-plug/telescope-era config with
uncommitted changes). Jon scoped work to this repo only, so it was left alone.
Until it is replaced by a stow symlink, *this repo is not what Neovim loads*.

## History

The original `nvim/` was 18 files / 378 lines, committed as `cd96202`. A single
restructure commit (`c217c7d`, on branch `restructure-nvim-config`, not yet merged
to `main`) rewrote it around one feature per file. The motivating defect: adding a
plugin required editing three files, and `lua/plugins/linting.lua` had been left
out of `lua/plugins/init.lua`, so nvim-lint was silently dead.

## Conventions that must be preserved

- **One feature per file in `nvim/lua/plugins/`.** A file owns everything about
  its feature: `vim.pack.add`, `setup`, keymaps, autocmds, and any option that
  exists only to serve it. This is why folding lives in `treesitter.lua` and
  `completeopt` in `completion.lua` rather than in `core/options.lua`.
- **Files are loaded by directory scan, not a list.** `nvim/init.lua` reads every
  `.lua` in `lua/plugins/` and requires it. Never reintroduce a manual roster —
  that is the bug this structure exists to prevent.
- **Load order must stay irrelevant.** Files schedule with
  `MiniMisc.safely('later', …)`, or `'now'` only for `colorscheme.lua` and
  `statusline.lua`. Never depend on another file having set a `Mini*` global; use
  the `require()` return value. Since the mini.deps → `vim.pack` migration there
  are no `Mini*` globals left in `lua/plugins/` at all.
- **`vim.g.mapleader` is set at the top of `init.lua`**, before anything can map a
  key.
- **Keymaps: `vim.keymap.set` only, always with a `desc`.** The descriptions are
  the documentation — `<Leader>pk` lists the whole set. Keymaps live in the file
  that owns the feature they drive.

## Keymap scheme — do not reorganise

Leader is `<Space>`. Mappings are **verb-first**: first letter is the action,
second is the object. `p`ick `f`iles/`s`ource/`t`est/`g`rep/`d`iagnostics/
`p`rojects/`c`onflicts/`h`ipatterns/`k`eymaps; `a`dd/`r`emove/`v`iew `l`abel;
`l`ist `f`iles; `g`it `b`lame.

This is an intentional system, not drift. A previous session mistook it for
inconsistency and proposed reorganising into domain prefixes (`<Leader>f` = find,
etc.); Jon rejected that and asked for strong justification before any key is
renamed. Convention, consistency with other people's configs, and resemblance to
popular distributions are **not** accepted justifications. Only raise a specific
key for a concrete mechanical defect — a prefix collision that forces a
`timeoutlen` delay, two keys bound to one action, or a mnemonic that describes the
wrong behaviour — and raise it as a question about that one key.

LSP uses Neovim's built-in maps (`grn`, `gra`, `grr`, `gri`, `gO`, `K`, `<C-s>`)
rather than redefining them. Only `gd` is added, in an `LspAttach` autocmd so it
is buffer-local. The old `<Leader>g*` LSP maps and the duplicate `<Leader>ca` were
removed; `<Leader>gr` had also been a strict prefix of `<Leader>grn`, which made
references block for the full 1000ms `timeoutlen`.

## Decisions with non-obvious reasons

- **Plugins are managed by `vim.pack`, Neovim 0.12's built-in manager.** mini.deps
  development is frozen upstream, explicitly because `vim.pack` was built using it
  as the design reference. `MiniMisc.safely(when, f)` is upstream's named
  replacement for `MiniDeps.now/later` and is what every plugin file uses; mini.nvim
  is still installed (for pick, files, statusline, icons, …) so it costs nothing.
  Note the org rename: **`nvim-mini/mini.nvim`**, not `echasnovski/` — the old URL
  only redirects.
- **`nvim/lua/core/pack.lua` exists only to set `confirm = false`.** `vim.pack.add`
  prompts for approval on first install by default, which blocks any unattended or
  headless launch — including the verification recipe below — and adds nothing when
  the plugin list is this repository, reviewed in git. Plugin files do
  `local add = require('core.pack')`, keeping the same shape the old
  `local add = MiniDeps.add` line had. Everything else stays at the `vim.pack`
  defaults, notably `load`: false while `init.lua` is sourcing, true afterwards,
  which is why `require('mini.misc')` at the top of each plugin file works.
- **The lockfile is `nvim/nvim-pack-lock.json`** and is tracked on purpose
  (upstream: "treat lockfile like its part: put under version control"). It
  replaced `nvim/mini-deps-snap`. Same caveat as before: a lockfile written inside
  the throwaway verification environment pins upstream HEADs of that moment, so
  regenerate it once against the real config.
- **nvim-treesitter tracks `main`.** The `master` branch is frozen at Neovim 0.11
  (last commit 2026-03-23); `main` needs 0.12 and `tree-sitter-cli` >= 0.26.1,
  which it shells out to in order to compile parsers locally. `main` is a
  different, lower-level plugin: no `configs.setup`, no `highlight`/`indent`
  tables. Highlighting, folding and indentation attach per buffer from a
  `FileType` autocmd, so folding is now window-local rather than a global that
  also applied to parserless buffers.
- **No completion plugin.** mini.completion was dropped for 0.12's native
  `'autocomplete'`; `'complete'` includes the `o` (omnifunc) source and
  `plugins/completion.lua` owns an `LspAttach` autocmd that calls
  `vim.lsp.completion.enable(…, { autotrigger = true })`. `'completeopt'` `popup`
  supplies the documentation window mini.completion used to. This is the first
  thing to revert if the feel is wrong — mini.completion is still maintained.
- **Mason uses `mason-org/*`, not `williamboman/*`** (v2, current). On a first run
  in an environment that still has the old clones, stale `mason.nvim` /
  `mason-lspconfig.nvim` directories may point at the old remote and need
  deleting. Note the install directory moved with the manager: `vim.pack` owns
  `~/.local/share/nvim/site/pack/core/opt/` (mini.deps used `pack/deps/`), and it
  assumes everything in there is managed exclusively by it — so the old
  `pack/deps/` tree is now dead weight and can be removed wholesale.
- **Per-server LSP settings live in `nvim/lsp/<server>.lua`**, which Neovim reads
  natively and merges over nvim-lspconfig's defaults. Only servers with real
  settings get a file (`ts_ls`, `pyright`); the rest are just listed in
  `vim.lsp.enable`. Do not add empty files for the others.
- **`pyright` resolves `.venv/bin/python` against the LSP root** via `before_init`,
  not against the cwd Neovim started in, which is what the original did.
- **ESLint is a language server, not a linter plugin.** `plugins/lint.lua` and
  nvim-lint are gone: the file configured exactly one linter, and half of it was
  a hand-written `available()` guard suppressing nvim-lint's hard error per
  missing binary. `eslint` is now just another entry in the `servers` list in
  `plugins/lsp.lua` — it is both the mason-lspconfig package name and the
  nvim-lspconfig server name, so no `nvim/lsp/eslint.lua` is needed. The guard
  became unnecessary rather than shorter: the server only attaches in a project
  with an eslint config, and `vim.lsp.enable` on an uninstalled server is
  silent. `:EslintFixAll` comes along but deliberately has no keymap.
- **Git blame is `mini.git`, not blame.nvim.** mini.nvim is already installed, so
  `:vert Git blame -- %` costs nothing. A bare split scrolls independently of the
  source, which was blame.nvim's one real advantage, so `plugins/git.lua` carries
  upstream's documented `MiniGitCommandSplit` recipe to scroll-bind the two.
  mini.git also tracks HEAD per buffer, which is the point below.
- **`plugins/visits.lua` reads HEAD from mini.git**, via
  `require('mini.git').get_buf_data(0).head_name`, replacing a
  `vim.system({'git', 'rev-parse', …}):wait()` that blocked on every
  `<Leader>al`/`rl`/`vl` press. This is the **one accepted exception** to "load
  order must stay irrelevant": mini.git's tracking only runs once
  `plugins/git.lua` has called `setup()`. It is safe because these keymaps can
  only fire on user input, long after both `'later'` bodies have run, and a nil
  `head_name` already has a handled path (the same warning as before).
- **Formatting is `conform.nvim`.** formatter.nvim's last commit was 2025-05-29.
  conform ships the `prettierd`, `ruff_format` and `gofmt` definitions, so the
  inline `exe`/`args`/`stdin` tables are gone, and `format_on_save` runs on
  `BufWritePre` — the old wiring ran `:FormatWrite` from `BufWritePost`, writing
  the buffer a second time after the write that triggered it. The filetype set is
  unchanged (ts, tsx, python, go); `lsp_format = 'fallback'` covers the rest.
- **`core/options.lua` holds no option that restates a default.** Seven were
  dropped after checking each against `nvim --clean`: `backup`, `conceallevel`,
  `hlsearch`, `timeoutlen`, `termguicolors` (auto-enabled since 0.10 when the
  terminal supports it), `guifont` (no effect in a terminal) and `fileencoding`
  (buffer-local, so setting it through `vim.opt` at startup only ever reached the
  first buffer). Check the same way before adding one back.
- **The `lua/plugins/` directory scan in `init.lua` stays.** Neovim's `plugin/`
  directory would give the same "nothing can be silently left out" guarantee as a
  core mechanism, and it was evaluated and rejected: the files would become
  scripts rather than modules, so the `package.loaded` check that is this
  structure's regression test stops working; the per-file `pcall` + `vim.notify`
  is lost; and `vim.pack.add`'s `load` option silently flips from `false` to
  `true`, because `plugin/` scripts are sourced after `init.lua` finishes. That
  is behaviour change and lost testability to save twelve greppable lines. Do not
  re-propose it.
- **No `core/autocmds.lua`.** The plan called for one, but there were no
  genuinely cross-cutting autocmds; an empty file is worse than none.

## Verification recipe

Never test against the real `~/.config` or `~/.local/share`. Build a throwaway
environment instead: a temp dir with `nvim` symlinked to `<repo>/nvim`, exported
as `XDG_CONFIG_HOME`, plus empty `XDG_DATA_HOME`/`XDG_STATE_HOME`/
`XDG_CACHE_HOME`. Then:

1. `nvim --headless '+qall!'` — must produce no stderr beyond install chatter.
2. Deferred plugins do **not** install on an immediate headless quit. Drive
   `MiniMisc.safely('later', …)` with a script that `vim.wait`s on the globals it expects
   (`MiniPick`, `MiniVisits`, `MiniSnippets`, …) plus a short settle, or the run
   will report false negatives.
3. Compare `ls nvim/lua/plugins/*.lua` against `package.loaded` keys prefixed
   `plugins.` — the sets must match. This is the regression test for the original
   bug.
4. `checkhealth vim.deprecated` must report no deprecated functions.
5. Beware `pcall(vim.treesitter.language.add, lang)`: it succeeds even when the
   function *returns* nil, so it is not a usable guard for parser availability.

Also worth knowing: `checkhealth vim.lsp` and `checkhealth vim.treesitter` exist
on 0.12, and `require('nvim-treesitter').get_installed()` is how you assert the
parser set now that `ensure_installed` is gone.

There are now **15** files in `lua/plugins/` (`lint.lua` is gone), so step 3
expects 15, not the 16 the run below recorded.

Last full run (pre-0.12, on 0.11.1): 16/16 plugin files loaded, 24/24 keymaps
present with descriptions, 0 retired keymaps remaining, 12/12 mini modules set up,
all 6 treesitter parsers compiled with highlighting attaching on
TypeScript/Python/Go, no deprecations.

## Outstanding

- Merge `restructure-nvim-config` into `main` (not done — `git merge --ff-only`).
- Decide what replaces `~/.config/nvim`, and stow this repo.
- `<Leader>pk` (pick keymaps) was added without being explicitly requested; it was
  offered as optional and included anyway. Drop it if Jon does not want it
  (`nvim/lua/plugins/pick.lua`).
- Untracked configs that could move in: `~/.config/tmux/` (`tmux.conf` plus
  `sessions/jonSession.sh`), `clangd/`, `go/`, `yay/`, `mimeapps.list`.
- `obsidian.nvim` was dropped (declared but never configured). `hardtime.nvim` was
  kept.
- Regenerate `nvim/nvim-pack-lock.json` against the real config once this repo is
  stowed; whatever the verification environment wrote is throwaway HEADs.
- 0.12 also ships `:Undotree`, `:DiffTool`, `v_an`/`v_in`/`v_]n`/`v_[n`
  incremental node selection, `:restart`, `vim.net.request()`, a default
  statusline carrying diagnostics and LSP progress, and the experimental `ui2`
  message/cmdline redesign. **None of these got a keymap or an option**, on
  purpose — see the `<Leader>pk` entry above for why unrequested additions are
  unwelcome. Raise them individually if worth it.
- The `gd` mapping in `plugins/lsp.lua` had passed `{ buf = args.buf }` to
  `vim.keymap.set`, whose option is `buffer`. Unknown keys are rejected
  (`invalid key: buf`), so `gd` was never mapped and every `LspAttach` raised.
  Fixed. The "24/24 keymaps present" run recorded above did not catch it, because
  the mapping only exists once a client has attached — assert the `LspAttach` maps
  against a real attached client, not a bare startup.
