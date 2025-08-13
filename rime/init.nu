use ../nushell/modules/pathvar.nu *
use ../nushell/modules/do.nu *
use ../nushell/modules/files.nu *

let link = do auto {
  "macos": { pathvar home | path join Library Rime moran.custom.yaml }
  _: { pathvar xdg_config_home | path join Rime moran.custom.yaml }
}

let original = do auto {
  _: { pathvar workspace | path join rime moran.custom.yaml }
}


def link_rime_moran_custom [] {
  symlink $link $original
}
