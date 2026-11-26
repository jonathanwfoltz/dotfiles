local lock = vim.json.decode(table.concat(vim.fn.readfile(_G.arg[1]), '\n'))
local bad = 0
for name, d in pairs(lock.plugins) do
  local head = vim.trim(vim.fn.system({ 'git', '-C', _G.arg[2] .. '/' .. name, 'rev-parse', 'HEAD' }))
  if head ~= d.rev then print(('%s: HEAD %s ~= lock %s'):format(name, head, d.rev)); bad = 1 end
end
os.exit(bad)
