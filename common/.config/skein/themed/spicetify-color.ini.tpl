; Spotify colors for the Spicetify theme "skein" (common/.config/spicetify/Themes/skein),
; rendered from the current theme by Skein's template engine (the same one on Linux and
; macOS) into current/theme/spicetify-color.ini. spicetify-theme-sync copies it next to
; user.css as color.ini and applies it. Values are hex without the leading '#'.
[skein]
text               = {{ foreground_strip }}
subtext            = {{ mix_strip foreground background 30 }}
button-text        = {{ background_strip }}
subbutton-text     = {{ foreground_strip }}
main               = {{ background_strip }}
main-elevated      = {{ lighter_background_strip }}
highlight          = {{ lighter_background_strip }}
highlight-elevated = {{ selection_strip }}
sidebar            = {{ dark_background_strip }}
player             = {{ dark_background_strip }}
card               = {{ lighter_background_strip }}
shadow             = {{ darker_background_strip }}
selected-row       = {{ selection_strip }}
sub-button         = {{ foreground_strip }}
button             = {{ accent_strip }}
button-active      = {{ mix_strip accent bright_foreground 25 }}
button-disabled    = {{ muted_strip }}
sidebar-button     = {{ foreground_strip }}
play-button        = {{ accent_strip }}
tab-active         = {{ lighter_background_strip }}
notification       = {{ lighter_background_strip }}
notification-error = {{ red_strip }}
playback-bar       = {{ accent_strip }}
misc               = {{ muted_strip }}
