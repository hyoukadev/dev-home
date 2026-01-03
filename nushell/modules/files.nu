use ./do.nu *

def log [emoji: string, msg: string] {
  print $"($emoji) ($msg)"
}

export def symlink [link: path, original: path] {
  # Expand paths to absolute to avoid relative path confusion
  let link = ($link | path expand)
  let original = ($original | path expand)

  if not ($original | path exists) {
    log "❌" $"Source not found: ($original)"
    return
  }

  if ($link | path exists) {
    # Check type via ls on parent to avoid following symlinks or listing dir contents
    # We use `path dirname` to list the parent directory
    let link_dirname = ($link | path dirname)
    # Find the specific entry. `ls` returns absolute paths if we don't specify otherwise,
    # but let's be safe matching the name.
    let entry = (ls -a $link_dirname | where name == $link | first)
    let type = $entry.type

    if $type == "symlink" {
      # Check if it points to the correct location
      # `path expand` on the link resolves to the real target
      let current_target = ($link | path expand)

      if $current_target == $original {
        log "✅" $"Already linked: ($link)"
        return
      }

      log "🔄" $"Updating link: ($link)"
      # Remove old symlink
      rm $link
    } else {
      # Backup existing file/directory
      let backup = $"($link).bak"
      if ($backup | path exists) {
        # Remove old backup if exists
        rm -r $backup
      }
      log "📦" $"Backing up: ($link) -> ($backup)"
      mv $link $backup
    }
  }

  # Ensure parent directory exists
  let parent = ($link | path dirname)
  if not ($parent | path exists) {
    mkdir $parent
  }

  log "🔗" $"Creating link: ($link) -> ($original)"

  do auto {
    windows: {
      # Windows native paths require backslashes for mklink
      let link_win = ($link | str replace -a "/" "\")
      let orig_win = ($original | str replace -a "/" "\")

      # Determine if source is directory for /D switch
      let is_dir = (($original | path type) == "dir")

      # Use constructed command string for cmd /c to handle spaces correctly
      # mklink syntax: mklink [[/D] | [/H] | [/J]] Link Target
      if $is_dir {
        cmd /c $"mklink /D \"($link_win)\" \"($orig_win)\""
      } else {
        cmd /c $"mklink \"($link_win)\" \"($orig_win)\""
      }
    },
    _: {
      # Unix (macOS/Linux)
      # ln -s target link_name
      ln -s $original $link
    }
  }
}
