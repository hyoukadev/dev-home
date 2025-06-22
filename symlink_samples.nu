
# wezterm symlink
def link_wezterm [] {
  match (sys host | get name) {
    "Darwin" => {
      ln -s $"($nu.default-config-dir | path dirname | path join wezterm)" $"($nu.home-path | path join .config wezterm)"
    }

    "Linux" => {
      ln -s $"($nu.default-config-dir | path dirname | path join wezterm )" $"($nu.data-dir | path dirname | path join wezterm)"
    }

    _ => { print "❌ wezterm config link failed!" }
  }
}

def unlink_wezterm [] {
  unlink $"($nu.data-dir | path dirname | path split | append "wezterm" | path join)"
}


const rime_to_create = $"($nu.data-dir | path dirname | path join Rime moran.custom.yaml)"
const rime_to_reference = $"($nu.default-config-dir | path dirname | path join Rime moran.custom.yaml)"

def link_rime_moran_custom [] {
  match $nu.os-info.name {
    "windows" => {
      # https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/mklink
      mklink $rime_to_create $rime_to_reference
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

# end of file
