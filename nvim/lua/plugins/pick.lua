require('mini.extra').setup()

local pick = require("mini.pick")
pick.setup()

local current_branch = function()
    local branch = vim.fn.system('git rev-parse --abbrev-ref HEAD')
    if vim.v.shell_error ~= 0 then return nil end
    return vim.trim(branch)
end

require('mini.visits').setup({})
local map_branch = function(keys, action, desc)
    local rhs = function()
        local branch = current_branch()
        if branch == nil then
            return
        end
        require('mini.visits')[action](branch)
    end
    vim.keymap.set('n', '<Leader>' .. keys, rhs, { desc = desc })
end

map_branch('al', 'add_label', 'Add branch label')
map_branch('rl', 'remove_label', 'Remove branch label')

local pick_label = function(keys, nameFunction, desc)
    local rhs = function()
        local labelName = nameFunction()
        if(labelName == nil) then
            return
        end
        MiniExtra.pickers.visit_paths({ filter = labelName })
    end
    vim.keymap.set('n', '<Leader>' .. keys, rhs, { desc = desc })
end

pick_label('vl', current_branch, 'View current branch label')

MiniPick.registry.projects = function()
  local cwd = vim.fn.expand('~/projects')
  local choose = function(item)
    vim.schedule(function() MiniPick.builtin.files(nil, { source = { cwd = item.path } }) end)
  end
  return MiniExtra.pickers.explorer({ cwd = cwd }, {source = { choose = choose } })
end

vim.keymap.set('n', '<Leader>pp', ':Pick projects<CR>', { desc = 'Lists the projects directory' })

local get_conflicts = function()
  return MiniPick.set_picker_items_from_cli({ 'git', 'diff', '--name-only', '--diff-filter=U'})
end

MiniPick.registry.conflicts = function()
  local items = vim.schedule(get_conflicts)
  MiniPick.start({ source = { items = items, name = 'Conflicts'} })
end

vim.keymap.set('n', '<Leader>pc', ':Pick conflicts<CR>', { desc = 'Lists conflicting git files' })
vim.keymap.set('n', '<Leader>ph', ':Pick hipatterns<CR>')

 function tracked_files(cwd)
   return function()
     pick.builtin.files({
       tool = "git"
     }, {source={cwd = cwd}})
   end
end

vim.api.nvim_set_keymap('n', '<Leader>pu', ':Pick files<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<Leader>pd', ':Pick diagnostic<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<Leader>pg', ':Pick grep_live<CR>', {noremap = true, silent = true})
vim.keymap.set('n', '<Leader>pf', tracked_files("./src"), {noremap = true, silent = true})
vim.keymap.set('n', '<Leader>pt', tracked_files("./test"), {noremap = true, silent = true})
