# dotfiles

Personal configuration, one GNU stow package per tool at the repository root.

## Prerequisites

Clone, install the list below, then `stow`. There is no bootstrap script: the
packages are symlinks and the plugins install themselves.

```sh
# Arch
pacman -S stow git tmux ripgrep base-devel nodejs npm python python-pip \
          curl unzip neovim tree-sitter-cli

# Debian / Ubuntu
apt install stow git tmux ripgrep build-essential nodejs npm python3 \
            python3-venv python3-pip curl unzip
```

| | why |
| --- | --- |
| `stow`, `git` | the install itself, and `vim.pack` clones over git |
| `tmux` ≥ 3.2 | `terminal-features`; `~/.config/tmux/tmux.conf` is searched from 3.1 |
| Neovim ≥ 0.12 | `vim.pack`, native `lsp/`, `'autocomplete'` — the config refuses to load below this |
| `tree-sitter-cli` ≥ 0.26.1 + a C compiler | nvim-treesitter's `main` branch compiles parsers locally |
| `ripgrep` | the pickers; optional, they fall back to `git` then `vim.fs.dir` |
| `nodejs`, `npm` | mason installs **pyright** from npm |
| `python3` + venv/pip | mason installs **debugpy** and **cmakelang** from PyPI |
| `curl`, `unzip` | mason installs clangd, codelldb, lua-language-server, neocmakelsp and ruff from GitHub releases |

**Two of these are not in Debian's or Ubuntu's repositories**, and are the ones
worth checking before blaming the config:

- **Neovim 0.12** — the distribution version is older. Use
  `ppa:neovim-ppa/unstable`, the appimage, or build from source. On an older
  Neovim this config prints one line saying so and loads nothing.
- **`tree-sitter-cli`** — `cargo install tree-sitter-cli` or
  `npm install -g tree-sitter-cli`. Without it nvim-treesitter cannot build a
  parser, and highlighting falls back to regex syntax.

Everything else arrives on its own: `vim.pack` installs the plugins at the
revisions in `nvim-pack-lock.json`, and mason installs the servers, formatters
and debug adapters on the first *interactive* `nvim` (it skips that work when
headless, by design) — watch it with `:Mason`. codelldb and debugpy register
with nvim-dap on the launch after they land.

One requirement is not a package on this machine at all: the **terminal font**
must be a Nerd Font or otherwise Powerline-patched, since the status line and
Neovim's file icons are drawn with private-use glyphs. That belongs to whatever
terminal you connect *from*.

## Install

Each package holds the paths it installs, relative to `$HOME` — so the nvim
package is `nvim/.config/nvim/`. `.stowrc` already sets `--target=~`, so from
the repository root a tool is linked by name and no install script is needed:

```sh
stow nvim
```

That creates `~/.config/nvim` as a single symlink to `nvim/.config/nvim`, so
files added to the repository later show up without re-stowing. `stow -D nvim`
removes the link; `stow -R nvim` replaces it.

Adding another tool means creating the package with the same shape and stowing
it the same way — `git/.config/git/`, or `bash/.bashrc` for something that
belongs at `$HOME` rather than under `~/.config`.

## nvim

