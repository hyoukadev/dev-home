# set windows-shell := ["powershell.exe", "-c"]
set windows-shell := ["nu", "-c"]

# canary recipe
[private]
default:
  @just --list

c:
  npx gitmoji-cli -c

[unix]
symlink:
  cargo run -- --source-dir .

[windows]
setup:
  sudo cargo run -- --source-dir .


debug:
  cargo run -- --source-dir . --debug

clean:
  cargo clean
  rm -rf target


[unix]
install-cargo:
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

[linux]
install-helix:
  # helix is not in the Ubuntu 24.04 PPA
  # https://github.com/maveonair/helix-ppa/issues/14
  # and I do not want to use snap
  sudo apt remove --purge snapd

  # choose flatpak because of RedHat and SteamOS
  # sudo apt install flatpak
  # sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  # sudo flatpak install flathub com.helix_editor.Helix

  

[unix]
pre-install:
  sudo apt install pkg-config libssl-dev build-essential
  cargo install nu --locked
  cargo install just --locked

  sudo apt install unzip
  curl -s https://ohmyposh.dev/install.sh | bash -s
  oh-my-posh init nu

  cargo install zoxide --locked
  zoxide init nushell | save -f ~/.zoxide.nu
  # cargo build uv cost too much time, so use install.sh here
  # cargo install --git https://github.com/astral-sh/uv uv
  curl -LsSf https://astral.sh/uv/install.sh | sh

[windows]
pre-install:
  winget install git.git
  winget install github.gitlfs
  winget install nushell
  winget install yazi
  winget install ajeetdsouza.zoxide
  winget install --id=astral-sh.uv  -e
  winget install Helix.Helix

# need re-open the terminal or the shell after pre-install
# to make the commands can be found
pre-config:
  zoxide init nushell | save -f ~/.zoxide.nu
