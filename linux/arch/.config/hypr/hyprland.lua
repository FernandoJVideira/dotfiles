-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Load user modules from ~/.config and Skein defaults from $SKEIN_PATH.
package.path = os.getenv("HOME")
  .. "/.config/?.lua;"
  .. (os.getenv("SKEIN_PATH") or (os.getenv("HOME") .. "/.local/share/skein"))
  .. "/?.lua;"
  .. package.path

-- All Skein default setups
require("default.hypr.skein")

---- Change your own setup in these files and override defaults.
require("hypr.monitors")
require("hypr.input")
require("hypr.capslock")
require("hypr.bindings")
require("hypr.panes")
require("hypr.looknfeel")
require("hypr.autostart")

---- Toggle config flags dynamically
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })
