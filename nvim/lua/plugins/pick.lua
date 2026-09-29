local later = MiniDeps.later

later(function()
  local pick = require('mini.pick')
  local extra = require('mini.extra')
  pick.setup()
  extra.setup()

  local function map(lhs, rhs, desc)
    vim.keymap.set('n', '<Leader>' .. lhs, rhs, { desc = desc })
  end

  map('pf', function() pick.builtin.files() end, 'Pick files')
  map('pg', function() pick.builtin.grep_live() end, 'Pick grep (live)')
  map('pd', function() extra.pickers.diagnostic() end, 'Pick diagnostics')
  map('pk', function() extra.pickers.keymaps() end, 'Pick keymaps')

  -- Git-tracked files beneath a single directory.
  local function tracked_files(cwd)
    return function()
      pick.builtin.files({ tool = 'git' }, { source = { cwd = cwd } })
    end
  end

  map('ps', tracked_files('./src'), 'Pick source files (./src)')
  map('pt', tracked_files('./test'), 'Pick test files (./test)')

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
