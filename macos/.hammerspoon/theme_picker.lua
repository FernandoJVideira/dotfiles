-- A popup to pick a theme: a glass card in the current theme's colors, rounded, with a fuzzy-search
-- list where each theme has a thumbnail of its screenshot (a swatch of its palette when it has none).
-- Picking one runs `theme set`. The page is theme_picker.html, drawn in a borderless web view.
-- Opened by `open -g hammerspoon://theme`, which a Hyprspace key runs (macos/.config/hyprspace).
local M = {}

local home = os.getenv("HOME")
M.theme_bin = home .. "/.local/bin/theme"
M.skein_root = home .. "/.local/share/skein"
M.config_root = home .. "/.config/skein"
M.theme_roots = { M.skein_root .. "/themes", M.config_root .. "/themes" }
M.current_file = M.config_root .. "/current/theme.name"
M.colors_file = M.config_root .. "/current/theme/colors.toml"
M.html_file = hs.configdir .. "/theme_picker.html"
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

local function valid_hex(value)
  return type(value) == "string" and value:match("^#%x%x%x%x%x%x$") ~= nil
end

-- "r, g, b" of a color, for the page's rgba(var(--x), alpha)
local function triplet(hex)
  local c = rgb(hex)
  return string.format("%d, %d, %d", math.floor(c.red * 255 + 0.5), math.floor(c.green * 255 + 0.5), math.floor(c.blue * 255 + 0.5))
end

