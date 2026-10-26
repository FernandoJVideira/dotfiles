require "nvchad.autocmds"

-- Open the file tree at startup, with the cursor staying in the editor. Skipped for
-- headless runs, diffs and git's commit/rebase editors.
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if #vim.api.nvim_list_uis() == 0 or vim.o.diff then
      return
    end
    if vim.tbl_contains({ "gitcommit", "gitrebase" }, vim.bo.filetype) then
      return
    end
    local api = require "nvim-tree.api"
    if not api.tree.is_visible() then
      api.tree.toggle { focus = false, find_file = true }
    end
  end,
})

-- :q in the last real window also closes the file tree, so Neovim exits instead of
-- stranding you in a lone tree window.
vim.api.nvim_create_autocmd("QuitPre", {
  callback = function()
    local wins = vim.api.nvim_list_wins()
    local tree_wins, floating = {}, 0
    for _, w in ipairs(wins) do
      local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w))
      if name:match "NvimTree_" then
        table.insert(tree_wins, w)
      elseif vim.api.nvim_win_get_config(w).relative ~= "" then
        floating = floating + 1
      end
    end
    if #tree_wins > 0 and #wins - floating - #tree_wins == 1 then
      for _, w in ipairs(tree_wins) do
        vim.api.nvim_win_close(w, true)
      end
    end
  end,
})
