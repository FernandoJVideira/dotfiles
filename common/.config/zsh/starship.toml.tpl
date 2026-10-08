# Themed variant of starship.toml: same layout and glyphs, with the colors taken
# from the current OS theme. This is a template, not a config: starship-theme-sync
# (run by the theme-set hook on Arch/Omarchy and Nobara/Omadora) fills in the
# double-brace placeholders and writes ~/.local/state/starship/starship.toml, which
# .zshenv prefers over the static file when it exists.
#   accent / background / foreground  straight from the theme's colors.toml
#   surface  background nudged toward the foreground (directory pill)
#   dim      halfway between them (the fill line)
#   error    the theme's red

# Don't print a new line at the start of the prompt
add_newline = false
# Pipes ╰─ ╭─
# Powerline symbols                                     
# Wedges 🭧🭒 🭣🭧🭓
# Random noise 🬖🬥🬔🬗
# Cool stuff 󰜥   

# format = """
# $directory $fill $git_branch $cmd_duration
#  $character"""
format = """
$cmd_duration $directory$git_branch
  $character"""

[fill]
symbol = '-'
style = 'fg:{{ dim }}'

# Replace the "❯" symbol in the prompt with "➜"
[character]                            # The name of the module we are configuring is "character"
success_symbol = "[ ](bold fg:{{ accent }})"
error_symbol = "[ ](bold fg:{{ error }})"

# Disable the package module, hiding it from the prompt completely
[package]
disabled = true

[git_branch]
style = "bg:{{ accent }}"
symbol = "󰘬"
truncation_length = 12
truncation_symbol = ""
format = " 󰜥 [](bold fg:{{ accent }})[$symbol $branch(:$remote_branch)](fg:{{ background }} bg:{{ accent }})[ ](bold fg:{{ accent }})"

[git_commit]
commit_hash_length = 4
tag_symbol = " "

[git_state]
format = '[\($state( $progress_current of $progress_total)\)]($style) '
cherry_pick = "[🍒 PICKING](bold red)"

[git_status]
conflicted = " 🏳 "
ahead = " 🏎💨 "
behind = " 😰 "
diverged = " 😵 "
untracked = " 🤷 ‍"
stashed = " 📦 "
modified = " 📝 "
staged = '[++\($count\)](green)'
renamed = " ✍️ "
deleted = " 🗑 "

[hostname]
ssh_only = false
format =  "[•$hostname](bg:{{ accent }} bold fg:{{ background }})[](bold fg:{{ accent }})"
trim_at = ".companyname.com"
disabled = false

[line_break]
disabled = false

[memory_usage]
disabled = true
threshold = -1
symbol = " "
style = "bold dimmed green"

[time]
disabled = true
format = '🕙[\[ $time \]]($style) '
time_format = "%T"

[username]
style_user = "bold bg:{{ accent }} fg:{{ background }}"
style_root = "red bold"
format = "[](bold fg:{{ accent }})[$user]($style)"
disabled = false
show_always = true

[directory]
home_symbol = " "
read_only = "  "
style = "bg:{{ surface }} fg:{{ foreground }}"
truncation_length = 2
truncation_symbol = ".../"
format = '[](bold fg:{{ surface }})[󰉋 → $path]($style)[](bold fg:{{ surface }})'


[directory.substitutions]
"Desktop" = "  "
"Documents" = "  "
"Downloads" = "  "
"Music" = " 󰎈 "
"Pictures" = "  "
"Videos" = "  "
"GitHub" = " 󰊤 "

[cmd_duration]
min_time = 0
format = '[](bold fg:{{ accent }})[󰪢 $duration](bold bg:{{ accent }} fg:{{ background }})[](bold fg:{{ accent }})'
