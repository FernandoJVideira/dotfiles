-- Super + h/j/k/l moves between Herdr panes and Neovim splits while a terminal has focus, and
-- between Hyprland windows everywhere else (Super + arrows still move between windows from a
-- terminal). In a terminal it sends Ctrl + h/j/k/l, which herdr-nvim-nav already handles, so those
-- keys keep working as they are. Loaded after hypr.bindings: Skein's bindings.lua gives these four
-- keys to window focus, so they are released and bound again here.
local terminals = { kitty = true, Alacritty = true, foot = true, ["com.mitchellh.ghostty"] = true }
local window_direction = { h = "l", j = "d", k = "u", l = "r" }

for key, direction in pairs(window_direction) do
  local chord = "SUPER + " .. key:upper()
  hl.unbind(chord)
  hl.bind(chord, function()
    local w = hl.get_active_window()
    if w and terminals[w.class] then
      hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = key }))
    else
      hl.dispatch(hl.dsp.focus({ direction = direction }))
    end
  end)
end
