require('formatter').setup({
    logging = false,
    filetype = {
        typescript = {
          require("formatter.filetypes.typescript").prettierd,
        },
        typescriptreact = {
          require("formatter.filetypes.typescriptreact").prettierd
        },
        python = {
          function()
            return {
              exe = "ruff",
              args = { "format", "-" },
              stdin = true
            }
          end
        },
        go = {
          function()
            return {
              exe = "gofmt",
              stdin = true
          }
        end
        }
    }
})

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
augroup("__formatter__", { clear = true })

autocmd("BufWritePost", {
    group = "__formatter__",
    command = ":FormatWrite",
})

