#!/usr/bin/env bash

# Hands the top of the screen to macOS's own menu bar (the application menus, Control Center, the other
# apps' status icons) and takes it back when macOS hides it again. The bar sits above that menu bar
# (topmost, so that clicks reach it), which means the menu bar can't be reached without getting out of
# its way. Opened by the menu button in the bar, the front app's name, or Alt+Shift+M (Hyprspace).
#
# Hiding the bar puts the pointer in the open: macOS slides its menu bar down while the pointer is in
# the top strip (give the pointer a nudge if it doesn't, within 6 seconds), and the bar comes back once the menu bar has
# slid away again, which it does only after the last menu is closed.

lock=/tmp/skein-menubar.lock
if ! mkdir "$lock" 2>/dev/null; then
  exit 0 # already running
fi
restore() {
  sketchybar --bar hidden=off
  rmdir "$lock" 2>/dev/null
}
trap restore EXIT

# macOS's menu bar is a window called "Menubar", parked at y = -39 (above the screen) while it is hidden
menubar_visible() {
  osascript -l JavaScript -e '
    ObjC.import("CoreGraphics");
    const list = ObjC.deepUnwrap(ObjC.castRefToObject($.CGWindowListCopyWindowInfo(0, 0)));
    const bar = list.find(w => w.kCGWindowName === "Menubar");
    bar && bar.kCGWindowBounds.Y > -20 ? "yes" : "no"' 2>/dev/null
}

sketchybar --bar hidden=on

# wait for macOS to show it (6 seconds, for a pointer that needs a nudge)
shown=0
SECONDS=0
while ((SECONDS < 6)); do
  if [[ "$(menubar_visible)" == yes ]]; then
    shown=1
    break
  fi
  sleep 0.2
done
((shown)) || exit 0

# ...and for it to go away again (two quiet checks in a row, for at most two minutes)
gone=0
SECONDS=0
while ((SECONDS < 120)); do
  sleep 0.3
  if [[ "$(menubar_visible)" == no ]]; then
    gone=$((gone + 1))
    ((gone >= 2)) && break
  else
    gone=0
  fi
done
exit 0
