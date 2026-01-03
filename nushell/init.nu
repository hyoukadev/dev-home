use ../nushell/modules/pathvar.nu *
use ../nushell/modules/do.nu *
use ../nushell/modules/files.nu *

let target = do auto {
  macos: { $nu.home-path | path join Library nushell }
  _: { pathvar xdg_config_home | path join nushell }
}

let source = do auto {
  _: { pathvar workspace | path join nushell }
}

export def install [] {
  symlink $target $source
}

export def uninstall [] {
  if ($target | path exists) {
    rm $target
  }
}
