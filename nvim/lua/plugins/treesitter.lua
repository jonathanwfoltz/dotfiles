require('nvim-treesitter.configs').setup({
    ensure_installed = { "html", "css", "typescript", "tsx", "python", "go" },
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
        use_languagetree = true,
    },
    indent = { enable = true}
})
