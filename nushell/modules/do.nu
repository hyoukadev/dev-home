export def "do auto" [cmds] {
  let cmd = $cmds | get -i unix

  if ($cmd | describe) == closure {
    return (do $cmd)
  }

  let cmd = $cmds | get -i ($nu.os-info.name)

  if ($cmd | describe) == closure {
    return (do $cmd)
  }

  return ($cmds | get _ | do $in)
}

export def "do auto supported" [] {
  ["unix", "windows", "macos", "linux", "android"]
}

