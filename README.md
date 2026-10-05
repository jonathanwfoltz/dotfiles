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

Requires **Neovim 0.12 or newer**, plus `tree-sitter-cli` 0.26.1+ and a C
compiler for treesitter parsers. Plugins are managed by Neovim's built-in
[`vim.pack`](https://neovim.io/doc/user/pack.html) — nothing to bootstrap and
nothing to install by hand. Revisions are recorded in
`nvim/nvim-pack-lock.json`, which is tracked; update with `:lua vim.pack.update()`,
review the diff buffer it opens, then `:write` to accept or `:quit` to discard.

```
nvim/
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

Window and buffer movement: `<C-h/j/k/l>` between windows, `<C-z>h/j/k/l` to
resize, `<S-h>`/`<S-l>` to cycle buffers.

LSP uses Neovim's built-in mappings rather than redefining them: `grn` rename,
`gra` code action, `grr` references, `gri` implementation, `gO` symbols, `K`
hover, `<C-s>` signature help. Only `gd` (definition) is added, since it has no
default.

### Languages

LSP, formatting and treesitter parsers are configured for TypeScript/TSX, Python,
Go, HTML and CSS, plus Tailwind. Formatting is
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
