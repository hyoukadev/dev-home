# env.nu
#
# Installed by:
# version = "0.103.0"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.

use std/util "path add"

# setup System PATH
if (uname | get operating-system) == "Darwin" {
  path add "/opt/homebrew/bin"
  path add "/opt/homebrew/sbin"


  # default settings of v2rayU
  let local_http_proxy = "http://127.0.0.1:1087"
  let local_socks_proxy = "socks5://127.0.0.1:1080"

  $env.http_proxy = $local_http_proxy
  $env.https_proxy = $local_http_proxy
  $env.all_proxy = $local_socks_proxy

  $env.HTTP_PROXY = $local_http_proxy
  $env.HTTPS_PROXY = $local_http_proxy
  $env.ALL_PROXY = $local_socks_proxy

} else if (uname | get kernel-name) == 'Windows_NT' {
  # default settings of v2rayN
  let local_http_proxy = "http://127.0.0.1:10808"
  let local_socks_proxy = "socks5://127.0.0.1:10808"

  $env.http_proxy = $local_http_proxy
  $env.https_proxy = $local_http_proxy
  $env.all_proxy = $local_socks_proxy

  $env.HTTP_PROXY = $local_http_proxy
  $env.HTTPS_PROXY = $local_http_proxy
  $env.ALL_PROXY = $local_socks_proxy
} else if ($nu.os-info.name == 'android') {
  # Termux
} else {
  # Linux and WSL2
  path add ($nu.home-path | path join .local bin)
  # /var/lib/flatpak/exports/share
  # /home/ice/.local/share/flatpak/exports/share
}

path add ($nu.home-path | path join .cargo bin)


$env.EDITOR = "hx"
$env.config.buffer_editor = "hx"

# end of file
