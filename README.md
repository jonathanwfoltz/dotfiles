# dotfiles

Personal configuration, one GNU stow package per tool at the repository root.

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
| `<Leader>al` | **a**dd **l**abel for the current branch |
| `<Leader>rl` | **r**emove **l**abel for the current branch |
| `<Leader>vl` | **v**iew files **l**abelled with the current branch |
| `<Leader>lf` | **l**ist **f**iles (explorer) |
| `<Leader>gb` | **g**it **b**lame (`:vert Git blame`, scroll-bound to the source) |
| `<Leader>tw` | **t**rim trailing **w**hitespace |

Window and buffer movement: `<C-h/j/k/l>` between windows, `<S-h>`/`<S-l>` to
cycle buffers, and `<C-z>` plus `h/j/k/l` to resize — the horizontal keys change
width and the vertical keys change height, matching tmux's `H/J/K/L`.

LSP uses Neovim's built-in mappings rather than redefining them: `grn` rename,
`gra` code action, `grr` references, `gri` implementation, `gO` symbols, `K`
hover, `<C-s>` signature help. Only `gd` (definition) is added, since it has no
default.

### Languages

LSP, formatting and treesitter parsers are configured for TypeScript/TSX, Python,
Go, HTML and CSS, plus Tailwind, C/C++ and Lua. The `servers` list in
`lua/plugins/lsp.lua` is the complete set: mason-lspconfig's `automatic_enable`
is off, so an unrelated server left in mason's install directory is not quietly
started. Formatting is
[conform.nvim](https://github.com/stevearc/conform.nvim) and expects `prettierd`,
`ruff` and `gofmt` on `PATH`, falling back to the language server where no
formatter is configured. ESLint arrives as a language server rather than a
separate linter, so it needs nothing on `PATH` and only attaches in a project
that has an eslint config.

`nvim-treesitter` tracks its `main` branch, which compiles parsers locally with
`tree-sitter-cli` and attaches per buffer from a `FileType` autocmd. The old
`master` branch is frozen at Neovim 0.11 and is not usable here.

Git blame and per-buffer HEAD tracking come from `mini.git`, which ships with
mini.nvim — no separate blame plugin.

Completion is Neovim's own: `'autocomplete'` drives the insert-mode menu and
`vim.lsp.completion` feeds it LSP items through the omnifunc source. No
completion plugin is installed.

## tmux

Requires **tmux 3.2 or newer**: `~/.config/tmux/tmux.conf` joined the default
config search path in 3.1 (so the config needs no `-f` and no
`$XDG_CONFIG_HOME` to be found) and `terminal-features` arrived in 3.2.

```
tmux/.config/tmux/
├── tmux.conf        prefix, vi copy mode, split/pane/window bindings
└── sessions/
    └── server.sh    attach to the "server" session, creating it if absent
```

Prefix is `C-f` (`C-b` is unbound; `C-f C-f` sends a literal `C-f`). Copy mode
uses vi bindings. All of the below are after the prefix:

| Key | Action |
| --- | --- |
| `-` | new pane below, in the current pane's directory |
| `\|` | new pane to the right, same |
| `h` `j` `k` `l` | move between panes (repeatable) |
| `H` `J` `K` `L` | resize the pane one cell (repeatable) |
| `C-h` / `C-l` | previous / next window (`n` and `p` are unbound) |
| `Tab` | last window |

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
