require("nvchad.configs.lspconfig").defaults()

-- Language servers, and the formatters conform uses (configs/conform.lua). Mason installs the ones that
-- are missing, in the background, the first time a file is opened (needs go and node, which mise provides).
local mason_packages = {
  "gopls",
  "goimports",
  "vtsls",
  "vue-language-server",
  "html-lsp",
  "css-lsp",
  "prettier",
  "stylua",
}

local function install_missing()
  local ok, registry = pcall(require, "mason-registry")
  if not ok then
    return
  end
  local missing = vim.tbl_filter(function(name)
    return not registry.is_installed(name)
  end, mason_packages)
  if #missing == 0 then
    return
  end
  registry.refresh(function()
    for _, name in ipairs(missing) do
      local found, package = pcall(registry.get_package, name)
      if found and not package:is_installed() and not package:is_installing() then
        vim.notify("Mason: installing " .. name)
        package:install()
      end
    end
  end)
end
vim.schedule(install_missing)

-- Go
vim.lsp.config("gopls", {
  settings = {
    gopls = {
      gofumpt = true,
      usePlaceholders = true, -- complete a call with its parameters as placeholders
      completeUnimported = true, -- complete packages that are not imported yet, and add the import
      staticcheck = true,
      analyses = { unusedparams = true, unusedwrite = true, nilness = true },
    },
  },
})

-- TypeScript and JavaScript; also the TypeScript inside .vue files, through Vue's tsserver plugin.
-- vue_ls (Vue 3, "hybrid mode") only handles the template and styles of a .vue file and asks vtsls for the
-- rest; its forwarding is in nvim-lspconfig's own lsp/vue_ls.lua.
local vue_plugin = {
  name = "@vue/typescript-plugin",
  location = vim.fn.stdpath "data" .. "/mason/packages/vue-language-server/node_modules/@vue/language-server",
  languages = { "vue" },
  configNamespace = "typescript",
}
vim.lsp.config("vtsls", {
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
  settings = {
    vtsls = { tsserver = { globalPlugins = { vue_plugin } } },
  },
})

vim.lsp.enable { "gopls", "vtsls", "vue_ls", "html", "cssls" }

-- This file loads after the first buffer was opened (NvChad loads lspconfig on its FilePost event), and
-- that buffer's FileType event, which is what attaches a server, has already gone by: fire it again for
-- the buffers that are open, for the servers above only.
vim.schedule(function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" and vim.bo[buf].filetype ~= "" then
      vim.api.nvim_exec_autocmds("FileType", { group = "nvim.lsp.enable", buffer = buf })
    end
  end
end)

-- read :h vim.lsp.config for changing options of lsp servers
