local add = require('core.pack')
local safely = require('mini.misc').safely

safely('later', function()
  add({
    -- NOTE: also in plugins/lsp.lua -- mason-nvim-dap needs mason-core at
    -- load time and either file may run first. add is idempotent.
    'https://github.com/mason-org/mason.nvim',
    'https://github.com/mfussenegger/nvim-dap',
    'https://github.com/nvim-neotest/nvim-nio',
    'https://github.com/rcarriga/nvim-dap-ui',
    'https://github.com/mfussenegger/nvim-dap-python',
    'https://github.com/jay-babu/mason-nvim-dap.nvim',
  })

  local dap = require('dap')
  local dapui = require('dapui')

  -- NOTE: setup() puts mason's bin on PATH, and codelldb is resolved with
  -- exepath() at require time -- without this the adapter gets no command.
  local mason = require('mason')
  if not mason.has_setup then mason.setup() end

  -- NOTE: handlers = {} looks optional but is what registers the codelldb
  -- adapter and launch config. ensure_installed is skipped when headless.
  require('mason-nvim-dap').setup({
    ensure_installed = { 'codelldb', 'python' },
    handlers = {},
  })

  -- debugpy comes from mason, not the project: a `uv init` venv has none.
  -- NOTE: built from the install root, not mason-registry, whose
  -- get_package() raises until plugins/lsp.lua has refreshed it.
  local debugpy = vim.fs.joinpath(
    require('mason.settings').current.install_root_dir,
    'packages', 'debugpy', 'venv', 'bin', 'python'
  )
  if vim.uv.fs_stat(debugpy) then require('dap-python').setup(debugpy) end

  dapui.setup()

  -- NOTE: wrapped, not passed by reference -- dap calls listeners with
  -- (session, body) and dapui reads arg 1 as options, leaving panels up.
  -- disconnect is omitted upstream and is the only event terminate() fires.
  dap.listeners.after.event_initialized.dapui = function() dapui.open() end
  dap.listeners.before.event_terminated.dapui = function() dapui.close() end
  dap.listeners.before.event_exited.dapui = function() dapui.close() end
  dap.listeners.before.disconnect.dapui = function() dapui.close() end

  local function map(lhs, rhs, desc)
    vim.keymap.set('n', '<Leader>' .. lhs, rhs, { desc = desc })
  end

  map('db', dap.toggle_breakpoint, 'Debug: toggle breakpoint')
  map('dc', dap.continue, 'Debug: continue (starts a session)')
  map('dn', dap.step_over, 'Debug: next (step over)')
  map('di', dap.step_into, 'Debug: step into')
  map('do', dap.step_out, 'Debug: step out')
  map('du', dapui.toggle, 'Debug: toggle UI')
  map('dq', dap.terminate, 'Debug: quit session')
  map('dt', function() require('dap-python').test_method() end, 'Debug: test method under cursor')
end)
