-- Hammerspoon runs one thing here: the theme picker popup, opened by `open -g hammerspoon://theme`
-- (Alt+Shift+T in macos/.config/hyprspace/config.toml), so it needs no hotkey permission.
hs.autoLaunch(true)
hs.menuIcon(false)
hs.dockIcon(false)

local theme_picker = require("theme_picker")
hs.urlevent.bind("theme", function()
  theme_picker.show()
end)
