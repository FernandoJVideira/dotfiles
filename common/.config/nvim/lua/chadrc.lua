-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = require("omarchy_theme").current(),

	-- Let the terminal's own background (its opacity and blur) show through, like every
	-- other window; nvim's colors come from the OS theme (see nvchad-sync)
	transparency = true,

	-- a tint on the cursor's line and a bold number, so the current line stands out even with
	-- the transparent background; theme colors, so it follows every theme switch
	hl_override = {
		CursorLine = { bg = "one_bg2" },
		CursorLineNr = { bold = true, bg = "one_bg2" },
	},
}

-- M.nvdash = { load_on_startup = true }
-- M.ui = {
--       tabufline = {
--          lazyload = false
--      }
-- }

return M
