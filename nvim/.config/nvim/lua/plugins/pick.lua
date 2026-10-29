local safely = require('mini.misc').safely

safely('later', function()
  local pick = require('mini.pick')
  local extra = require('mini.extra')
  pick.setup()
  extra.setup()

  local function map(lhs, rhs, desc)
    vim.keymap.set('n', '<Leader>' .. lhs, rhs, { desc = desc })
  end

  local function git_lines(...)
    local out = vim.fn.systemlist({ 'git', ... })
    if vim.v.shell_error ~= 0 then return nil end
    return out
  end

  -- NOTE: git ls-files needs no extra dependency and arrives pre-filtered --
  -- .git is never reported and --exclude-standard drops ignored caches
  -- (__pycache__, .venv, build output). Same filtering tool = 'git' gives ps/pt.
  local ls_files = { 'ls-files', '--exclude-standard', '--cached', '--others' }

  pick.registry.other_files = function()
    -- Pathspecs are anchored at the cwd, so this excludes the top-level src and
    -- test only: the exact complement of ps and pt. builtin.files takes no
    -- command arguments, hence cli.
    if git_lines('rev-parse', '--show-toplevel') == nil then
      return pick.builtin.files()
    end
    local command = { 'git' }
    vim.list_extend(command, ls_files)
    vim.list_extend(command, { '--', ':(exclude)src', ':(exclude)test', ':(exclude)typings' })
    return pick.builtin.cli(
      { command = command },
      { source = { name = 'Files (no src/test)' } }
    )
  end

  map('pf', pick.registry.other_files, 'Pick files (excluding ./src, ./test)')
  map('pg', pick.builtin.grep_live, 'Pick grep (live)')
  map('pd', extra.pickers.diagnostic, 'Pick diagnostics')
  map('pk', extra.pickers.keymaps, 'Pick keymaps')
  -- Upper-case C because pc is pick-conflicts; equal-length sequences, so
  -- neither is a prefix of the other and neither stalls.
  map('pC', extra.pickers.commands, 'Pick commands')
  map('pb', pick.builtin.buffers, 'Pick buffers')
  map('pr', pick.builtin.resume, 'Pick resume last')

  -- Core gives gO for the current file and nothing project-wide. Lives here
  -- rather than plugins/lsp.lua because this file owns the pickers.
  map('pw', function()
    extra.pickers.lsp({ scope = 'workspace_symbol_live' })
  end, 'Pick workspace symbols')

  local function tracked_files(cwd)
    return function()
      pick.builtin.files({ tool = 'git' }, { source = { cwd = cwd } })
    end
  end

  map('ps', tracked_files('./src'), 'Pick source files (./src)')
  map('pt', tracked_files('./test'), 'Pick test files (./test)')

  pick.registry.folders = function()
    local files = git_lines(unpack(ls_files))
    if files == nil then
      return vim.notify('Not inside a git repository', vim.log.levels.WARN)
    end

    local dirs, seen = {}, {}
    for _, path in ipairs(files) do
      local dir = vim.fs.dirname(path)
      if not seen[dir] then
        seen[dir] = true
        table.insert(dirs, dir)
      end
    end

    -- A directory is a leaf when no other listed directory sits below it. '.'
    -- is the parent of every path, so it only survives in a flat repository.
    local leaves = {}
    for _, dir in ipairs(dirs) do
      local prefix = dir == '.' and '' or dir .. '/'
      local is_leaf = true
      for _, other in ipairs(dirs) do
        if other ~= dir and vim.startswith(other, prefix) then
          is_leaf = false
          break
        end
      end
      if is_leaf then table.insert(leaves, dir) end
    end
    table.sort(leaves)

    local choose = function(item)
      -- A picker cannot be started from inside another picker's choose.
      vim.schedule(function()
        pick.builtin.files({ tool = 'git' }, { source = { cwd = item } })
      end)
    end

    -- Items are directories, which the default preview would try to read as
    -- files.
    local preview = function(buf_id, item)
      local entries = vim.fn.readdir(item)
      vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, entries)
    end

    return pick.start({
      source = {
        items = leaves,
        name = 'Leaf folders',
        choose = choose,
        preview = preview,
      },
    })
  end

  map('po', pick.registry.folders, 'Pick leaf folders')

  pick.registry.projects = function()
    local choose = function(item)
      vim.schedule(function()
        pick.builtin.files(nil, { source = { cwd = item.path } })
      end)
    end
    return extra.pickers.explorer(
      { cwd = vim.fn.expand('~/projects') },
      { source = { choose = choose } }
    )
  end

  map('pp', pick.registry.projects, 'Pick projects')
end)
