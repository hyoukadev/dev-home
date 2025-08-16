# Linux and WSL2
use std/util "path add"

path add ($nu.home-path | path join .local bin)
# /var/lib/flatpak/exports/share
# /home/ice/.local/share/flatpak/exports/share

# mise activate | save ($nu.default-config-dir | path join mise.nu)
