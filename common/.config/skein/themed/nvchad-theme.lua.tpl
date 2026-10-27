-- NvChad (base46) theme "skein", rendered from the current OS theme by Skein's
-- template engine (common/.config/skein/themed/nvchad-theme.lua.tpl) into
-- current/theme/nvchad-theme.lua; the nvchad-sync hook installs it as
-- ~/.config/nvim/lua/themes/skein.lua. Same palette as the terminal, so Neovim matches
-- every theme, not just the ones that have an NvChad namesake.
local M = {}

M.base_30 = {
  white = "{{ foreground }}",
  darker_black = "{{ dark_background }}",
  black = "{{ background }}", --  nvim bg
  black2 = "{{ mix background foreground 4 }}",
  one_bg = "{{ mix background foreground 8 }}",
  one_bg2 = "{{ mix background foreground 13 }}",
  one_bg3 = "{{ mix background foreground 18 }}",
  grey = "{{ mix background foreground 25 }}",
  grey_fg = "{{ mix background foreground 30 }}",
  grey_fg2 = "{{ mix background foreground 35 }}",
  light_grey = "{{ mix background foreground 45 }}",
  red = "{{ red }}",
  baby_pink = "{{ bright_red }}",
  pink = "{{ magenta }}",
  line = "{{ mix background foreground 12 }}", -- for lines like vertsplit
  green = "{{ green }}",
  vibrant_green = "{{ bright_green }}",
  nord_blue = "{{ bright_blue }}",
  blue = "{{ blue }}",
  yellow = "{{ yellow }}",
  sun = "{{ bright_yellow }}",
  purple = "{{ magenta }}",
  dark_purple = "{{ bright_magenta }}",
  teal = "{{ cyan }}",
  orange = "{{ orange }}",
  cyan = "{{ bright_cyan }}",
  statusline_bg = "{{ mix background foreground 5 }}",
  lightbg = "{{ mix background foreground 10 }}",
  pmenu_bg = "{{ accent }}",
  folder_bg = "{{ accent }}",
}

M.base_16 = {
  base00 = "{{ background }}",
  base01 = "{{ mix background foreground 8 }}",
  base02 = "{{ selection }}",
  base03 = "{{ mix background foreground 40 }}",
  base04 = "{{ dark_foreground }}",
  base05 = "{{ foreground }}",
  base06 = "{{ light_foreground }}",
  base07 = "{{ bright_foreground }}",
  base08 = "{{ red }}",
  base09 = "{{ orange }}",
  base0A = "{{ yellow }}",
  base0B = "{{ green }}",
  base0C = "{{ cyan }}",
  base0D = "{{ blue }}",
  base0E = "{{ magenta }}",
  base0F = "{{ brown }}",
}

M.type = "{{ mode }}"

M = require("base46").override_theme(M, "skein")

return M
