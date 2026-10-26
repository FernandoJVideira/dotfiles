-- Ctrl+h/j/k/l across Neovim splits and Herdr panes (see lib/herdr.sh for the Herdr half and
-- why this commit: it is the one that was read in full before being adopted). Lazy-loaded from
-- mappings.lua, which has to run its setup() after NvChad's own <C-hjkl> window mappings.
return {
  {
    "aimdevlee/herdr-nvim-nav",
    commit = "ec047fd6d8d0269d54a34e9405af28d8aad4c8f0",
    lazy = true,
  },
}
