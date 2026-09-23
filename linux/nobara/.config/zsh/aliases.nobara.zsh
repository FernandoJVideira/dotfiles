# =========================================================
# Package management (dnf)
# Ported from linux/arch/.config/zsh/aliases.arch.zsh (pacman) - same
# muscle-memory commands, dnf equivalents.
# =========================================================

# Full system upgrade
alias update='sudo dnf upgrade --refresh'

# Install a package
alias install='sudo dnf install'

# Search repos (name/description)
alias search='dnf search'

# Remove a package (dnf cleans up its own unused dependencies by default,
# unlike pacman - no -ns-style flag needed)
alias remove='sudo dnf remove'

# List explicitly installed packages (excludes dependencies)
alias pkglist='dnf history userinstalled'

# Remove orphaned packages (deps nothing else needs anymore)
alias orphans='sudo dnf autoremove'

# Clean the package cache of uninstalled/old versions
alias cleanup='sudo dnf clean packages'
