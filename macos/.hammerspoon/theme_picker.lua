-- A popup to pick a theme: a centered fuzzy-search list where each theme has a thumbnail of its
-- screenshot (a swatch of its palette when it has none), then `theme set` for the one you pick.
-- Opened by `open -g hammerspoon://theme`, which a Hyprspace key runs (macos/.config/hyprspace).
local M = {}

local home = os.getenv("HOME")
M.theme_bin = home .. "/.local/bin/theme"
M.theme_roots = { home .. "/.local/share/omadora/themes", home .. "/.config/omadora/themes" }
M.current_file = home .. "/.config/omadora/current/theme.name"
M.path = "/opt/homebrew/bin:/opt/homebrew/sbin:" .. home .. "/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

-- "key = "#rrggbb"" and `mode = "dark"` lines of a theme's colors.toml
function M.parse_colors(text)
  local colors = {}
  for key, value in text:gmatch('([%w_]+)%s*=%s*"([^"]*)"') do
    colors[key] = value
  end
  return colors
end

local function read(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local text = f:read("*a")
  f:close()
  return text
end

-- every theme that has a colors.toml, with the folder it lives in; a theme in two roots
-- (a user theme next to a built-in one) is listed once, the later root winning
function M.themes()
  local found, order = {}, {}
  for _, root in ipairs(M.theme_roots) do
    local iter, dir = hs.fs.dir(root)
    if iter then
      for name in iter, dir do
        if name:sub(1, 1) ~= "." and hs.fs.attributes(root .. "/" .. name .. "/colors.toml") then
          if not found[name] then
            order[#order + 1] = name
          end
          found[name] = root .. "/" .. name
        end
      end
    end
  end
  table.sort(order)
  local list = {}
  for _, name in ipairs(order) do
    list[#list + 1] = { name = name, dir = found[name] }
  end
  return list
end

local function rgb(hex)
  hex = hex:gsub("#", "")
  return {
    red = tonumber(hex:sub(1, 2), 16) / 255,
    green = tonumber(hex:sub(3, 4), 16) / 255,
    blue = tonumber(hex:sub(5, 6), 16) / 255,
    alpha = 1,
  }
end

-- the palette as a strip of colors on the theme's background
local function swatch(colors)
  local w, h = 96, 60
  local canvas = hs.canvas.new({ x = 0, y = 0, w = w, h = h })
  canvas[1] = { type = "rectangle", action = "fill", fillColor = rgb(colors.background or "#222222") }
  local strip = {}
  for _, key in ipairs({ "accent", "red", "yellow", "green", "cyan", "magenta" }) do
    if colors[key] and colors[key]:match("^#%x%x%x%x%x%x$") then
      strip[#strip + 1] = colors[key]
    end
  end
  local cell = (w - 12) / math.max(#strip, 1)
  for i, hex in ipairs(strip) do
    canvas[#canvas + 1] = {
      type = "rectangle",
      action = "fill",
      fillColor = rgb(hex),
      frame = { x = 6 + (i - 1) * cell, y = 20, w = cell, h = 20 },
    }
  end
  local image = canvas:imageFromCanvas()
  canvas:delete()
  return image
end

local thumbnails = {}

local function thumbnail(theme, colors)
  if thumbnails[theme.name] then
    return thumbnails[theme.name]
  end
  local image
  local png = theme.dir .. "/preview.png"
  if hs.fs.attributes(png) then
    image = hs.image.imageFromPath(png)
    if image then
      image = image:setSize({ w = 96, h = 60 })
    end
  end
  image = image or swatch(colors)
  thumbnails[theme.name] = image
  return image
end

function M.choices()
  local current = (read(M.current_file) or ""):gsub("%s+$", "")
  local choices = {}
  for _, theme in ipairs(M.themes()) do
    local colors = M.parse_colors(read(theme.dir .. "/colors.toml") or "")
    choices[#choices + 1] = {
      text = theme.name,
      subText = (theme.name == current and "current, " or "") .. (colors.mode or "dark"),
      image = thumbnail(theme, colors),
      name = theme.name,
    }
  end
  return choices, current
end

local function apply(name)
  local task = hs.task.new("/usr/bin/env", function(code, _, err)
    if code == 0 then
      hs.notify.new({ title = "Theme", informativeText = "Now using " .. name }):send()
    else
      hs.notify.new({ title = "Theme", informativeText = "Couldn't apply " .. name .. ": " .. (err or "") }):send()
    end
  end, { "PATH=" .. M.path, M.theme_bin, "set", name })
  task:start()
end

local chooser
local current_theme

function M.show()
  local choices
  choices, current_theme = M.choices()
  if not chooser then
    chooser = hs.chooser.new(function(choice)
      if choice and choice.name ~= current_theme then
        apply(choice.name)
      end
    end)
    chooser:rows(9):width(32):searchSubText(true):placeholderText("Pick a theme")
  end
  chooser:choices(choices)
  chooser:show()
end

function M.visible()
  return chooser ~= nil and chooser:isVisible()
end

function M.hide()
  if chooser then
    chooser:hide()
  end
end

return M
