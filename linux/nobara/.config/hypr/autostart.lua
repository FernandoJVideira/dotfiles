-- Hyprland here is started directly by the display manager (start-hyprland),
-- not uwsm, so nothing brings up graphical-session.target and
-- xdg-desktop-portal fails its Requisite on it (no screen share, no file
-- chooser). Start it once the session env is in systemd's manager.
hl.on("hyprland.start", function()
  hl.exec_cmd(
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE && systemctl --user start hyprland-session.target"
  )
end)
