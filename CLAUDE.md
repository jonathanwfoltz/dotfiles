# CLAUDE.md

Notes for future sessions in this repo. `README.md` documents the config for a
human reader; this file records *why* things are the way they are, what has
already been decided, and what is still outstanding.

## What this repo is

Personal dotfiles, one GNU stow package per tool at the root: `nvim/` and
`tmux/`. There is no install script to maintain: `stow <tool>` from the
repository root is the whole install.

**A package holds the paths it installs, relative to `$HOME`** — hence
`nvim/.config/nvim/`, not `nvim/`. This is not decoration. Stow maps a package's
*contents* onto the target, so the `stow --target="$HOME/.config" nvim` that this
file used to document — back when the package was a bare `nvim/` — actually
linked that `nvim/init.lua` to `~/.config/init.lua` and scattered `lua/`, `lsp/`
and the lockfile loose into `~/.config`. It was never correct. `.stowrc` at the
root sets `--target=~` and `--dir=.`, which is why the command needs no flags;
stow only reads `.stowrc` from the current directory, so run it from the
repository root. Targeting `$HOME` is also what lets a future
package install something outside `~/.config` (`bash/.bashrc`).

Stow's tree folding means `~/.config/nvim` is a **single symlink** to
`nvim/.config/nvim`, not a directory of per-file links, so files added to the
repository appear without re-stowing — and files Neovim writes into its config
directory land in the repository, which is what `.gitignore` covers (`spell/`,
`.luarc.json`). `stow -D nvim` unlinks, `stow -R nvim` relinks.

**This repo is now what Neovim loads.** The previous `~/.config/nvim` — a
separate vim-plug/telescope-era clone of `git@github.com:Foltz124/nvim-config.git` — was
moved aside to `~/.config/nvim.bak` and, on 2026-10-11, deleted at Jon's word.
Its three uncommitted edits went with it (a trailing-whitespace fix in
`lua/general/options.lua`, `lua/plugins/gitsigns.lua` emptied out, and a small
`lua/plugins/telescope.lua` tweak); the config itself is still on GitHub.

## History

The original config (then at `nvim/`) was 18 files / 378 lines, committed as
`cd96202`. A single
restructure commit (`c217c7d`, on branch `restructure-nvim-config`, not yet merged
to `main`) rewrote it around one feature per file. The motivating defect: adding a
plugin required editing three files, and `lua/plugins/linting.lua` had been left
out of `lua/plugins/init.lua`, so nvim-lint was silently dead.

## Conventions that must be preserved

- **One feature per file in `nvim/.config/nvim/lua/plugins/`.** A file owns
  everything about its feature: `vim.pack.add`, `setup`, keymaps, autocmds, and any option that
  exists only to serve it. This is why folding lives in `treesitter.lua` and
  `completeopt` in `completion.lua` rather than in `core/options.lua`.
- **Files are loaded by directory scan, not a list.** The package's `init.lua`
  reads every `.lua` in `lua/plugins/` and requires it. Never reintroduce a manual roster —
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
`l`ist `f`iles; `g`it `b`lame; `t`rim `w`hitespace.

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
- **`lua/core/pack.lua` exists only to set `confirm = false`.** `vim.pack.add`
  prompts for approval on first install by default, which blocks any unattended or
  headless launch — including the verification recipe below — and adds nothing when
  the plugin list is this repository, reviewed in git. Plugin files do
  `local add = require('core.pack')`, keeping the same shape the old
  `local add = MiniDeps.add` line had. Everything else stays at the `vim.pack`
  defaults, notably `load`: false while `init.lua` is sourcing, true afterwards,
  which is why `require('mini.misc')` at the top of each plugin file works.
- **The lockfile is `nvim/.config/nvim/nvim-pack-lock.json`** and is meant to be
  tracked (upstream: "treat lockfile like its part: put under version control").
  It replaced `mini-deps-snap`. Despite what this file claimed, `git ls-files`
  showed it was never actually added — and it is not in `.gitignore` either, so
  nothing was suppressing it. The copy on disk is now generated against the real
  stowed config rather than a throwaway environment, so it is the one to commit.
