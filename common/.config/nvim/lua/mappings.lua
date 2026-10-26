require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- Learning Neovim: interactive lessons (lua/../tutor/nvchad.tutor is about this very config)
map("n", "<leader>lt", "<cmd>Tutor nvchad<CR>", { desc = "learn: NvChad tutorial (interactive)" })
map("n", "<leader>lT", "<cmd>Tutor<CR>", { desc = "learn: classic vimtutor (interactive)" })
map("n", "<leader>lg", "<cmd>VimBeGood<CR>", { desc = "learn: vim-be-good (practice game)" })
map("n", "<leader>lp", "<cmd>Precognition toggle<CR>", { desc = "learn: show available motions (toggle)" })
local ok, wk = pcall(require, "which-key")
if ok then
  wk.add { { "<leader>l", group = "learn" } }
end

-- Herdr: Ctrl+h/j/k/l carry on into the neighbouring Herdr pane at the edge of the last split
-- (and Herdr hands the keys back when Neovim owns the pane). Must run after "nvchad.mappings"
-- above, which maps the same keys to plain window moves. A no-op outside Herdr, and until
-- the plugin has been installed by lazy.nvim.
local herdr_ok, herdr_nav = pcall(require, "herdr-nvim-nav")
if herdr_ok then
  herdr_nav.setup { with_tmux = false }
end
