use ../nushell/modules/pathvar.nu *
use ../nushell/modules/do.nu *
use ../nushell/modules/files.nu *

# Oh My Tmux installation paths
let tmux_repo = ($nu.home-path | path join ".tmux")
let conf_link = ($nu.home-path | path join ".tmux.conf")
let conf_source = ($tmux_repo | path join ".tmux.conf")
let local_conf_source = ($tmux_repo | path join ".tmux.conf.local")
let local_conf_target = ($nu.home-path | path join ".tmux.conf.local")

export def install [] {
  # 1. Clone repo if not exists
  if not ($tmux_repo | path exists) {
    print "⬇️ Cloning Oh My Tmux..."
    git clone --single-branch https://github.com/gpakosz/.tmux.git $tmux_repo
  } else {
    print "✅ Oh My Tmux repo already exists"
  }

  # 2. Link .tmux.conf -> .tmux/.tmux.conf
  symlink $conf_link $conf_source

  # 3. Copy .tmux.conf.local if not exists (don't overwrite user changes)
  if not ($local_conf_target | path exists) {
    print "📋 Copying default local config..."
    cp $local_conf_source $local_conf_target
  } else {
    print "✅ Local config already exists, skipping copy"
  }
}

export def uninstall [] {
  if ($conf_link | path exists) { rm $conf_link }
  # We generally don't delete the repo or local config on uninstall to preserve data
}
