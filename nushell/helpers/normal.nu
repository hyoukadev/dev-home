def "ice ip" [] {
  match $nu.os-info.name {
    "macos" => {
      ipconfig getifaddr en0
    }
  }
}


