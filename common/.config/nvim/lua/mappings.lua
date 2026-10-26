require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- Learning Neovim: interactive lessons (lua/../tutor/nvchad.tutor is about this very config)
map("n", "<leader>lt", "<cmd>Tutor nvchad<CR>", { desc = "learn: NvChad tutorial (interactive)" })
map("n", "<leader>lT", "<cmd>Tutor<CR>", { desc = "learn: classic vimtutor (interactive)" })
local ok, wk = pcall(require, "which-key")
if ok then
  wk.add { { "<leader>l", group = "learn" } }
end
