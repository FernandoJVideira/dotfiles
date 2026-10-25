-- Resolves the NvChad base46 theme name from the state file that the theme-set hook
-- (nvchad-sync, common/.config/omadora/hooks/theme-set.d) writes on every theme change:
-- "omadora", a theme generated from the OS palette. Falls back to "gruvbox" when the
-- file doesn't exist (fresh install).
local M = {}

local state_file = vim.fn.stdpath "state" .. "/omarchy_theme"

function M.current()
  local file = io.open(state_file, "r")
  if not file then
    return "gruvbox"
  end

  local name = file:read "*l"
  file:close()

  return name and name ~= "" and name or "gruvbox"
end

return M
