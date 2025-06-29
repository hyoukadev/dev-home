export def "pathvar xdg_config_home" [] {
  match $nu.os-info.name {
    "windows" => {
      $env.APPDATA
    }
    "macos" => {
      $nu.home-path
    }
    "linux" => {
      $nu.home-path
    }
  }
}

export def "pathvar home" [] {
  $nu.home-path
}

export def "pathvar workspace" [] {
  $nu.default-config-dir | path dirname
}
