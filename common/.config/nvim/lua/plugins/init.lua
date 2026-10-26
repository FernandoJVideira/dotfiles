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

  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },
}
