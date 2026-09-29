local add = require('core.pack')
local safely = require('mini.misc').safely

safely('later', function()
  add({ 'https://github.com/stevearc/conform.nvim' })

  local util = require('conform.util')

  -- Prefer the project's pinned ruff over mason's; find_executable searches
  -- upward from the buffer.
  local ruff = { command = util.find_executable({ '.venv/bin/ruff' }, 'ruff') }

  -- NOTE: these gates are why a save does not reformat a project that never
  -- asked for it. Returning {} leaves the buffer alone; without them,
  -- clang-format imposes LLVM style and cmake-format its own defaults.
  local function when_config(names, formatter)
    return function(bufnr)
      local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
      if dir == '' then return {} end
      return vim.fs.find(names, { path = dir, upward = true })[1] and { formatter } or {}
    end
  end

  local clang_format = when_config({ '.clang-format', '_clang-format' }, 'clang-format')

  -- Python cannot reuse when_config: a pyproject.toml only counts when it
  -- carries a [tool.ruff] section, which mirrors ruff's own discovery.
  local function ruff_config_above(dir)
    local found = vim.fs.find(function(name)
      return name == 'ruff.toml' or name == '.ruff.toml' or name == 'pyproject.toml'
    end, { path = dir, upward = true, limit = math.huge })

    for _, path in ipairs(found) do
      if vim.fs.basename(path) ~= 'pyproject.toml' then return true end
      for _, line in ipairs(vim.fn.readfile(path)) do
        -- [tool.ruff], [tool.ruff.lint] and [tool.ruff.format] all count.
        if line:match('^%s*%[tool%.ruff[%]%.]') then return true end
      end
    end

    return false
  end

  require('conform').setup({
    formatters = { ruff_format = ruff, ruff_organize_imports = ruff },
    formatters_by_ft = {
      -- Imports first: organize_imports rewrites lines ruff_format then lays
      -- out. Both gated, so a non-ruff project keeps its import order too.
      python = function(bufnr)
        local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
        if dir == '' or not ruff_config_above(dir) then return {} end
        return { 'ruff_organize_imports', 'ruff_format' }
      end,
      c = clang_format,
      cpp = clang_format,
      cmake = when_config({
        '.cmake-format.yaml', '.cmake-format.json', '.cmake-format.py',
        'cmake-format.yaml', 'cmake-format.json', 'cmake-format.py',
      }, 'cmake_format'),
    },
    -- A function, not a table, so vim.g/vim.b.disable_autoformat can bypass it
    -- without resorting to :noautocmd w.
    format_on_save = function(bufnr)
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
      -- NOTE: lsp_format cannot be overridden per filetype -- merge_default_opts
      -- only fills keys still nil, so a formatters_by_ft entry setting it is a
      -- silent no-op.
      return { timeout_ms = 500, lsp_format = 'fallback' }
    end,
  })

  vim.keymap.set('n', '<Leader>sf', function()
    vim.g.disable_autoformat = not vim.g.disable_autoformat
    vim.notify(('Format on save %s'):format(vim.g.disable_autoformat and 'off' or 'on'))
  end, { desc = 'Switch format on save' })

  -- Covers both on-demand and partial formatting: conform.format derives the
  -- range from the visual selection when opts.range is unset.
  vim.keymap.set({ 'n', 'x' }, '<Leader>fb', function()
    require('conform').format({ async = true, lsp_format = 'fallback' })
  end, { desc = 'Format buffer or selection' })
end)
