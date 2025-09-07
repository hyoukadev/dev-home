use ../nushell/modules/pathvar.nu 'pathvar workspace'
use ../nushell/modules/pathvar.nu 'pathvar autoload'

http get https://raw.githubusercontent.com/catppuccin/starship/refs/heads/main/starship.toml | save -f (pathvar workspace | path join starship starship.toml)

zoxide init nushell | save -f (pathvar autoload | path join zoxide.nu)