- **nvim-treesitter tracks `main`.** The `master` branch is frozen at Neovim 0.11
  (last commit 2026-03-23); `main` needs 0.12 and `tree-sitter-cli` >= 0.26.1,
  which it shells out to in order to compile parsers locally. `main` is a
  different, lower-level plugin: no `configs.setup`, no `highlight`/`indent`
  tables. Highlighting, folding and indentation attach per buffer from a
  `FileType` autocmd, so folding is now window-local rather than a global that
  also applied to parserless buffers. `lua`, `c` and `cpp` are in the filetype
  list: Neovim bundles the `lua` and `c` parsers and `$VIMRUNTIME/ftplugin/lua.lua`
  starts treesitter itself, so Lua had highlighting but no treesitter folds or
  indentation until the autocmd covered it. Installing `cpp` pulls a local `c`
  grammar in alongside, the way `tsx` pulls in `ecma` and `jsx`.
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
  `pack/deps/` tree was dead weight and has been removed.
- **`automatic_enable = false` is what makes the `servers` list mean something.**
  mason-lspconfig v2 defaults it to *true*, and `features/automatic_enable.lua`'s
  `init()` then calls `vim.lsp.enable` for every installed mason package that maps
  to an lspconfig name — not just `ensure_installed`. That is how `clangd`,
  `lua_ls`, `cmake` and `lemminx`, all leftovers from the old config, were being
  started on every launch with nothing in this repo mentioning them, and it made
  `vim.lsp.enable(servers)` close to a no-op. Worse, it was not reproducible: on a
  fresh clone `lua-language-server` is not installed, so editing this config would
  have had no LSP at all. With it off, `servers` is the whole set. `lua_ls` and
  `clangd` are now declared there rather than inherited, which is also why
  `.gitignore` carries `.luarc.json` — lua_ls writes it. The remaining mason
  packages (`cmakelang`, `cpplint`, `pylint`, `pyink`, `lemminx`,
  `cmake-language-server`, `clang-format`) are now inert rather than silently
  live; they are left installed.
- **Per-server LSP settings live in the package's `lsp/<server>.lua`**, which
  Neovim reads natively and merges over nvim-lspconfig's defaults. Only servers with real
  settings get a file (`ts_ls`, `pyright`); the rest are just listed in
  `vim.lsp.enable`. Do not add empty files for the others.
- **`pyright` resolves `.venv/bin/python` against the LSP root** via `before_init`,
  not against the cwd Neovim started in, which is what the original did.
- **ESLint is a language server, not a linter plugin.** `plugins/lint.lua` and
  nvim-lint are gone: the file configured exactly one linter, and half of it was
  a hand-written `available()` guard suppressing nvim-lint's hard error per
  missing binary. `eslint` is now just another entry in the `servers` list in
  `plugins/lsp.lua` — it is both the mason-lspconfig package name and the
  nvim-lspconfig server name, so no `lsp/eslint.lua` is needed. The guard
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
- **mini.indentscope draws a solid `│`.** Its default `symbol` is the dashed
  `╎`, which reads as a dotted guide; `plugins/ui.lua` passes `'│'`.
- **mini.trailspace gets a keymap, because `setup()` alone only highlights.**
  `trim()` is the half that acts, and conform covers nothing outside
  ts/tsx/python/go, so the highlight was permanent everywhere else. `<Leader>tw`
  (verb-first: `t`rim `w`hitespace) calls it.
- **The `<C-z>` resize keys follow their own direction.** They used to be `h`/`j`
  for height and `k`/`l` for width, so the two vertical keys resized
  horizontally — and `tmux.conf`'s `H`/`J`/`K`/`L` already got this right, so the
  same four letters meant different things in the two programs. The right-hand
  sides of `h` and `k` were swapped; `j` and `l` were already correct. Raised
  under the "mnemonic describes the wrong behaviour" exception, and it renames no
  key.
