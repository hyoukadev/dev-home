use ../nushell/modules/pathvar.nu *
use ../nushell/modules/do.nu *
use ../nushell/modules/files.nu *

let target = do auto {
  windows: { pathvar xdg_config_home | path join yazi config theme.toml }
  _: { pathvar xdg_config_home | path join yazi theme.toml }
}

let source = do auto {
  _: { pathvar workspace | path join yazi theme.toml }
}

export def install [] {
  # 1. Install themes if 'ya' command exists
  if (which ya | is-empty) {
    print "⚠️ 'ya' command not found, skipping theme installation."
  } else {
    print "🎨 Installing Yazi themes..."
    # Using 'do -i' to ignore errors if packages are already installed
    do -i { ya pack -a yazi-rs/flavors:catppuccin-latte }
    do -i { ya pack -a yazi-rs/flavors:catppuccin-frappe }
    do -i { ya pack -a yazi-rs/flavors:catppuccin-macchiato }
  }

  # 2. Link config file
  symlink $target $source
}

export def uninstall [] {
  if ($target | path exists) {
    rm $target
  }
}
