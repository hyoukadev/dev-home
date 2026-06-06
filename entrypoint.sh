#!/bin/sh
set -e

# Re-run user-space bootstrap when this changes.
BOOTSTRAP_VERSION="2026-06-06.1"

OHMYNUSHELL_REPO="git@github.com:hyoukadev/ohmynushell.git"
OHMYTMUX_REPO="https://github.com/gpakosz/.tmux.git"

# === Tool versions ===
HELIX_VERSION="25.07.1"
NEOVIM_VERSION="0.12.2"
STARSHIP_VERSION="1.25.1"
ZOXIDE_VERSION="0.9.9"
YAZI_VERSION="26.1.22"
FD_VERSION="10.4.2"
RIPGREP_VERSION="15.1.0"
FZF_VERSION="0.72.0"
PYTHON_VERSION="3.13"
NODE_VERSION="24"
PNPM_VERSION="10"
UV_VERSION="latest"
BUN_VERSION="latest"
GO_VERSION="1.24"
RUST_VERSION="stable"
JUST_VERSION="latest"
GITHUB_CLI_VERSION="latest"
KUBECTL_VERSION="latest"
TERRAFORM_VERSION="latest"
FLYCTL_VERSION="latest"

# ============================================
# Phase 1: root
# ============================================
if [ "$(id -u)" = "0" ]; then
    DEV_HOME="/home/dev"
    DEV_UID="${DEV_UID:-}"
    DEV_GID="${DEV_GID:-}"

    # Save proxy for Phase 2 (tool downloads need it)
    SAVED_http_proxy="$http_proxy"
    SAVED_https_proxy="$https_proxy"
    SAVED_HTTP_PROXY="$HTTP_PROXY"
    SAVED_HTTPS_PROXY="$HTTPS_PROXY"

    if [ -z "$DEV_UID" ] || [ -z "$DEV_GID" ]; then
        if [ -d /workspace ]; then
            WORKSPACE_UID=$(stat -c '%u' /workspace 2>/dev/null || true)
            WORKSPACE_GID=$(stat -c '%g' /workspace 2>/dev/null || true)
            if [ -z "$DEV_UID" ] && [ -n "$WORKSPACE_UID" ] && [ "$WORKSPACE_UID" != "0" ]; then
                DEV_UID="$WORKSPACE_UID"
            fi
            if [ -z "$DEV_GID" ] && [ -n "$WORKSPACE_GID" ] && [ "$WORKSPACE_GID" != "0" ]; then
                DEV_GID="$WORKSPACE_GID"
            fi
        fi
    fi
    DEV_UID="${DEV_UID:-1000}"
    DEV_GID="${DEV_GID:-1000}"

    case "$DEV_UID" in
        ''|*[!0-9]*)
            echo "DEV_UID must be a numeric uid, got: $DEV_UID" >&2
            exit 1
            ;;
    esac
    case "$DEV_GID" in
        ''|*[!0-9]*)
            echo "DEV_GID must be a numeric gid, got: $DEV_GID" >&2
            exit 1
            ;;
    esac
    if [ "$DEV_UID" = "0" ] || [ "$DEV_GID" = "0" ]; then
        echo "DEV_UID/DEV_GID must not be 0 because root already uses 0:0." >&2
        exit 1
    fi

    CURRENT_GID=$(id -g dev)
    DEV_GROUP=$(id -gn dev)
    if [ "$DEV_GID" != "$CURRENT_GID" ]; then
        EXISTING_GROUP=$(getent group "$DEV_GID" | cut -d: -f1 || true)
        if [ -n "$EXISTING_GROUP" ] && [ "$EXISTING_GROUP" != "dev" ]; then
            DEV_GROUP="$EXISTING_GROUP"
        else
            groupmod -g "$DEV_GID" dev
            DEV_GROUP=dev
        fi
    fi

    CURRENT_UID=$(id -u dev)
    if [ "$DEV_UID" != "$CURRENT_UID" ]; then
        EXISTING_USER=$(getent passwd "$DEV_UID" | cut -d: -f1 || true)
        if [ -n "$EXISTING_USER" ] && [ "$EXISTING_USER" != "dev" ]; then
            echo "Cannot set dev uid to $DEV_UID because user '$EXISTING_USER' already uses it." >&2
            exit 1
        fi
        usermod -u "$DEV_UID" -g "$DEV_GROUP" dev
    elif [ "$DEV_GID" != "$CURRENT_GID" ]; then
        usermod -g "$DEV_GROUP" dev
    fi
    DEV_PRIMARY_GID=$(id -g dev)

    ROOT_MARKER="/var/lib/dev-home/root-bootstrap.done"
    if [ ! -f "$ROOT_MARKER" ]; then
        # --- apt mirror (Debian aliyun) ---
        sed -i 's|http://deb.debian.org/debian|http://mirrors.aliyun.com/debian|g' /etc/apt/sources.list.d/debian.sources
        sed -i 's|http://deb.debian.org/debian-security|http://mirrors.aliyun.com/debian-security|g' /etc/apt/sources.list.d/debian.sources

        # --- apt install system deps (no proxy for aliyun mirrors) ---
        unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
        export DEBIAN_FRONTEND=noninteractive
        apt-get update && \
            apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
            ca-certificates curl git git-lfs openssh-client rsync tmux \
            build-essential clang lld cmake pkg-config libssl-dev \
            unzip zip xz-utils zstd tar gzip sudo jq file less vim locales \
            vainfo mesa-utils vulkan-tools clinfo libva-drm2 \
            mesa-va-drivers mesa-vulkan-drivers intel-media-va-driver \
            && rm -rf /var/lib/apt/lists/*

        # --- locale-gen ---
        locale-gen en_US.UTF-8
        mkdir -p "$(dirname "$ROOT_MARKER")"
        touch "$ROOT_MARKER"
    fi

    # Create root-phase directories before the ownership repair below.
    VENDOR_DIR="/home/dev/.local/share/nushell/vendor/autoload"
    mkdir -p "$DEV_HOME/.local/bin" "$VENDOR_DIR"

    # Repair ownership for persisted home volumes created by older images.
    # Keep ~/.ssh untouched because it is a read-only host bind mount.
    chown dev:"$DEV_GROUP" "$DEV_HOME"
    find "$DEV_HOME" -mindepth 1 -maxdepth 1 ! -name .ssh -exec chown -R dev:"$DEV_GROUP" {} +

    # Materialize a writable ~/.ssh while keeping private keys on the read-only host mount.
    if [ -d /host-ssh ]; then
        SSH_DIR="$DEV_HOME/.ssh"
        rm -rf "$SSH_DIR"
        mkdir -p "$SSH_DIR"
        chown dev:"$DEV_GROUP" "$SSH_DIR"
        chmod 700 "$SSH_DIR"

        for src in /host-ssh/* /host-ssh/.[!.]*; do
            [ -e "$src" ] || continue
            [ -f "$src" ] || continue
            name=$(basename "$src")
            case "$name" in
                config|known_hosts|known_hosts.old|*.pub|.gitignore)
                    cp "$src" "$SSH_DIR/$name" 2>/dev/null || true
                    chown dev:"$DEV_GROUP" "$SSH_DIR/$name" 2>/dev/null || true
                    chmod 600 "$SSH_DIR/$name" 2>/dev/null || true
                    ;;
                *)
                    ln -s "$src" "$SSH_DIR/$name"
                    chown -h dev:"$DEV_GROUP" "$SSH_DIR/$name" 2>/dev/null || true
                    ;;
            esac
        done
    fi

    # Re-exec as dev without creating a su-managed session. GPU device
    # access in rootless Podman needs the host's supplementary groups.
    SETPRIV_GROUP_ARGS="--init-groups"
    if [ "${DEV_HOME_KEEP_GROUPS:-0}" = "1" ] || \
       [ -d /dev/dri ] || [ -e /dev/kfd ] || ls /dev/nvidia* >/dev/null 2>&1; then
        SETPRIV_GROUP_ARGS="--keep-groups"
    fi
    exec setpriv --reuid dev --regid "$DEV_PRIMARY_GID" "$SETPRIV_GROUP_ARGS" env \
        HOME="$DEV_HOME" USER=dev LOGNAME=dev SHELL=/usr/bin/nu \
        http_proxy="$SAVED_http_proxy" https_proxy="$SAVED_https_proxy" \
        HTTP_PROXY="$SAVED_HTTP_PROXY" HTTPS_PROXY="$SAVED_HTTPS_PROXY" \
        /usr/local/bin/entrypoint.sh "$@"
fi

# ============================================
# Phase 2: dev
# ============================================
cd ~
export PATH="$HOME/.local/bin:$PATH"
mkdir -p "$HOME/.cache/dev-home" "$HOME/.local/bin" "$HOME/workspace"
MARKER="$HOME/.cache/dev-home/bootstrap-${BOOTSTRAP_VERSION}.done"

if [ ! -f "$MARKER" ]; then
    # --- install mise ---
    if ! command -v mise >/dev/null 2>&1; then
        curl https://mise.run | sh
    fi

    # --- install default tools ---
    mise use -g \
        "python@${PYTHON_VERSION}" \
        "node@${NODE_VERSION}" \
        "pnpm@${PNPM_VERSION}" \
        "uv@${UV_VERSION}" \
        "bun@${BUN_VERSION}" \
        "go@${GO_VERSION}" \
        "rust@${RUST_VERSION}" \
        "helix@${HELIX_VERSION}" \
        "neovim@${NEOVIM_VERSION}" \
        "starship@${STARSHIP_VERSION}" \
        "zoxide@${ZOXIDE_VERSION}" \
        "yazi@${YAZI_VERSION}" \
        "fd@${FD_VERSION}" \
        "ripgrep@${RIPGREP_VERSION}" \
        "fzf@${FZF_VERSION}" \
        "just@${JUST_VERSION}" \
        "github-cli@${GITHUB_CLI_VERSION}" \
        "kubectl@${KUBECTL_VERSION}" \
        "terraform@${TERRAFORM_VERSION}" \
        "flyctl@${FLYCTL_VERSION}"

    # --- nushell config via ohmynushell ---
    rm -rf ~/.config/nushell ~/.ohmynushell
    mkdir -p ~/.config
    git clone --single-branch "$OHMYNUSHELL_REPO" ~/.config/nushell

    # Override linux init for container (no hardcoded proxy)
    cat > ~/.config/nushell/inits/linux.nu <<'NUSHEOF'
# Container Linux init
use std/util "path add"
path add ($nu.home-dir | path join .local bin)
path add ($nu.home-dir | path join .local share mise shims)
path add ($nu.home-dir | path join .cargo bin)
path add ($nu.home-dir | path join go bin)

# Proxy from environment if set
if ($env.http_proxy? != null) {
    $env.HTTP_PROXY = $env.http_proxy
    $env.HTTPS_PROXY = ($env.https_proxy? | default $env.http_proxy)
}
NUSHEOF

    # --- vendor autoload scripts ---
    VENDOR_DIR="$HOME/.local/share/nushell/vendor/autoload"
    mkdir -p "$VENDOR_DIR"
    rm -f "$VENDOR_DIR/mise.nu" "$VENDOR_DIR/starship.nu" "$VENDOR_DIR/zoxide.nu"
    curl -fsSL https://raw.githubusercontent.com/catppuccin/starship/refs/heads/main/starship.toml \
        -o "$VENDOR_DIR/starship.toml"
    mise exec -- starship init nu > "$VENDOR_DIR/starship.nu"
    mise exec -- zoxide init nushell > "$VENDOR_DIR/zoxide.nu"
    mise activate nu > "$VENDOR_DIR/mise.nu"
    mise reshim

    # --- oh-my-tmux setup ---
    rm -rf ~/.tmux ~/.tmux.conf ~/.tmux.conf.local
    git clone --single-branch "$OHMYTMUX_REPO" ~/.tmux
    ln -s -f ~/.tmux/.tmux.conf ~/.tmux.conf
    if [ -f ~/.tmux/.tmux.conf.local ]; then
        cp ~/.tmux/.tmux.conf.local ~/.tmux.conf.local
    else
        touch ~/.tmux.conf.local
    fi
    sed -i -e '/# -- tpm/i\set -g default-shell "/usr/bin/nu" #!important' \
           -e '/# -- tpm/i\set -g default-command "/usr/bin/nu --login" #!important' \
           -e '/# -- tpm/i\set -g mouse on #!important' ~/.tmux.conf.local

    touch "$MARKER"
fi

exec "$@"