- **`'complete'` does not cap the omnifunc source.** `0.12`'s `{flag}^{limit}`
  syntax caps a source's matches, and `o^5` capped the *LSP* at five items with
  `pumheight` at 10. The word sources keep their `^5`; `o` does not.
- **`core/options.lua` holds no option that restates a default.** Six were
  dropped after checking each against `nvim --clean`: `backup`, `conceallevel`,
  `hlsearch`, `timeoutlen`, `guifont` (no effect in a terminal) and
  `fileencoding` (buffer-local, so setting it through `vim.opt` at startup only
  ever reached the first buffer). `smartindent` went too, for a different reason:
  filetype indent is on by default and any filetype with an `indentexpr` ignores
  it — including every filetype in the treesitter list — so it only ever applied
  where its C-flavoured guesses are wrong. Check the same way before adding one back.
- **`termguicolors = true` is back, and is not a restated default.** It was
  dropped as "auto-enabled when the terminal supports it", which is not true
  under tmux: probed inside a real pane with `TERM=tmux-256color` and no
  `COLORTERM`, Neovim's own detection settles on `false`. The cost is not just
  256-colour rounding — with it off, Neovim emits the diagnostic undercurl
  (`\033[4:3m`) and no `\033[58…` underline colour at all, so squiggles render
  colourless next to a cterm-coloured sign. The only reason detection ever
  succeeds here is that tmux exports `COLORTERM=truecolor` into panes *because*
  of the `RGB` terminal-feature in `tmux.conf`, so leaving this to detection
  silently couples Neovim's colours to that one tmux line and to pane age.
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
- **`plugins/swagger.lua` must pass a table to `setup`.** swagger-preview's
  `M.setup(config)` indexes its argument unconditionally, so a bare `setup()`
  raised `attempt to index local 'config' (a nil value)` on every startup —
  caught by `MiniMisc.safely` and reported, but the module was left
  unconfigured. `setup({})` it is, even though port 8000 and host localhost are
  upstream's own defaults.
- **swagger-preview needs `npm install` in its plugin directory.** It shells out
  to `node_modules/.bin/swagger-ui-watcher`, which its repository does not ship;
  upstream's install instructions carry a build step, and `vim.pack` has no build
  hook to run one. So after any install or update of that plugin:
  `(cd ~/.local/share/nvim/site/pack/core/opt/swagger-preview.nvim && npm install)`.
  Nothing in Neovim reports this — `:SwaggerPreview` just fails to start a server.
  It has been run for the current install (`node_modules/.bin/swagger-ui-watcher`
  is present), so this is a standing instruction, not an outstanding action.

## tmux

**This repo is also what tmux loads.** The old `~/.config/tmux/` was moved aside
to `~/.config/tmux.bak` and `stow tmux` put a single symlink in its place.
Nothing was lost: its `tmux.conf` was byte-identical to the one committed here,
and its `sessions/` directory was already empty — a previous session had moved
the script into the repo before crashing. `tmux.bak` was deleted on 2026-10-11.

That previous session left the package in the wrong shape (`tmux/tmux.conf`,
`tmux/sessions/`), which `stow tmux` would have linked to `~/tmux.conf` and
`~/sessions`. It is now `tmux/.config/tmux/…` like every other package.

- **`sessions/server.sh` passes no `-f`.** tmux's built-in search path is
  `/etc/tmux.conf:~/.tmux.conf:$XDG_CONFIG_HOME/tmux/tmux.conf:~/.config/tmux/tmux.conf`
  (checked against the tmux 3.8 binary; neither of the first two exists here and
  `XDG_CONFIG_HOME` is unset), so the `-f ~/.config/tmux/tmux.conf` the script
  used to carry loaded exactly the file tmux finds anyway. Do not re-add it.
  The script also gained a `#!/bin/sh` — it had none, despite being `+x` — and
  `exec`, so no shell is parked around tmux for the session's lifetime.
