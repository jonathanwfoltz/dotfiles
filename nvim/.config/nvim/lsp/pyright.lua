-- NOTE: searches upward. A uv workspace keeps one .venv at the workspace root
-- while the member holds the pyproject.toml that becomes the LSP root.
local function venv_python(root)
  if vim.env.VIRTUAL_ENV then
    return vim.fs.joinpath(vim.env.VIRTUAL_ENV, 'bin', 'python')
  end

  local venv = vim.fs.find('.venv', { path = root, upward = true, type = 'directory' })[1]
  return venv and vim.fs.joinpath(venv, 'bin', 'python')
end

-- A project declaring its own interpreter has the last word.
-- NOTE: root-only, unlike the .venv search above -- pyright reads
-- [tool.pyright] from its own root only. venvPath alone is deliberately not a
-- declaration: pyright needs venv alongside it to resolve an interpreter, so
-- standing down on venvPath would fall back to PATH.
local function declares_own_env(root)
  if vim.uv.fs_stat(vim.fs.joinpath(root, 'pyrightconfig.json')) then return true end

  local pyproject = vim.fs.joinpath(root, 'pyproject.toml')
  if not vim.uv.fs_stat(pyproject) then return false end

  local in_pyright = false
  for _, line in ipairs(vim.fn.readfile(pyproject)) do
    local section = line:match('^%s*%[(.-)%]')
    if section then in_pyright = section == 'tool.pyright' end
    if in_pyright and line:match('^%s*venv%s*=') then return true end
  end

  return false
end

return {
  -- NOTE: on_init, not before_init. The client snapshots config.settings when
  -- it is constructed, so a before_init edit lands on a table nothing reads and
  -- pyright never receives pythonPath. The init-time notification has already
  -- gone out by now, hence notifying by hand.
  on_init = function(client)
    local root = client.root_dir or vim.fn.getcwd()
    if declares_own_env(root) then return end

    local python = venv_python(root)
    if not python or not vim.uv.fs_stat(python) then return end

    client.settings = vim.tbl_deep_extend('force', client.settings or {}, {
      python = { pythonPath = python },
    })
    client:notify('workspace/didChangeConfiguration', { settings = client.settings })
  end,

  settings = {
    pyright = {
      disableOrganizeImports = true, -- ruff owns imports
    },
    python = {
      analysis = {
        -- NOTE: all or nothing -- pyright offers one entry per module that
        -- could export a symbol, including re-exports, and has no finer filter.
        autoImportCompletions = false,
      },
    },
  },
}
