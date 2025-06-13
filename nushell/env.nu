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

const MACOS_SPECIAL_SCRIPT = "./inits/macos.nu"
const WINDOWS_SPECIAL_SCRIPT = "./inits/windows.nu"
const ANDROID_SPECIAL_SCRIPT = "./inits/android.nu"
const LINUX_SPECIAL_SCRIPT = "./inits/linux.nu"

# https://www.nushell.sh/blog/2023-09-19-nushell_0_85_0.html#improvements-to-parse-time-evaluation
const OS_SPECIAL_SCRIPT = if ($nu.os-info.name == "windows") {
	$WINDOWS_SPECIAL_SCRIPT
} else if ($nu.os-info.name == "macos") {
	$MACOS_SPECIAL_SCRIPT
} else if ($nu.os-info.name == "android") {
  $ANDROID_SPECIAL_SCRIPT
} else {
  $LINUX_SPECIAL_SCRIPT
}

# setup System PATH
source $OS_SPECIAL_SCRIPT

use std/util "path add"
path add ($nu.home-path | path join .cargo bin)


$env.EDITOR = "hx"
$env.config.buffer_editor = "hx"

# end of file
