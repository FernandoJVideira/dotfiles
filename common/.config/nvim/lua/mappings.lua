require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- Telescope hides node_modules, vendor, dist and friends (lua/plugins/init.lua); these two don't
map("n", "<leader>fA", function()
  require("telescope.builtin").find_files { follow = true, no_ignore = true, hidden = true, file_ignore_patterns = {} }
end, { desc = "telescope find all files, including ignored folders" })
map("n", "<leader>fW", function()
  require("telescope.builtin").live_grep { additional_args = { "--no-ignore", "--hidden" }, file_ignore_patterns = {} }
end, { desc = "telescope live grep, including ignored folders" })

-- Reviewing what Claude changed on disk (docs/claude-review.md). A hunk is "accepted" once it is
-- staged, so the sign column only ever shows what is still waiting for review.
local function gs(fn, ...)
  local args = { ... }
  return function()
    require("gitsigns")[fn](unpack(args))
  end
end
local function hunk_range()
  return { vim.fn.line ".", vim.fn.line "v" }
end
map("n", "]h", gs("nav_hunk", "next"), { desc = "hunk: next" })
map("n", "[h", gs("nav_hunk", "prev"), { desc = "hunk: previous" })
map("n", "<leader>hp", gs "preview_hunk_inline", { desc = "hunk: preview inline (shows the removed lines)" })
map("n", "<leader>ha", gs "stage_hunk", { desc = "hunk: accept (stage)" })
map("v", "<leader>ha", function()
  require("gitsigns").stage_hunk(hunk_range())
end, { desc = "hunk: accept the selected lines" })
map("n", "<leader>hd", gs "reset_hunk", { desc = "hunk: deny (restore the old lines)" })
map("v", "<leader>hd", function()
  require("gitsigns").reset_hunk(hunk_range())
end, { desc = "hunk: deny the selected lines" })
map("n", "<leader>hA", gs "stage_buffer", { desc = "hunk: accept every hunk in this file" })
map("n", "<leader>hD", gs "reset_buffer", { desc = "hunk: deny every hunk in this file" })
map("n", "<leader>hu", gs "undo_stage_hunk", { desc = "hunk: undo the last accept" })
map("n", "<leader>hl", gs("setqflist", "all"), { desc = "hunk: list every hunk to review (quickfix)" })
map("n", "<leader>hF", function()
  if vim.fn.confirm("Accept ALL changes in the repo (git add -A)?", "&Yes\n&No", 2) == 1 then
    vim.system({ "git", "add", "-A" }):wait()
    vim.cmd "checktime"
    vim.notify "accepted every change"
  end
end, { desc = "hunk: accept everything in the repo" })

-- Learning Neovim: interactive lessons (lua/../tutor/nvchad.tutor is about this very config)
map("n", "<leader>lt", "<cmd>Tutor nvchad<CR>", { desc = "learn: NvChad tutorial (interactive)" })
map("n", "<leader>lT", "<cmd>Tutor<CR>", { desc = "learn: classic vimtutor (interactive)" })
map("n", "<leader>lg", "<cmd>VimBeGood<CR>", { desc = "learn: vim-be-good (practice game)" })
map("n", "<leader>lp", "<cmd>Precognition toggle<CR>", { desc = "learn: show available motions (toggle)" })
local ok, wk = pcall(require, "which-key")
if ok then
  wk.add { { "<leader>l", group = "learn" }, { "<leader>h", group = "review hunks" }, { "<leader>a", group = "claude" } }
end

-- Herdr: Ctrl+h/j/k/l carry on into the neighbouring Herdr pane at the edge of the last split
-- (and Herdr hands the keys back when Neovim owns the pane). Must run after "nvchad.mappings"
-- above, which maps the same keys to plain window moves. A no-op outside Herdr, and until
-- the plugin has been installed by lazy.nvim.
local herdr_ok, herdr_nav = pcall(require, "herdr-nvim-nav")
if herdr_ok then
  herdr_nav.setup { with_tmux = false }
end
