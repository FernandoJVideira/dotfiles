# fonts

Drop licensed font files (`.ttf`, `.otf`) here; they are gitignored because this repo is public.
`lib/fonts.sh` installs them on every OS (`~/.local/share/fonts/dotfiles` on Linux,
`~/Library/Fonts` on macOS). Copy `DankMono-*.ttf` here on each new machine before `./bootstrap.sh`;
without it the terminals and Zed fall back to JetBrainsMono Nerd Font.
