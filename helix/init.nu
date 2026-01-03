use ../nushell/modules/pathvar.nu *
use ../nushell/modules/do.nu *
use ../nushell/modules/files.nu *

let target = do auto {
  _: { pathvar xdg_config_home | path join helix }
}

let source = do auto {
  _: { pathvar workspace | path join helix }
}

export def install [] {
  symlink $target $source
}

export def uninstall [] {
  if ($target | path exists) {
    rm $target
  }
}
