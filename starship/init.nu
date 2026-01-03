use ../nushell/modules/pathvar.nu *
use ../nushell/modules/do.nu *
use ../nushell/modules/files.nu *

let target = do auto {
  _: { pathvar xdg_config_home | path join starship.toml }
}

let source = do auto {
  _: { pathvar workspace | path join starship starship.toml }
}

export def install [] {
  # 1. Download config if missing in repo
  if not ($source | path exists) {
    print "⬇️ Downloading Starship config..."
    http get https://raw.githubusercontent.com/catppuccin/starship/refs/heads/main/starship.toml | save -f $source
  }

  # 2. Link config file
  symlink $target $source

  # 3. Generate zoxide init script into nushell autoload directory (inside repo)
  let zoxide_init = (pathvar autoload | path join zoxide.nu)

  # Ensure autoload directory exists
  let autoload_dir = ($zoxide_init | path dirname)
  if not ($autoload_dir | path exists) {
    mkdir $autoload_dir
  }

  print "⚡ Generating zoxide init for nushell..."
  zoxide init nushell | save -f $zoxide_init
}

export def uninstall [] {
  if ($target | path exists) {
    rm $target
  }
}