Requires **Neovim 0.12 or newer**, plus `tree-sitter-cli` 0.26.1+ and a C
compiler for treesitter parsers. Plugins are managed by Neovim's built-in
[`vim.pack`](https://neovim.io/doc/user/pack.html) — nothing to bootstrap and
nothing to install by hand. Revisions are recorded in
`nvim/.config/nvim/nvim-pack-lock.json`, which is tracked; update with
`:lua vim.pack.update()`, review the diff buffer it opens, then `:write` to
accept or `:quit` to discard.

```
nvim/.config/nvim/
├── init.lua              leader → core → mini.nvim → load every plugin file
├── nvim-pack-lock.json   plugin revisions, written by vim.pack
├── lsp/                  per-server settings, read natively by Neovim
└── lua/
    ├── core/             options, keymaps and the vim.pack wrapper
    └── plugins/          one feature per file, loaded automatically
```

### Conventions

**One feature per file under `lua/plugins/`.** Each file owns everything about
that feature: its `vim.pack.add`, its `setup`, its keymaps, its autocmds, and
any option that exists only to serve it. Folding lives in `treesitter.lua` and
`completeopt` in `completion.lua` for that reason — not in `core/options.lua`,
where they would break if the plugin failed to load.

**Files are loaded by directory scan, not by a list.** `init.lua` reads every
`.lua` file in `lua/plugins/` and requires it. Adding a plugin is creating one
file; deleting one is removing it. A configured plugin can never be silently
left unloaded, which is a mistake this config has made before.

**Load order is irrelevant.** Files schedule their own work with
`MiniMisc.safely('later', …)`, or `'now'` for the two that affect first paint
(`colorscheme.lua`, `statusline.lua`). Nothing may depend on the alphabetical
order of the scan, and nothing may rely on another file having set a `Mini*`
global — use the value returned by `require('mini.extra')` instead.

**Keymaps live with the feature they drive**, use `vim.keymap.set`, and always
carry a `desc`. The descriptions are the documentation: `<Leader>pk` lists every
mapping.

**Comments mark the exceptional only.** A comment earns its place if removing it
invites a regression — it says why a setting has to be the value it is, sitting
on that setting, and nothing more. It is then tagged `NOTE:` or `HACK:` so
hipatterns highlights it and `<Leader>ph` lists it. Measurements, alternatives
considered and history are not kept in the tree; `git log` is where they live.

### Keymaps

Leader is `<Space>`. Mappings are verb-first: the first letter is the action, the
second is what it acts on.

| Key | Action |
| --- | --- |
| `<Leader>pf` | **p**ick **f**iles |
| `<Leader>ps` | **p**ick **s**ource files (`./src`, git-tracked) |
| `<Leader>pt` | **p**ick **t**est files (`./test`, git-tracked) |
| `<Leader>pg` | **p**ick by live **g**rep |
| `<Leader>pd` | **p**ick **d**iagnostics |
| `<Leader>pp` | **p**ick **p**rojects (`~/projects`) |
| `<Leader>pc` | **p**ick **c**onflicted files |
| `<Leader>ph` | **p**ick **h**ipatterns (TODO/FIXME/HACK/NOTE) |
| `<Leader>pk` | **p**ick **k**eymaps |
| `<Leader>pC` | **p**ick **C**ommands — every Ex command, built-in and user |
| `<Leader>pb` | **p**ick **b**uffers |
| `<Leader>pr` | **p**ick **r**esume — reopen the last picker |
| `<Leader>pw` | **p**ick **w**orkspace symbols (LSP, whole project) |
| `<Leader>pH` | **p**ick git **H**unks across the repository |
| `<Leader>al` | **a**dd **l**abel for the current branch |
| `<Leader>rl` | **r**emove **l**abel for the current branch |
| `<Leader>vl` | **v**iew files **l**abelled with the current branch |
| `<Leader>vd` | **v**iew the **d**iff overlay for the buffer |
| `<Leader>vr` | **v**iew **r**ecently visited files |
| `<Leader>vu` | **v**iew the **u**ndo tree (`:Undotree`) |
| `<Leader>lf` | **l**ist **f**iles (explorer) |
| `<Leader>gb` | **g**it **b**lame (`:vert Git blame`, scroll-bound to the source) |
| `<Leader>tw` | **t**rim trailing **w**hitespace |
| `<Leader>sh` | **s**witch between source and **h**eader (clangd buffers) |
| `<Leader>sf` | **s**witch **f**ormat on save on or off |
| `<Leader>vi` | **v**iew **i**nlay hints (toggle, where the server has them) |
| `<Leader>cb` | **c**lose the **b**uffer, keeping the window layout |
| `<Leader>fb` | **f**ormat the **b**uffer, or just the selection in visual mode |
| `<Leader>js` | **j**ump to a **s**pot anywhere on screen |
| `<Leader>db` | **d**ebug: toggle **b**reakpoint |
| `<Leader>dc` | **d**ebug: **c**ontinue, which starts a session |
| `<Leader>dn` | **d**ebug: **n**ext (step over) |
| `<Leader>di` | **d**ebug: step **i**nto |
| `<Leader>do` | **d**ebug: step **o**ut |
| `<Leader>dt` | **d**ebug: nearest **t**est (Python) |
| `<Leader>du` | **d**ebug: toggle the **U**I |
| `<Leader>dq` | **d**ebug: **q**uit the session |

Window and buffer movement: `<C-h/j/k/l>` between windows, `<S-h>`/`<S-l>` to
cycle buffers, and `<C-z>` plus `h/j/k/l` to resize — the horizontal keys change
width and the vertical keys change height, matching tmux's `H/J/K/L`.

Typing a prefix and pausing opens a **clue window** listing what follows it —
mini.clue, in `plugins/clue.lua`, reading the `desc` every mapping carries. It
needs no keymap of its own: the triggers are the prefixes. `<Space>` lists the
twelve verbs, `<Space>p` the pickers, and `gs`, `[`, `]`, `z`, `"`, `'`, `` ` ``,
`<C-w>` and `<C-z>` are covered too. There is deliberately no trigger on a bare
`g`: a quarter of its entries come from hardtime.nvim's throttled keys, which
carry no usable description and cannot be relabelled from here.

LSP uses Neovim's built-in mappings rather than redefining them: `grn` rename,
`gra` code action, `grr` references, `gri` implementation, `gO` symbols, `K`
hover, `<C-s>` signature help. Only `gd` (definition) is added, since it has no
default.

Hunks and textobjects keep their plugins' own mappings, which collide with
nothing above: `gh` applies a hunk and `gH` resets one (`gh` is also the hunk
textobject), `[h`/`]h` and `[H`/`]H` move between hunks, and mini.ai extends
`a`/`i` — `al`/`il` for the previous object, `g[`/`g]` for its edges. mini.ai's
`an`/`in` are deliberately unmapped so Neovim 0.12's incremental node selection
keeps them.

Three operators sit outside leader space too. `gs` plus `a`/`d`/`r`/`f`/`F`/`h`
adds, deletes, replaces, finds or highlights a surrounding — mini.surround is on
`gs` rather than its usual `s` so that plain `s`, substitute-character, keeps
working, at the cost of `gs` (`:sleep`). `gS` toggles an argument list between one
line and one per line. `<M-h/j/k/l>` move the current line, or the selection,
reindenting as they go.

### Languages

Python, C/C++ and CMake, plus Lua for this config. The `servers` list in
`lua/plugins/lsp.lua` — `pyright`, `ruff`, `clangd`, `neocmake`, `lua_ls` — is
the complete set: mason-lspconfig's `automatic_enable` is off, so an unrelated
server left in mason's install directory is not quietly started.

**Python** is pyright for types and ruff for linting, formatting and imports.
Both read the project's own configuration — `pyproject.toml`, `ruff.toml`,
`pyrightconfig.json` — and nothing here overrides it. `lsp/pyright.lua` points
pyright at the project interpreter, searching *upward* for a `.venv` so a uv
workspace member finds the environment at the workspace root, and stands aside
when the project declares its own. Auto-import completions are off: pyright
offers one entry per module that could export a symbol, including modules that
merely re-export it, and it has no finer filter.

**C/C++** is clangd at its defaults, which already include `--background-index`,
`--clang-tidy` and IWYU header insertion; per-project flags belong in the
project's `.clangd`. Inlay hints are on where a server provides them.

Formatting is [conform.nvim](https://github.com/stevearc/conform.nvim) on
`BufWritePre`, and **only where the project asks for it**: `ruff` for Python in a
project carrying a `[tool.ruff]` section or a `ruff.toml` — preferring the
project's own `.venv/bin/ruff` over mason's — and `clang-format` / `cmake-format`
in one that ships a `.clang-format` or `.cmake-format.*`. A project that asks for
none of them is left untouched on save, so nothing is reformatted to a default
style by accident. Everything else falls back to the language server, except
Python: ruff's language server has its formatting capability switched off so
conform is the only route, and the gate cannot be bypassed.

**Debugging** is [nvim-dap](https://github.com/mfussenegger/nvim-dap) with
nvim-dap-ui, codelldb for C/C++ and debugpy for Python, all installed by mason.
The panels open with a session and close with it; `<Leader>d*` drives it, and
`<Leader>dt` debugs the pytest/unittest test under the cursor.

`nvim-treesitter` tracks its `main` branch, which compiles parsers locally with
`tree-sitter-cli` and attaches per buffer from a `FileType` autocmd. The old
`master` branch is frozen at Neovim 0.11 and is not usable here.

Git blame and per-buffer HEAD tracking come from `mini.git`, and gutter hunk
signs from `mini.diff`; both ship with mini.nvim, so there is no separate blame
or signs plugin. `<Leader>vd` toggles mini.diff's overlay.

Diagnostics render as `virtual_lines` under the cursor's line only — the full
message, uncut, and nothing on the lines around it. `]d`/`[d` move between them,
both Neovim defaults.

The tabline is `mini.tabline`, listing the buffers `<S-h>`/`<S-l>` cycle
through. `<Leader>cb` closes one without collapsing the split it was in, which
plain `:bd` does.

The undo-history browser is Neovim's own, not a plugin: `plugins/undotree.lua`
runs `packadd nvim.undotree`, since it ships as an *opt* package and so does
nothing until loaded. With `undofile` set, history already outlived the session —
`<Leader>vu` is what makes it visible.

Completion is Neovim's own: `'autocomplete'` drives the insert-mode menu and
`vim.lsp.completion` feeds it LSP items through the omnifunc source. No
completion plugin is installed.

## tmux

Requires **tmux 3.2 or newer**: `~/.config/tmux/tmux.conf` joined the default
config search path in 3.1 (so the config needs no `-f` and no
`$XDG_CONFIG_HOME` to be found) and `terminal-features` arrived in 3.2.

```
tmux/.config/tmux/
├── tmux.conf        prefix, vi copy mode, bindings, status line
└── sessions/
    └── server.sh    attach to the "server" session, creating it if absent
```

Prefix is `C-f` (`C-b` is unbound; `C-f C-f` sends a literal `C-f`). Copy mode
uses vi bindings. All of the below are after the prefix:

| Key | Action |
| --- | --- |
| `c` | new window, in the current pane's directory |
| `-` | new pane below, in the current pane's directory |
| `\|` | new pane to the right, same |
| `h` `j` `k` `l` | move between panes (repeatable) |
| `H` `J` `K` `L` | resize the pane one cell (repeatable) |
| `C-h` / `C-l` | previous / next window (`n` and `p` are unbound) |
| `Tab` | last window |

Three options are set beyond the terminal ones below. `set-clipboard on`
(default `external`) lets a program's *own* OSC 52 through, so Neovim's `"+y`
reaches Windows' clipboard and not just copy mode's. `focus-events on` (default
off) forwards the terminal's focus reporting into the pane. `history-limit` is
50000 lines per pane, up from a default of 2000.

### Status line

Powerline-style blocks in tokyonight-night's palette, so the bar matches the
colourscheme Neovim loads: session name on the left, window list in the middle,
date, time and hostname on the right. The session block turns yellow while the
prefix is held, which is the one thing `tmux-prefix-highlight` is for. No plugin
and no plugin manager is involved — it is `status-left`, `status-right` and the
two `window-status-*-format` options, with the separators drawn by U+E0B0 and
U+E0B2, so **the terminal font must be a Nerd Font or otherwise
Powerline-patched** (the same requirement Neovim's glyph icons already impose).

The five colours are named once as `%hidden` server options (`TN_BG`,
`TN_BLOCK`, `TN_FG`, `TN_ACCENT`, `TN_ALERT`), so retheming is a five-line edit;
tmux expands `#{...}` inside style strings as well as formats.

`set -as terminal-features "*:RGB:usstyle"` is there for Neovim. tmux re-renders
24-bit colour down to the palette it credits the outer terminal with, and over
SSH that terminal is `xterm-256color`, whose terminfo advertises neither
truecolour nor styled underlines — so a truecolour colourscheme gets rounded to
the 256-colour palette and diagnostic undercurls are dropped. Declaring the two
features makes tmux pass both through untouched.

tmux reads its config only when the server starts, so editing `tmux.conf` does
not affect a running server — `tmux source-file ~/.config/tmux/tmux.conf` applies
it, or start a fresh server. `terminal-features` is read once more per client, as
it attaches, so after setting it detach and re-attach (`<prefix> d`, then
`tmux attach`) — the session and its panes survive.
