#!/usr/bin/env nu

# task.nu - Replaces justfile for project management

def main [] {
    print "Usage: nu task.nu <command>"
    print ""
    print "Commands:"
    print "  c                    Run gitmoji-cli"
    print "  termux-init          Initialize Termux environment"
    print "  termux-sshd          Setup SSHD in Termux"
    print "  install-cargo        Install Rust (Unix)"
    print "  install-helix        Install Helix (Linux)"
}

# c: npx gitmoji-cli -c
def "main c" [] {
    npx gitmoji-cli -c
}

# termux-init
def "main termux-init" [] {
    let pkgs = [
        "git", "git-lfs", "nushell", "rust",
        "oh-my-posh", "yazi", "zoxide", "helix",
        "uv", "tmux", "nodejs-lts"
    ]
    for pkg in $pkgs {
        print $"Installing ($pkg)..."
        pkg install $pkg
    }
}

# termux-support-sshd
def "main termux-sshd" [] {
    pkg install openssh
    sshd
    ifconfig
    passwd
    # ssh -p 8022 ${IP}
}

# [unix] install-cargo
def "main install-cargo" [] {
    if $nu.os-info.family != "unix" {
        print "Skipping: This task is for Unix-like systems."
        return
    }
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
}

# [linux] install-helix
def "main install-helix" [] {
    if ($nu.os-info.name? != "linux") and ($nu.os-info.family != "unix") {
        print "Skipping: This task is for Linux."
        return
    }
    # helix is not in the Ubuntu 24.04 PPA...
    sudo apt remove --purge snapd
}

# pre-install (Windows & Unix)
def "main pre-install" [] {
    match $nu.os-info.family {
        "windows" => {
            winget install git.git
            winget install github.gitlfs
            winget install nushell --scope machine
            winget install yazi
            winget install ajeetdsouza.zoxide
            # winget install --id=astral-sh.uv -e
            winget install Helix.Helix
        }
        "unix" => {
            sudo apt install pkg-config libssl-dev build-essential
            cargo install nu --locked

            sudo apt install unzip
            curl -s https://ohmyposh.dev/install.sh | bash -s
            oh-my-posh init nu

            cargo install zoxide --locked
            zoxide init nushell | save -f ~/.zoxide.nu

            curl -LsSf https://astral.sh/uv/install.sh | sh
        }
        _ => {
            print $"Unsupported OS family: ($nu.os-info.family)"
        }
    }
}
