use ../nushell/modules/pathvar.nu *
use ../nushell/modules/do.nu *
use ../nushell/modules/files.nu *

let link = do auto {
  macos: { $nu.home-path | path join Library nushell }
  _: { pathvar xdg_config_home | path join nushell }
}

let original = do auto {
  _: { pathvar workspace | path join nushell }
}


def link_helix [] {
  symlink $link $original
}

def unlink_helix [] {
  rm $link
}
