use ../nushell/modules/pathvar.nu 'pathvar workspace'
http get https://raw.githubusercontent.com/catppuccin/starship/refs/heads/main/starship.toml | save -f (pathvar workspace | path join starship starship.toml)
