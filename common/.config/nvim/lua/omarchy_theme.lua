-- Resolves the NvChad base46 theme name from the state file that Omarchy's
-- theme-set hook (linux/.config/omarchy/hooks/theme-set.d/nvchad-sync)
-- writes on every `omarchy theme set`. Falls back to "onedark" when the
-- file doesn't exist yet (fresh install, or on macOS where Omarchy isn't
-- present at all).
local M = {}

local state_file = vim.fn.stdpath "state" .. "/omarchy_theme"

function M.current()
  local file = io.open(state_file, "r")
  if not file then
    return "onedark"
  end

  local name = file:read "*l"
  file:close()

  return name and name ~= "" and name or "onedark"
end

return M
