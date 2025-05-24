
# 1. install themes
# https://github.com/yazi-rs/flavors
ya pack -a yazi-rs/flavors:catppuccin-latte
ya pack -a yazi-rs/flavors:catppuccin-frappe
ya pack -a yazi-rs/flavors:catppuccin-macchiato


# 2. link config folder
let install_path = match $nu.os-info.family {
  "unix" => {
    $nu.home-path | path join .config yazi
  }
  "windows" => {
    $nu.data-dir | path dirname | path join yazi config
  }
  _ => {
    
  }
}

let theme_path_origin = $env.FILE_PWD | path join theme.toml
let theme_path_symlink = $install_path | path join theme.toml

print $install_path
print $theme_path_origin
print $theme_path_symlink

ln -s $theme_path_origin $theme_path_symlink
