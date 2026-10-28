-- Generated or vendored folders that Telescope should never list or grep, at any depth.
-- `<leader>fA` and `<leader>fW` search without this list.
local ignored_dirs = {
  ".git", "node_modules", "vendor", "dist", "build", ".next", ".nuxt", ".output", ".turbo",
  ".cache", ".pnpm-store", "coverage", "target", "__pycache__", ".venv",
}
local ignore_patterns = {}
for _, dir in ipairs(ignored_dirs) do
  local escaped = dir:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
  vim.list_extend(ignore_patterns, { "^" .. escaped .. "/", "/" .. escaped .. "/" })
end

return {
  {
    "nvim-telescope/telescope.nvim",
    opts = { defaults = { file_ignore_patterns = ignore_patterns } },
  },

  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  -- Syntax trees. The installed nvim-treesitter is its rewritten "main" branch: it installs parsers
  -- with require("nvim-treesitter").install() (building them with the tree-sitter CLI, from mise) and
  -- no longer turns highlighting on or reads ensure_installed, which NvChad's spec still assumes.
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate", -- NvChad's ":TSUpdate | TSInstallAll" ends in a command that no longer exists
    config = function()
      local treesitter = require "nvim-treesitter"
      treesitter.setup {}

      local parsers = {
        "go", "gomod", "gosum", "gowork",
        "typescript", "tsx", "javascript", "html", "css", "scss", "vue",
        "json", "yaml", "toml", "markdown", "markdown_inline",
        "bash", "lua", "luadoc", "vim", "vimdoc", "query",
      }
      -- in the background; the ones that are already there are skipped
      local installed = treesitter.get_installed()
      local missing = vim.tbl_filter(function(lang)
        return not vim.list_contains(installed, lang)
      end, parsers)
      if #missing > 0 and vim.fn.executable "tree-sitter" == 1 then
        treesitter.install(missing)
      end

      local function start(buf)
        local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
        if lang and pcall(vim.treesitter.start, buf, lang) then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
        callback = function(event)
          start(event.buf)
        end,
      })
      -- the buffer that triggered loading this plugin already had its FileType event
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          start(buf)
        end
      end
    end,
  },

  -- Close an HTML/JSX/Vue tag when you type its ">", and rename the closing tag with the opening one
  {
    "windwp/nvim-ts-autotag",
    ft = { "html", "xml", "vue", "javascript", "javascriptreact", "typescript", "typescriptreact", "markdown" },
    dependencies = "nvim-treesitter/nvim-treesitter",
    opts = {
      opts = { enable_close = true, enable_rename = true, enable_close_on_slash = false },
    },
  },
}
