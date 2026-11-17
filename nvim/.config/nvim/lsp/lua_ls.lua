-- Settings for editing this config, so `vim` resolves and vim.api completes.
-- A project with its own .luarc.json has the last word, as with pyright.
return {
  -- NOTE: on_init and a notify, not settings -- the same snapshot problem
  -- lsp/pyright.lua describes.
  on_init = function(client)
    local root = client.root_dir
    if root and (vim.uv.fs_stat(root .. '/.luarc.json') or vim.uv.fs_stat(root .. '/.luarc.jsonc')) then
      return
    end

    client.settings = vim.tbl_deep_extend('force', client.settings or {}, {
      Lua = {
        runtime = { version = 'LuaJIT', path = { 'lua/?.lua', 'lua/?/init.lua' } },
        workspace = {
          -- NOTE: off, or lua_ls offers to write a .luarc.json into the
          -- stow-folded config directory.
          checkThirdParty = false,
          library = { vim.env.VIMRUNTIME, '${3rd}/luv/library' },
        },
      },
    })
    client:notify('workspace/didChangeConfiguration', { settings = client.settings })
  end,
}
