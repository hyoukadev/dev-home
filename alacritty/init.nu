use ../nushell/modules/pathvar.nu *
use ../nushell/modules/do.nu *
use ../nushell/modules/files.nu *

let link = do auto {
  _: { pathvar xdg_config_home | path join alacritty }
}

let original = do auto {
  _: { pathvar workspace | path join alacritty }
}


def link_alacritty [] {
  do auto {
    unix: {
      symlink ($original | path join alacritty.toml) ($original | path join alacritty.unix.toml)
    }
    windows: {
      symlink ($original | path join alacritty.toml) ($original | path join alacritty.windows.toml)
    }
  }

  symlink $link $original
}

def unlink_alacritty [] {
  rm $link
}
