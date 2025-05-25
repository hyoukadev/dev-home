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

const init_path = $nu.default-config-dir | path join inits
const ohmyposh_init_path = $init_path | path join ohmyposh.nu
source $ohmyposh_init_path

const zoxide_init_path = $init_path | path join zoxide.nu
source $zoxide_init_path

const mise_init_path = $init_path | path join mise.nu
source $mise_init_path

# const local_mise_nu_path = ($nu.default-config-dir | path join mise.nu)
# const local_mise_nu_file_exist = (echo $local_mise_nu_path | path exists)

# let local_mise_command_exist = (which mise | length) > 0

# print $"[ice]: outside"

# if $local_mise_command_exist and $local_mise_nu_file_exist == false {
#   mise activate | save $local_mise_nu_path
#   print $"[ice]: ($local_mise_nu_path) does not exists! so we created it"
# }

# if $local_mise_command_exist {
# 	source $local_mise_nu_path
# }

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


# end of file
