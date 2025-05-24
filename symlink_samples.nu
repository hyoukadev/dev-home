
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

# end of file