- **It was `sessions/serverSession.sh` creating a session named `jonSession`**
  (and this file recorded the filename as `jonSession.sh`, which it never was).
  Both are now `server`.
- **`tmux.conf` is deliberately near-irreducible.** Every `bind` is
  load-bearing and `unbind C-b` / `unbind n` / `unbind p` each remove a real
  default — do not "tidy" them away. The one cleanup made was
  `set-window-option -g mode-keys vi` → `setw -g mode-keys vi`, matching the
  `set -g` / `bind` short forms used everywhere else in the file.
- **`set -as terminal-features "*:RGB:usstyle"` is why Neovim's colours survive.**
  Without it tmux rewrote nvim's 24-bit SGR to the nearest 256-colour entry and
  dropped styled underlines entirely — measured on the wire, not guessed: with a
  pty client on `TERM=xterm-256color`, `\033[38;2;122;162;247m` reached the
  client as `\033[38;5;111m` and both `\033[4:3m` (undercurl) and `\033[58:2:…`
  (underline colour) vanished; with the line, all three arrive byte-identical.
  The cause is that tmux downsamples to whatever palette it credits the *outer*
  terminal with, and `xterm-256color`'s terminfo declares neither `RGB`/`Tc` nor
  `Smulx`/`Setulc` (`tmux info | grep RGB` shows them missing). `COLORTERM` would
  have told tmux too, but this is an SSH session and sshd has no
  `AcceptEnv COLORTERM`, so it never arrives — hence declaring it in the config
  rather than relying on the environment. Neovim was not the cause of the
  *downsampling* — but this file used to claim it turns `termguicolors` on under
  tmux either way, and that is wrong: in a pane with no `COLORTERM` it settles
  on `false`, which is why the option is now set explicitly. Check this with a
  real TUI nvim in a pane, never `--headless`, which always reports `true`.
- **`terminal-features` also controls `COLORTERM` in panes.** tmux exports
  `COLORTERM=truecolor` into a pane's environment only when it credits the
  client with `RGB`, so the `terminal-features` line is also what makes Neovim's
  own truecolour detection succeed — which is why `termguicolors` is now set
  explicitly rather than relying on it.
- **The `Setulc` override is why the undercurls have a colour.** `usstyle` alone
  is not enough. tmux's built-in `usstyle` capability re-emits the underline
  colour in a five-parameter colon form, `\033[58:2:R:G:Bm`, dropping the empty
  colour-space field from the six-parameter `\033[58:2::R:G:Bm` Neovim sends.
  Windows Terminal 1.24 ignores the five-parameter form and draws the curl in
  the cell's foreground colour instead — a colourless squiggle beside a coloured
  sign, indistinguishable from `termguicolors` being off. Both ends were
  measured: the bytes leaving tmux, and `printf` of each form straight to the
  terminal outside tmux (only the six-parameter one came out red; indexed
  `\033[58:5:9m` also works and passes through tmux untouched, which is why
  that was the one form that showed colour in the original diagnosis).
  The override restores the six-parameter form. Two traps in it: a literal
  colon inside a `terminal-overrides` value is written `::`, so the six-param
  separator `::` becomes `::::`; and the value is a terminfo string, so `\E`
  needs the extra backslash tmux's double quotes consume.
- **A pane is useless for testing escape sequences.** tmux parses what a program
  writes and re-emits its *own* encoding, so `printf`ing a sequence inside a
  pane measures tmux, not the terminal — every RGB underline-colour form looked
  identical (and wrong) that way. Test the terminal from a shell outside tmux,
  and test tmux by reading the bytes it writes (recipe below).
