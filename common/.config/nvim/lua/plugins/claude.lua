-- Claude Code <-> Neovim, for reviewing what Claude does (docs/claude-review.md). Claude runs in
-- its own Herdr pane, so this plugin runs no terminal of its own: it listens on 127.0.0.1 and
-- Claude connects to it as an IDE (run /ide inside Claude Code). Its edit proposals then open as a
-- diff here, and selections and files can be sent to it.
-- Third-party code, so it is pinned to the commit that was reviewed; to move to a newer one, read the
-- diff and change the commit below.
return {
  {
    "coder/claudecode.nvim",
    commit = "c0deb41a0c6ac74c620be0a683aa9834e535c84a",
    -- the server has to be up for /ide to find it, so no cmd/keys lazy loading
    event = "VeryLazy",
    opts = {
      terminal = { provider = "none" },
      diff_opts = { layout = "vertical" },
    },
    keys = {
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "claude: send selection" },
      { "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", ft = { "NvimTree" }, desc = "claude: add file" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "claude: add this file" },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "claude: accept the proposed diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "claude: reject the proposed diff" },
    },
  },
}
