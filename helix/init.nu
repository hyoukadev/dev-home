use ../nushell/modules/pathvar.nu *
use ../nushell/modules/do.nu *
use ../nushell/modules/files.nu *

let link = do auto {
  _: { pathvar xdg_config_home | path join helix }
}

let original = do auto {
  _: { pathvar workspace | path join helix }
}


def link_helix [] {
  symlink $link $original
}

def unlink_helix [] {
  rm $link
}
