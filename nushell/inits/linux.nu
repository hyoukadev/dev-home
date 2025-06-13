# Linux and WSL2
use std/util "path add"

path add ($nu.home-path | path join .local bin)
# /var/lib/flatpak/exports/share
# /home/ice/.local/share/flatpak/exports/share

const init_path = $nu.default-config-dir | path join inits
const mise_init_path = $init_path | path join mise.nu
source $mise_init_path

# mise activate | save ($nu.default-config-dir | path join mise.nu)
