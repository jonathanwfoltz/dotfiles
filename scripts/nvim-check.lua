-- Sourced with --cmd, i.e. BEFORE init.lua. Captures every vim.notify at
-- WARN or above, then (after init) queues a sentinel at the END of the
-- MiniMisc.safely('later') FIFO, waits a grace period for async follow-ups,
-- and exits 1 if anything was captured.
local problems = {}
local orig_notify = vim.notify
vim.notify = function(msg, level, opts)
  if (level or vim.log.levels.INFO) >= vim.log.levels.WARN then
    table.insert(problems, tostring(msg))
  end
  return orig_notify(msg, level, opts)
end

-- Some plugins bypass vim.notify: nvim-treesitter's logger echoes with the
-- ErrorMsg/WarningMsg highlight and no `err` flag. It grabs
-- vim.api.nvim_echo when required, which is after this wrapper exists.
local bad_hl = { ErrorMsg = true, WarningMsg = true }
local orig_echo = vim.api.nvim_echo
vim.api.nvim_echo = function(chunks, history, opts)
  local flagged = opts and opts.err
  local text = {}
  for _, c in ipairs(chunks) do
    table.insert(text, c[1])
    if bad_hl[c[2]] then
      flagged = true
    end
  end
  if flagged then
    table.insert(problems, 'echo: ' .. table.concat(text))
  end
  return orig_echo(chunks, history, opts)
end

local function finish()
  if vim.v.errmsg ~= '' then
    table.insert(problems, 'v:errmsg: ' .. vim.v.errmsg)
  end
  if #problems == 0 then
    io.stdout:write('config-check: OK\n')
    vim.cmd('qall!')
  else
    io.stderr:write('config-check: FAILED\n' .. table.concat(problems, '\n---\n') .. '\n')
    vim.cmd('cquit 1')
  end
end

vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    local grace = tonumber(vim.env.CHECK_GRACE_MS) or 3000
    local ok, misc = pcall(require, 'mini.misc')
    if not ok then
      table.insert(problems, 'mini.misc not loadable: ' .. misc)
      return finish()
    end
    -- FIFO: every 'later' queued while sourcing init.lua runs before this.
    misc.safely('later', function()
      vim.defer_fn(finish, grace)
    end)
  end,
})

-- Hard cap so a hang (e.g. a prompt) fails instead of blocking CI forever.
vim.defer_fn(function()
  table.insert(problems, 'timeout')
  finish()
end, tonumber(vim.env.CHECK_TIMEOUT_MS) or 300000)
