local safely = require('mini.misc').safely

safely('later', function()
  local pick = require('mini.pick')
  local extra = require('mini.extra')
  pick.setup()
  extra.setup()

  local function map(lhs, rhs, desc)
    vim.keymap.set('n', '<Leader>' .. lhs, rhs, { desc = desc })
  end

  map('pf', pick.builtin.files, 'Pick files')
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
