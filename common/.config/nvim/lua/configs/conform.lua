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

  -- format_on_save = {
  --   -- These options will be passed to conform.format()
  --   timeout_ms = 500,
  --   lsp_fallback = true,
  -- },
}

return options
