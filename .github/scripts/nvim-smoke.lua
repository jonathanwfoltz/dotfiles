-- Run with `nvim --headless --cmd 'luafile <this>'`: --cmd runs before
-- init.lua, so every notification the config raises is caught here.
local problems = {}

local notify = vim.notify
vim.notify = function(msg, level, opts)
  if (level or vim.log.levels.INFO) >= vim.log.levels.WARN then
    table.insert(problems, tostring(msg))
  end
  return notify(msg, level, opts)
end

local function finish()
  -- Errors raised outside vim.notify only reach :messages.
  local messages = vim.api.nvim_exec2('messages', { output = true }).output
  for _, line in ipairs(vim.split(messages, '\n')) do
    if line:match('^E%d+:') or line:match('^Error') then
      table.insert(problems, line)
    end
  end

  if #problems == 0 then
    io.stdout:write('nvim config loaded cleanly\n')
    vim.cmd('qall!')
  else
    io.stdout:write('nvim config raised:\n' .. table.concat(problems, '\n') .. '\n')
    vim.cmd('cquit 1')
  end
end

vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    local ok, misc = pcall(require, 'mini.misc')
    if not ok then
      table.insert(problems, 'mini.nvim never loaded -- init.lua stopped early')
      return finish()
    end
    -- NOTE: the 'later' queue runs in order, so this runs after every plugin
    -- file's own 'later' block. The delay lets notifications they scheduled land.
    misc.safely('later', function() vim.defer_fn(finish, 2000) end)
  end,
})
