local prettier = { "prettier" }

local options = {
  -- <leader>fm formats the buffer (NvChad's mapping)
  formatters_by_ft = {
    lua = { "stylua" },
    go = { "goimports", "gofmt" },
    javascript = prettier,
    javascriptreact = prettier,
    typescript = prettier,
    typescriptreact = prettier,
    vue = prettier,
    html = prettier,
    css = prettier,
    scss = prettier,
    json = prettier,
    jsonc = prettier,
    yaml = prettier,
  },

  -- Format when the file is saved: the formatters above, or the language server's formatting for filetypes
  -- without one. :FormatToggle turns it off and on (for the session), or use :noautocmd w to skip it once.
  format_on_save = function()
    if vim.g.disable_autoformat then
      return nil
    end
    return { timeout_ms = 3000, lsp_format = "fallback" }
  end,
}

return options
