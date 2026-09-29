# dotfiles

Personal configuration, one directory per tool at the repository root.

## Install

The layout is GNU stow compatible, so each tool is linked by name and no install
script is needed:

```sh
stow --target="$HOME/.config" nvim
```

Adding another tool later means creating `tmux/`, `git/` and so on beside
`nvim/`, then stowing it the same way.

## nvim

Requires Neovim 0.11 or newer. Plugins are managed by
[mini.deps](https://github.com/echasnovski/mini.nvim), which `init.lua`
bootstraps on first launch — there is nothing to install by hand. Plugin
versions are pinned in `nvim/mini-deps-snap`; refresh it with `:DepsSnapSave`
after `:DepsUpdate`.

```
nvim/
├── init.lua              leader → bootstrap → core → load every plugin file
├── mini-deps-snap        pinned plugin commits
├── lsp/                  per-server settings, read natively by Neovim
└── lua/
    ├── core/             options and keymaps that belong to no plugin
    └── plugins/          one feature per file, loaded automatically
```

### Conventions

**One feature per file under `lua/plugins/`.** Each file owns everything about
that feature: its `MiniDeps.add`, its `setup`, its keymaps, its autocmds, and
any option that exists only to serve it. Folding lives in `treesitter.lua` and
`completeopt` in `completion.lua` for that reason — not in `core/options.lua`,
where they would break if the plugin failed to load.

**Files are loaded by directory scan, not by a list.** `init.lua` reads every
`.lua` file in `lua/plugins/` and requires it. Adding a plugin is creating one
file; deleting one is removing it. A configured plugin can never be silently
left unloaded, which is a mistake this config has made before.

**Load order is irrelevant.** Files schedule their own work with
`MiniDeps.later`, or `MiniDeps.now` for the two that affect first paint
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
| `<Leader>gb` | **g**it **b**lame (toggle) |

Window and buffer movement: `<C-h/j/k/l>` between windows, `<C-z>h/j/k/l` to
resize, `<S-h>`/`<S-l>` to cycle buffers.

LSP uses Neovim's built-in mappings rather than redefining them: `grn` rename,
`gra` code action, `grr` references, `gri` implementation, `gO` symbols, `K`
hover, `<C-s>` signature help. Only `gd` (definition) is added, since it has no
default.

### Languages

LSP, formatting and treesitter parsers are configured for TypeScript/TSX, Python,
Go, HTML and CSS, plus Tailwind. External tools are expected on `PATH`:
`prettierd`, `ruff`, `gofmt` and `eslint_d`. Anything missing is skipped rather
than reported as an error on every buffer.

`nvim-treesitter` is pinned to its `master` branch on purpose: the `main` branch
calls `vim.list.unique`, which does not exist before Neovim 0.12, so `main`
requires a nightly build. `nvim/lua/plugins/treesitter.lua` documents the exact
change to make once you are on 0.12.
