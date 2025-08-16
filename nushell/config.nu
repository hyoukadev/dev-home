# config.nu
#
# Installed by:
# version = "0.103.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# This file is loaded after env.nu and before login.nu
#
# You can open this file in your default editor using:
# config nu
#
# See `help config nu` for more options
#
# You can remove these comments if you want or leave
# them for future reference.

def --env y [...args] {
	let tmp = (mktemp -t "yazi-cwd.XXXXXX")
	yazi ...$args --cwd-file $tmp
	let cwd = (open $tmp)
	if $cwd != "" and $cwd != $env.PWD {
		cd $cwd
	}
	rm -fp $tmp
}


# nushell self
# https://github.com/nushell/nushell/issues/5585
if ($env.TERM_PROGRAM? == "WezTerm") {
	$env.config.shell_integration.osc133 = false
}


# WSL2
# https://github.com/nushell/nushell/issues/5068
# if () { alias } seems not work, the aliases can not be found with `help aliases`
# 下面这种方式不能传参，所以最后我选择将其命名为 podman
# alias podman = if (uname | get 'kernel-release' | str index-of "WSL2") != -1 {
# 	podman-remote-static-linux_amd64
# } else {
# 	podman
# }


source ./helpers/git.nu
source ./helpers/python_uv.nu
source ./helpers/normal.nu
source ./themes/catppuccin_frappe.nu


# setup alias
alias cls = clear


const MACOS_SPECIAL_SCRIPT = "./helpers/macos.nu"
const WINDOWS_SPECIAL_SCRIPT = "./helpers/windows.nu"

# https://www.nushell.sh/blog/2023-09-19-nushell_0_85_0.html#improvements-to-parse-time-evaluation
const OS_SPECIAL_SCRIPT = if ($nu.os-info.name == "windows") {
	$WINDOWS_SPECIAL_SCRIPT
} else if ($nu.os-info.name == "macos") {
	$MACOS_SPECIAL_SCRIPT
}

source $OS_SPECIAL_SCRIPT


mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
zoxide init nushell | save -f ($nu.data-dir | path join "vendor/autoload/zoxide.nu")
# https://mise.jdx.dev/installing-mise.html#nushell
mise activate nu | save -f ($nu.data-dir | path join "vendor/autoload/mise.nu")

# end of file
