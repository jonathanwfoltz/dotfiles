local add, now = MiniDeps.add, MiniDeps.now

now(function()
  add({ source = 'folke/tokyonight.nvim' })

  if not pcall(vim.cmd.colorscheme, 'tokyonight-night') then
    vim.notify('Colorscheme tokyonight-night not found', vim.log.levels.WARN)
  end
end)
