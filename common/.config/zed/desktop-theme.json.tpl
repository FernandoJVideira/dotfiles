{
  "$schema": "https://zed.dev/schema/themes/v0.2.0.json",
  "name": "Desktop Theme",
  "author": "dotfiles (colors from the OS theme; structure derived from Zed's MIT-licensed Gruvbox theme)",
  "themes": [
    {
      "name": "Desktop Theme",
      "appearance": "{{ mode }}",
      "style": {
        "accents": [
          "{{ red }}ff",
          "{{ green }}ff",
          "{{ yellow }}ff",
          "{{ blue }}ff",
          "{{ magenta }}ff",
          "{{ cyan }}ff",
          "{{ orange }}ff"
        ],
        "border": "{{ mix background foreground 25 }}ff",
        "border.variant": "{{ mix background foreground 16 }}ff",
        "border.focused": "{{ mix background foreground 7 }}ff",
        "border.selected": "{{ mix background foreground 7 }}ff",
        "border.transparent": "#00000000",
        "border.disabled": "{{ mix background foreground 21 }}ff",
        "elevated_surface.background": "{{ mix background foreground 9 }}ff",
        "surface.background": "{{ mix background foreground 9 }}ff",
        "background": "{{ mix background foreground 18 }}ff",
        "element.background": "{{ mix background foreground 9 }}ff",
        "element.hover": "{{ mix background foreground 16 }}ff",
        "element.active": "{{ mix background foreground 25 }}ff",
        "element.selected": "{{ mix background foreground 25 }}ff",
        "element.disabled": "{{ mix background foreground 9 }}ff",
        "drop_target.background": "{{ mix background foreground 80 }}80",
        "ghost_element.background": "#00000000",
        "ghost_element.hover": "{{ mix background foreground 16 }}ff",
        "ghost_element.active": "{{ mix background foreground 25 }}ff",
        "ghost_element.selected": "{{ mix background foreground 25 }}ff",
        "ghost_element.disabled": "{{ mix background foreground 9 }}ff",
        "text": "{{ bright_foreground }}ff",
        "text.muted": "{{ mix background foreground 80 }}ff",
        "text.placeholder": "{{ mix background foreground 57 }}ff",
        "text.disabled": "{{ mix background foreground 57 }}ff",
        "text.accent": "{{ accent }}ff",
        "icon": "{{ bright_foreground }}ff",
        "icon.muted": "{{ mix background foreground 80 }}ff",
        "icon.disabled": "{{ mix background foreground 57 }}ff",
        "icon.placeholder": "{{ mix background foreground 80 }}ff",
        "icon.accent": "{{ accent }}ff",
        "status_bar.background": "{{ mix background foreground 18 }}ff",
        "title_bar.background": "{{ mix background foreground 18 }}ff",
        "title_bar.inactive_background": "{{ mix background foreground 9 }}ff",
        "toolbar.background": "{{ background }}ff",
        "tab_bar.background": "{{ mix background foreground 9 }}ff",
        "tab.inactive_background": "{{ mix background foreground 9 }}ff",
        "tab.active_background": "{{ background }}ff",
        "search.match_background": "{{ accent }}66",
        "search.active_match_background": "{{ yellow }}66",
        "panel.background": "{{ mix background foreground 9 }}ff",
        "panel.focused_border": "{{ accent }}ff",
        "pane.focused_border": null,
        "scrollbar.thumb.active_background": "{{ accent }}ac",
        "scrollbar.thumb.hover_background": "{{ bright_foreground }}4c",
        "scrollbar.thumb.background": "{{ mix background foreground 65 }}4c",
        "scrollbar.thumb.border": "{{ mix background foreground 16 }}ff",
        "scrollbar.track.background": "#00000000",
        "scrollbar.track.border": "{{ mix background foreground 7 }}ff",
        "editor.foreground": "{{ foreground }}ff",
        "editor.background": "{{ background }}ff",
        "editor.gutter.background": "{{ background }}ff",
        "editor.subheader.background": "{{ mix background foreground 9 }}ff",
        "editor.active_line.background": "{{ mix background foreground 9 }}bf",
        "editor.highlighted_line.background": "{{ mix background foreground 9 }}ff",
        "editor.line_number": "{{ mix background foreground 37 }}",
        "editor.active_line_number": "{{ bright_foreground }}",
        "editor.hover_line_number": "{{ mix background bright_foreground 82 }}",
        "editor.invisible": "{{ mix background foreground 53 }}ff",
        "editor.wrap_guide": "{{ bright_foreground }}0d",
        "editor.active_wrap_guide": "{{ bright_foreground }}1a",
        "editor.document_highlight.read_background": "{{ accent }}1a",
        "editor.document_highlight.write_background": "{{ mix background foreground 53 }}66",
        "terminal.background": "{{ background }}ff",
        "terminal.foreground": "{{ foreground }}ff",
        "terminal.bright_foreground": "{{ bright_foreground }}ff",
        "terminal.dim_foreground": "{{ mix background foreground 39 }}ff",
        "terminal.ansi.black": "{{ background }}ff",
        "terminal.ansi.bright_black": "{{ mix background foreground 53 }}ff",
        "terminal.ansi.dim_black": "{{ bright_foreground }}ff",
        "terminal.ansi.red": "{{ red }}ff",
        "terminal.ansi.bright_red": "{{ bright_red }}ff",
        "terminal.ansi.dim_red": "{{ mix darker_background red 63 }}ff",
        "terminal.ansi.green": "{{ green }}ff",
        "terminal.ansi.bright_green": "{{ bright_green }}ff",
        "terminal.ansi.dim_green": "{{ mix darker_background green 69 }}ff",
        "terminal.ansi.yellow": "{{ yellow }}ff",
        "terminal.ansi.bright_yellow": "{{ bright_yellow }}ff",
        "terminal.ansi.dim_yellow": "{{ mix darker_background yellow 60 }}ff",
        "terminal.ansi.blue": "{{ blue }}ff",
        "terminal.ansi.bright_blue": "{{ bright_blue }}ff",
        "terminal.ansi.dim_blue": "{{ mix darker_background blue 57 }}ff",
        "terminal.ansi.magenta": "{{ magenta }}ff",
        "terminal.ansi.bright_magenta": "{{ bright_magenta }}ff",
        "terminal.ansi.dim_magenta": "{{ mix darker_background magenta 62 }}ff",
        "terminal.ansi.cyan": "{{ cyan }}ff",
        "terminal.ansi.bright_cyan": "{{ bright_cyan }}ff",
        "terminal.ansi.dim_cyan": "{{ mix background cyan 41 }}ff",
        "terminal.ansi.white": "{{ mix background foreground 65 }}ff",
        "terminal.ansi.bright_white": "{{ bright_foreground }}ff",
        "terminal.ansi.dim_white": "{{ mix background foreground 39 }}ff",
        "link_text.hover": "{{ accent }}ff",
        "version_control.added": "{{ bright_green }}ff",
        "version_control.modified": "{{ bright_yellow }}ff",
        "version_control.deleted": "{{ bright_red }}ff",
        "conflict": "{{ bright_yellow }}ff",
        "conflict.background": "{{ mix darker_background orange 36 }}ff",
        "conflict.border": "{{ mix background orange 48 }}ff",
        "created": "{{ bright_green }}ff",
        "created.background": "{{ mix darker_background orange 18 }}ff",
        "created.border": "{{ mix darker_background green 38 }}ff",
        "deleted": "{{ bright_red }}ff",
        "deleted.background": "{{ mix darker_background red 30 }}ff",
        "deleted.border": "{{ mix darker_background red 45 }}ff",
        "error": "{{ bright_red }}ff",
        "error.background": "{{ mix darker_background red 30 }}ff",
        "error.border": "{{ mix darker_background red 45 }}ff",
        "hidden": "{{ mix background foreground 57 }}ff",
        "hidden.background": "{{ mix background foreground 18 }}ff",
        "hidden.border": "{{ mix background foreground 21 }}ff",
        "hint": "{{ mix darker_background bright_foreground 53 }}ff",
        "hint.background": "{{ mix background darker_background 80 }}ff",
        "hint.border": "{{ mix background foreground 7 }}ff",
        "ignored": "{{ mix background foreground 57 }}ff",
        "ignored.background": "{{ mix background foreground 18 }}ff",
        "ignored.border": "{{ mix background foreground 25 }}ff",
        "info": "{{ bright_blue }}ff",
        "info.background": "{{ mix background darker_background 80 }}ff",
        "info.border": "{{ mix background foreground 7 }}ff",
        "modified": "{{ bright_yellow }}ff",
        "modified.background": "{{ mix darker_background orange 36 }}ff",
        "modified.border": "{{ mix background orange 48 }}ff",
        "predictive": "{{ mix background foreground 40 }}ff",
        "predictive.background": "{{ mix darker_background orange 18 }}ff",
        "predictive.border": "{{ mix darker_background green 38 }}ff",
        "renamed": "{{ bright_blue }}ff",
        "renamed.background": "{{ mix background darker_background 80 }}ff",
        "renamed.border": "{{ mix background foreground 7 }}ff",
        "success": "{{ bright_green }}ff",
        "success.background": "{{ mix darker_background orange 18 }}ff",
        "success.border": "{{ mix darker_background green 38 }}ff",
        "unreachable": "{{ mix background foreground 80 }}ff",
        "unreachable.background": "{{ mix background foreground 18 }}ff",
        "unreachable.border": "{{ mix background foreground 25 }}ff",
        "warning": "{{ bright_yellow }}ff",
        "warning.background": "{{ mix darker_background orange 36 }}ff",
        "warning.border": "{{ mix background orange 48 }}ff",
        "players": [
          {
            "cursor": "{{ accent }}ff",
            "background": "{{ accent }}ff",
            "selection": "{{ accent }}3d"
          },
          {
            "cursor": "{{ mix background foreground 65 }}ff",
            "background": "{{ mix background foreground 65 }}ff",
            "selection": "{{ mix background foreground 65 }}3d"
          },
          {
            "cursor": "{{ orange }}ff",
            "background": "{{ orange }}ff",
            "selection": "{{ orange }}3d"
          },
          {
            "cursor": "{{ bright_magenta }}ff",
            "background": "{{ bright_magenta }}ff",
            "selection": "{{ bright_magenta }}3d"
          },
          {
            "cursor": "{{ bright_cyan }}ff",
            "background": "{{ bright_cyan }}ff",
            "selection": "{{ bright_cyan }}3d"
          },
          {
            "cursor": "{{ bright_red }}ff",
            "background": "{{ bright_red }}ff",
            "selection": "{{ bright_red }}3d"
          },
          {
            "cursor": "{{ bright_yellow }}ff",
            "background": "{{ bright_yellow }}ff",
            "selection": "{{ bright_yellow }}3d"
          },
          {
            "cursor": "{{ bright_green }}ff",
            "background": "{{ bright_green }}ff",
            "selection": "{{ bright_green }}3d"
          }
        ],
        "syntax": {
          "attribute": {
            "color": "{{ bright_blue }}ff",
            "font_style": null,
            "font_weight": null
          },
          "boolean": {
            "color": "{{ bright_magenta }}ff",
            "font_style": null,
            "font_weight": null
          },
          "comment": {
            "color": "{{ mix background foreground 65 }}ff",
            "font_style": null,
            "font_weight": null
          },
          "comment.doc": {
            "color": "{{ mix background foreground 80 }}ff",
            "font_style": null,
            "font_weight": null
          },
          "constant": {
            "color": "{{ bright_yellow }}ff",
            "font_style": null,
            "font_weight": null
          },
          "constructor": {
            "color": "{{ bright_blue }}ff",
            "font_style": null,
            "font_weight": null
          },
          "embedded": {
            "color": "{{ bright_cyan }}ff",
            "font_style": null,
            "font_weight": null
          },
          "emphasis": {
            "color": "{{ bright_blue }}ff",
            "font_style": null,
            "font_weight": null
          },
          "emphasis.strong": {
            "color": "{{ bright_blue }}ff",
            "font_style": null,
            "font_weight": 700
          },
          "enum": {
            "color": "{{ orange }}ff",
            "font_style": null,
            "font_weight": null
          },
          "function": {
            "color": "{{ bright_green }}ff",
            "font_style": null,
            "font_weight": null
          },
          "function.builtin": {
            "color": "{{ bright_red }}ff",
            "font_style": null,
            "font_weight": null
          },
          "hint": {
            "color": "{{ mix darker_background bright_foreground 53 }}ff",
            "font_style": null,
            "font_weight": null
          },
          "keyword": {
            "color": "{{ bright_red }}ff",
            "font_style": null,
            "font_weight": null
          },
          "label": {
            "color": "{{ bright_blue }}ff",
            "font_style": null,
            "font_weight": null
          },
          "link_text": {
            "color": "{{ bright_cyan }}ff",
            "font_style": "italic",
            "font_weight": null
          },
          "link_uri": {
            "color": "{{ bright_magenta }}ff",
            "font_style": null,
            "font_weight": null
          },
          "namespace": {
            "color": "{{ bright_blue }}ff",
            "font_style": null,
            "font_weight": null
          },
          "number": {
            "color": "{{ bright_magenta }}ff",
            "font_style": null,
            "font_weight": null
          },
          "operator": {
            "color": "{{ bright_cyan }}ff",
            "font_style": null,
            "font_weight": null
          },
          "predictive": {
            "color": "{{ mix background foreground 40 }}ff",
            "font_style": "italic",
            "font_weight": null
          },
          "preproc": {
            "color": "{{ bright_red }}ff",
            "font_style": null,
            "font_weight": null
          },
          "primary": {
            "color": "{{ foreground }}ff",
            "font_style": null,
            "font_weight": null
          },
          "property": {
            "color": "{{ foreground }}ff",
            "font_style": null,
            "font_weight": null
          },
          "punctuation": {
            "color": "{{ mix background foreground 88 }}ff",
            "font_style": null,
            "font_weight": null
          },
          "punctuation.bracket": {
            "color": "{{ mix background foreground 65 }}ff",
            "font_style": null,
            "font_weight": null
          },
          "punctuation.delimiter": {
            "color": "{{ mix background foreground 97 }}ff",
            "font_style": null,
            "font_weight": null
          },
          "punctuation.list_marker": {
            "color": "{{ foreground }}ff",
            "font_style": null,
            "font_weight": null
          },
          "punctuation.markup": {
            "color": "{{ bright_blue }}ff",
            "font_style": null,
            "font_weight": null
          },
          "punctuation.special": {
            "color": "{{ mix background foreground 97 }}ff",
            "font_style": null,
            "font_weight": null
          },
          "selector": {
            "color": "{{ bright_yellow }}ff",
            "font_style": null,
            "font_weight": null
          },
          "selector.pseudo": {
            "color": "{{ bright_blue }}ff",
            "font_style": null,
            "font_weight": null
          },
          "string": {
            "color": "{{ bright_green }}ff",
            "font_style": null,
            "font_weight": null
          },
          "string.escape": {
            "color": "{{ mix background foreground 80 }}ff",
            "font_style": null,
            "font_weight": null
          },
          "string.regex": {
            "color": "{{ orange }}ff",
            "font_style": null,
            "font_weight": null
          },
          "string.special": {
            "color": "{{ bright_magenta }}ff",
            "font_style": null,
            "font_weight": null
          },
          "string.special.symbol": {
            "color": "{{ bright_cyan }}ff",
            "font_style": null,
            "font_weight": null
          },
          "tag": {
            "color": "{{ bright_cyan }}ff",
            "font_style": null,
            "font_weight": null
          },
          "text.literal": {
            "color": "{{ bright_blue }}ff",
            "font_style": null,
            "font_weight": null
          },
          "title": {
            "color": "{{ bright_green }}ff",
            "font_style": null,
            "font_weight": 700
          },
          "type": {
            "color": "{{ bright_yellow }}ff",
            "font_style": null,
            "font_weight": null
          },
          "variable": {
            "color": "{{ foreground }}ff",
            "font_style": null,
            "font_weight": null
          },
          "variable.parameter": {
            "color": "{{ foreground }}ff",
            "font_style": null,
            "font_weight": null
          },
          "variable.special": {
            "color": "{{ bright_blue }}ff",
            "font_style": null,
            "font_weight": null
          },
          "variant": {
            "color": "{{ bright_blue }}ff",
            "font_style": null,
            "font_weight": null
          },
          "diff.plus": {
            "color": "{{ bright_green }}ff",
            "font_style": null,
            "font_weight": null
          },
          "diff.minus": {
            "color": "{{ bright_red }}ff",
            "font_style": null,
            "font_weight": null
          }
        }
      }
    }
  ]
}
