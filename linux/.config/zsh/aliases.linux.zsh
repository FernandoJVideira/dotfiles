# =========================================================
# Package management (pacman)
# =========================================================

# Full system upgrade
alias update='sudo pacman -Syu'

# Install a package
alias install='sudo pacman -S'

# Search official repos (name/description)
alias search='pacman -Ss'

# Remove a package, its unused dependencies, and its config files
alias remove='sudo pacman -Rns'

# List explicitly installed packages (excludes dependencies)
alias pkglist='pacman -Qqe'

# Remove orphaned packages (deps nothing else needs anymore)
alias orphans='sudo pacman -Rns $(pacman -Qtdq)'

# Clean the package cache of uninstalled/old versions
alias cleanup='sudo pacman -Sc'

# =========================================================
# AUR (via yay)
# =========================================================

# Full upgrade including AUR packages
alias yayu='yay -Syu'

# Search AUR + official repos
alias yays='yay -Ss'
