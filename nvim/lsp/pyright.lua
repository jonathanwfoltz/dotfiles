-- The previous config hardcoded './.venv/bin/python', which resolves against
-- whatever directory Neovim happened to start in. Resolve it against the
-- project root instead, and only when it actually exists.
return {
  before_init = function(_, config)
    local root = config.root_dir or vim.fn.getcwd()
    local python = vim.fs.joinpath(root, '.venv', 'bin', 'python')
    if not vim.uv.fs_stat(python) then return end

    config.settings = vim.tbl_deep_extend('force', config.settings or {}, {
      python = { pythonPath = python },
    })
  end,
}
