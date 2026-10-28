# Colors for the macOS bar and window borders, rendered from the current theme
# (macos/.config/skein/themed/macos-colors.sh.tpl). Sourced by sketchybarrc, its
# plugins, Hyprspace's startup command and the sketchybar-sync hook. 0xAARRGGBB.
export CLR_BG=0x00000000                       # transparent bar background
export CLR_BAR_BG=0xff{{ background_strip }}   # the bar itself: the theme's background, like Skein's
export CLR_ALERT=0xffa55555                    # Skein's alert red (low battery)
export CLR_COMP_BG=0xff{{ lighter_background_strip }}
export CLR_COMP_BORDER=0xff{{ muted_strip }}
export CLR_FG=0xff{{ foreground_strip }}
export CLR_ACCENT=0xff{{ accent_strip }}       # focused workspace
export CLR_FG_DIM=0x77{{ foreground_strip }}   # unfocused workspaces
export CLR_GREEN=0xff{{ green_strip }}
export CLR_CYAN=0xff{{ cyan_strip }}
export CLR_ORANGE=0xff{{ orange_strip }}
export CLR_YELLOW=0xff{{ yellow_strip }}
export CLR_RED=0xff{{ red_strip }}
export BORDER_ACTIVE=0xff{{ accent_strip }}
export BORDER_INACTIVE=0x77{{ muted_strip }}
