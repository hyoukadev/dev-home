const rime_to_create_macos = ($nu.home-path | path join Library Rime moran.custom.yaml)
const rime_to_create = ($nu.data-dir | path dirname | path join Rime moran.custom.yaml)
const rime_to_reference = ($nu.default-config-dir | path dirname | path join Rime moran.custom.yaml)

def link_rime_moran_custom [] {
  match $nu.os-info.name {
    "windows" => {
      # https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/mklink
      mklink $rime_to_create $rime_to_reference
    }
    "macos" => {
      ln -s $rime_to_reference $rime_to_create_macos 
    }
  }
}

def unlink_rime_moran_custom [] {
  match $nu.os-info.name {
    "windows" => {
      del $rime_to_create
    }
  }
}

# main
link_rime_moran_custom
