-- Practice for learning Neovim, next to the interactive lessons (:Tutor nvchad, :Tutor; see
-- tutor/nvchad.tutor). Both are loaded only when asked for. Keys are in mappings.lua (<leader>l...).
return {
  -- a game that drills motions: deleting, changing, moving, hjkl (:VimBeGood)
  { "ThePrimeagen/vim-be-good", cmd = "VimBeGood" },

  -- shows, as virtual text, which motions are available from the cursor (off until toggled)
  {
    "tris203/precognition.nvim",
    cmd = "Precognition",
    opts = { startVisible = false },
  },
}