-- the palette as a strip of colors on the theme's background
local function swatch(colors)
  local w, h = 144, 90
  local canvas = hs.canvas.new({ x = 0, y = 0, w = w, h = h })
  canvas[1] = {
    type = "rectangle",
    action = "fill",
    fillColor = rgb(valid_hex(colors.background) and colors.background or "#222222"),
  }
  local strip = {}
  for _, key in ipairs({ "accent", "red", "yellow", "green", "cyan", "magenta" }) do
    if valid_hex(colors[key]) then
      strip[#strip + 1] = colors[key]
    end
  end
  local cell = (w - 18) / math.max(#strip, 1)
  for i, hex in ipairs(strip) do
    canvas[#canvas + 1] = {
      type = "rectangle",
      action = "fill",
      fillColor = rgb(hex),
      frame = { x = 9 + (i - 1) * cell, y = 30, w = cell, h = 30 },
    }
  end
  local image = canvas:imageFromCanvas()
  canvas:delete()
  return image
end

local thumbnails = {}

-- a data: URL, so the page needs no file access
local function thumbnail(theme, colors)
  local key = theme.name .. ":" .. (hs.fs.attributes(theme.dir .. "/preview.png") and "p" or "s")
  if thumbnails[key] then
    return thumbnails[key]
  end
  local url
  local png = theme.dir .. "/preview.png"
  if hs.fs.attributes(png) then
    local image = hs.image.imageFromPath(png)
    if image then
      url = image:setSize({ w = 144, h = 90 }):encodeAsURLString(true, "JPEG")
    end
  end
  url = url or swatch(colors):encodeAsURLString(true, "PNG")
  thumbnails[key] = url
  return url
end

-- The screenshots are left out of the sparse clone of the themes until something asks for them (the
-- `theme` menu fetches them all, once). Ask for them here too, in the background, so they are there
-- the next time the popup opens.
local previews_requested = false
local function request_previews(themes)
  if previews_requested or not hs.fs.attributes(M.skein_root .. "/.git") then
    return
  end
  for _, theme in ipairs(themes) do
    if theme.dir:find(M.theme_roots[1], 1, true) == 1 and not hs.fs.attributes(theme.dir .. "/preview.png") then
      previews_requested = true
      hs.task.new("/usr/bin/git", nil, { "-C", M.skein_root, "sparse-checkout", "add", "/themes/*/preview.png" }):start()
      return
    end
  end
end

function M.current_name()
  return (read(M.current_file) or ""):gsub("%s+$", "")
end

-- one entry per theme, for the page
function M.choices()
  local current = M.current_name()
  local themes = M.themes()
  request_previews(themes)
  local choices = {}
  for _, theme in ipairs(themes) do
    local colors = M.parse_colors(read(theme.dir .. "/colors.toml") or "")
    choices[#choices + 1] = {
      name = theme.name,
      mode = colors.mode or "dark",
      current = theme.name == current,
      thumb = thumbnail(theme, colors),
    }
  end
  return choices, current
end

local function luminance(hex)
  local c = rgb(hex)
  return 0.2126 * c.red + 0.7152 * c.green + 0.0722 * c.blue
end

-- the card takes the current theme's background, text and accent
function M.palette()
  local colors = M.parse_colors(read(M.colors_file) or "")
  local background = valid_hex(colors.background) and colors.background or "#1e1e1e"
  local foreground = valid_hex(colors.foreground) and colors.foreground or "#eeeeee"
  local accent = valid_hex(colors.accent) and colors.accent or "#7aa2f7"
  local dark
  if colors.mode then
    dark = colors.mode ~= "light"
  else
    dark = luminance(background) < 0.5
  end
  return dark,
    string.format(
      "--bg: %s; --fg: %s; --accent: %s; --sheen: %s; --rim: %s; --rim-top: %s;",
      triplet(background),
      triplet(foreground),
      triplet(accent),
      dark and "0.20" or "0.55",
      dark and "0.26" or "0.70",
      dark and "0.50" or "0.95"
    )
end

function M.render()
  local template = read(M.html_file)
  if not template then
    return nil
  end
  local choices = M.choices()
  local dark, vars = M.palette()
  -- "</" would end the script block early
  local data = hs.json.encode(choices):gsub("</", "<\\/")
  local html = template
  html = html:gsub("/%*MODE%*/", function() return dark and "dark" or "light" end)
  html = html:gsub("/%*VARS%*/", function() return vars end)
  html = html:gsub("/%*DATA%*/ null", function() return data end)
  return html
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

local view
local previous_app
local ready = false

function M.visible()
  return view ~= nil
end

function M.hide()
  ready = false
  if view then
    view:delete()
    view = nil
  end
  if previous_app then
    previous_app:activate()
    previous_app = nil
  end
end

-- the page talks to us through window.webkit.messageHandlers.picker
local function on_message(message)
  local body = message.body or {}
  if body.action == "pick" and type(body.name) == "string" then
    local current = M.current_name()
    -- hide on the next turn: this runs inside the page's own message
    hs.timer.doAfter(0, function()
      M.hide()
      if body.name ~= current then
        apply(body.name)
      end
    end)
  elseif body.action == "close" then
    hs.timer.doAfter(0, M.hide)
  end
end

function M.show()
  if view then
    M.hide()
    return
  end
  local html = M.render()
  if not html then
    hs.notify.new({ title = "Theme", informativeText = "theme_picker.html is missing from ~/.hammerspoon" }):send()
    return
  end

  -- the glass is 700 wide: the search pill (86 high), a 16 gap and the results (up to 538); the window
  -- leaves 56px around it for the shadows (see the page). It sits in the upper part of the screen.
  local w, h = 812, 752
  local frame = hs.screen.mainScreen():frame()
  local rect = { x = frame.x + (frame.w - w) / 2, y = frame.y + frame.h * 0.14, w = w, h = h }

  previous_app = hs.application.frontmostApplication()
  local content = hs.webview.usercontent.new("picker"):setCallback(on_message)
  view = hs.webview.new(rect, {}, content)
  view:windowStyle({ "borderless" })
    :allowTextEntry(true)
    :transparent(true)
    :shadow(false)
    :level(hs.drawing.windowLevels.modalPanel)
    :behavior(hs.drawing.windowBehaviors.moveToActiveSpace)
    :windowCallback(function(action, _, state)
      -- clicking elsewhere closes it; the first moments are ignored while it takes focus
      if action == "focusChange" and state == false and ready then
        hs.timer.doAfter(0, M.hide)
      end
    end)
    :html(html)
    :show()
  hs.focus()
  hs.timer.doAfter(0.05, function()
    if view then
      view:bringToFront(true)
      local win = view:hswindow()
      if win then
        win:focus()
      end
      view:evaluateJavaScript("window.focusSearch && window.focusSearch()")
    end
  end)
  hs.timer.doAfter(0.6, function()
    ready = true
  end)
end

return M
