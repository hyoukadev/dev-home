# nu -c init.nu 初始化

const init_path = $nu.default-config-dir | path join inits
const ohmyposh_init_path = $init_path | path join ohmyposh.nu
# .oh-my-posh.nu created via:
# https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/themes/catppuccin.omp.json
oh-my-posh init nu --config ($init_path | path join catppuccin.ohmyposh.json) --print | save $ohmyposh_init_path --force

const zoxide_init_path = $init_path | path join zoxide.nu
# .zoxide.nu created via:
zoxide init nushell | save -f $zoxide_init_path

const mise_init_path = $init_path | path join mise.nu
# mise.nu created via:
mise activate nu | save $mise_init_path