- **`terminal-features` needs tmux 3.2**, and it is evaluated per client *at
  attach*, not only at server start. `source-file` alone leaves an attached
  client on the old features — detach and re-attach. `client_colours` is the
  quick check: `tmux display -p '#{client_colours}'` reads 16 on a client tmux
  thinks is dumb and 16777216 once RGB is credited (it never reports 256 here,
  so don't read it as a palette size).
- **`C-h`/`C-l` were swapped**, the one intentional behaviour change: `C-h` had
  been `next-window` and `C-l` `previous-window`, so each key moved opposite to
  its direction. Jon confirmed the swap.
- **Verifying a config change cannot use the running server.** tmux reads its
  config once, at server start, so `list-keys` on the attached server reports
  the *old* bindings however the file has changed. Use a throwaway socket:
  `tmux -L check -f ~/.config/tmux/tmux.conf new-session -d -s t`, inspect with
  `tmux -L check list-keys -T prefix`, then `tmux -L check kill-server`.
  `terminal-overrides` is applied per client at attach, like `terminal-features`,
  so a change to either needs a detach and re-attach (or a fresh server), not
  just `source-file`. That is
  how the bindings above were confirmed, and it never touches Jon's session.
  To check which underline-colour forms the *client* terminal honours, four
  `printf`s are enough — `\033[4:3m` plus each of `\033[58:2::255:0:0m`
  (six-param colon, Neovim's and now tmux's), `\033[58:2:255:0:0m`
  (five-param, tmux's built-in), `\033[58;2;255;0;0m` (semicolon) and
  `\033[58:5:9m` (indexed). Run them **outside** tmux, from a plain SSH shell;
  a red curl means that form lands. Inside a pane the answer is meaningless.
  Anything about *colour* in the config, though, needs a real client terminal,
  since features are per client: attach one with
  `env -u COLORTERM TERM=xterm-256color script -qf wire.log -c "tmux -L check -f <conf> new-session -s t <emitter>"`,
  where `<emitter>` is a *script file* that prints the escape sequences — inline
  `printf` gets echoed into the pane and then matches your own grep — and read
  the bytes tmux sent out of `wire.log`.

## Verification recipe

Now that the repo is stowed, `nvim` with no flags *is* the real config, and the
checks below were last run that way deliberately — a throwaway environment
cannot tell you whether the live link works. For a change whose blast radius is
unclear, still build one: a temp dir with `nvim` symlinked to
`<repo>/nvim/.config/nvim`, exported as `XDG_CONFIG_HOME`, plus empty
`XDG_DATA_HOME`/`XDG_STATE_HOME`/`XDG_CACHE_HOME`. Then:

1. `nvim --headless '+qall!'` — must produce no stderr beyond install chatter.
2. Deferred plugins do **not** install on an immediate headless quit. Drive
   `MiniMisc.safely('later', …)` with a script that `vim.wait`s on the globals it expects
   (`MiniPick`, `MiniVisits`, `MiniSnippets`, …) plus a short settle, or the run
   will report false negatives.
3. Compare `ls nvim/.config/nvim/lua/plugins/*.lua` against `package.loaded` keys
   prefixed `plugins.` — the sets must match. This is the regression test for the
   original bug.
4. `checkhealth vim.deprecated` must report no deprecated functions.
5. Beware `pcall(vim.treesitter.language.add, lang)`: it succeeds even when the
   function *returns* nil, so it is not a usable guard for parser availability.
6. **A `-S` script runs before the `'later'` bodies have.** Anything that depends
   on them — the `FileType` treesitter autocmd, `vim.lsp.enable`, the `LspAttach`
   maps — is not registered yet when the script's first line executes, so opening
   a file straight away gets no highlighting, no LSP and `foldmethod=manual`, and
   it looks exactly like a broken config. Wait on the augroups first:
   `vim.wait(30000, function() return pcall(vim.api.nvim_get_autocmds, { group = 'lsp_attach' }) end, 200)`.
   This cost a false "LSP is dead" conclusion once already.
7. **mason-lspconfig skips `ensure_installed` when headless**, by design —
   `lua/mason-lspconfig/init.lua` guards it with `not platform.is_headless`. No
   server will ever install in a headless run, however long you wait, so a
   headless check cannot verify the `servers` list. Install one explicitly via
   `require('mason-registry').get_package(<mason name>):install()` and wait on its
   `'closed'` event — `is_installed()` flips true *before* the install finishes,
   and mason tears down incomplete installs on exit ("Neovim is exiting while
   packages are still installing"), so waiting on `is_installed()` loses the
   package. Mason names are not lspconfig names here (`css-lsp`, `eslint-lsp`,
   `typescript-language-server`, `tailwindcss-language-server`).
8. Assert the `LspAttach` maps against a **real attached client**, not a bare
   startup: `gd` only exists once a client attaches, which is how the
   `{ buf = … }`/`{ buffer = … }` bug below survived a "24/24 keymaps" run. A
   two-file Go module plus gopls is the cheapest way in — gopls installs in
   twenty seconds and attaches on a `go.mod` root.

Also worth knowing: `checkhealth vim.lsp` and `checkhealth vim.treesitter` exist
on 0.12, and `require('nvim-treesitter').get_installed()` is how you assert the
parser set now that `ensure_installed` is gone.

There are **15** files in `lua/plugins/` (`lint.lua` is gone), so step 3
expects 15.

Last full run (2026-10-11, on the real stowed config, Neovim 0.12.5,
tree-sitter-cli 0.26.9): 15/15 plugin files loaded, `checkhealth vim.deprecated`
clean, no stderr on startup, `complete` and the indentscope symbol as set, 11
parsers compiled (the 7 asked for plus `c`, `ecma`, `jsx`, `html_tags` as shared
grammars). The enabled server set printed exactly the nine in `servers` — no
`cmake`, no `lemminx` — and with real clients attached, `lua_ls` on an `a.lua`
and `clangd` on an `a.cpp`: `gd` buffer-local in both, treesitter highlighter
active, `foldmethod=expr` set from the `FileType` autocmd.

The 2026-10-09 run additionally confirmed every leader keymap carries a `desc`
and that `gd` jumps correctly against gopls; neither has been re-measured since.

The older pre-0.12 run (0.11.1) recorded 16/16 plugin files, 24/24 keymaps, 12/12
mini modules — kept only because the keymap and mini-module counts have not been
re-measured since.

## Outstanding

- **Branch state is editor state.** `~/.config/nvim` and `~/.config/tmux` are
  symlinks into the working tree, so `git switch`, `git stash` and
  `git checkout .` all change Jon's live editor and tmux config. `main` has been
  fast-forwarded onto `simplify-nvim-config` with `git branch -f`, which never
  checks anything out, rather than by switching to `main` and merging — the
  switch would have put the `cd96202` tree under the symlink for the duration.
  Use the same trick next time. `restructure-nvim-config` was deleted once
  contained in `main`.
- `<Leader>pk` (pick keymaps) was added without being explicitly requested; it was
  offered as optional and included anyway. Drop it if Jon does not want it
  (`lua/plugins/pick.lua`).
- Untracked configs that could move in: `clangd/`, `go/`, `yay/`,
  `mimeapps.list`. Jon said on 2026-10-11 that he does not need any of them yet,
  so do not offer again unasked. When they do move in, each becomes its own
  package in the shape `<tool>/.config/<tool>/…`, linked with `stow <tool>`.
  `mimeapps.list` is a bare file rather than a directory, so it needs a package
  name of its own — `xdg/.config/mimeapps.list`, say — since the package
  directory is never part of the installed path.
- `obsidian.nvim` was dropped (declared but never configured). `hardtime.nvim` was
  kept.
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
  against a real attached client, not a bare startup. Now verified that way
  against gopls: `gd` is mapped buffer-local and jumps correctly.
- **All nine LSP servers are installed.** `cssls`, `ts_ls`, `html`,
  `tailwindcss`, `pyright`, `eslint` and `gopls` are in
  `~/.local/share/nvim/mason/packages`, and `clangd` and `lua_ls` were already
  there from the old config — they are now declared in `servers` rather than
  arriving through `automatic_enable`. `ensure_installed` still cannot run
  headless (recipe step 7), so that remains the constraint on a fresh machine:
  the first *interactive* `nvim` is what installs them, and `:Mason` is where to
  watch it.
