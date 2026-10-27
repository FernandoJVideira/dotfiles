-- Caps Lock is a second Super key, except while a game has focus (then it is Caps Lock again).
-- Replaces Skein's default, which makes Caps the Compose key. ~/.local/bin/capslock-mode decides
-- what counts as a game on every focus change and switches the option to match.
hl.config({ input = { kb_options = "caps:super" } })

local script = os.getenv("HOME") .. "/.local/bin/capslock-mode"

hl.on("window.active", function()
  hl.exec_cmd(script)
end)

-- By hand, for a game the script doesn't recognise: force real Caps Lock, press again to undo.
hl.bind("SUPER + CTRL + F12", function()
  hl.exec_cmd(script .. " toggle")
end)
