#!/usr/bin/env bash
set -euo pipefail

BOOTSTRAP_VERSION="2026-06-06.1"

OHMYNUSHELL_REPO="git@github.com:hyoukadev/ohmynushell.git"
OHMYTMUX_REPO="https://github.com/gpakosz/.tmux.git"

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

APT_REQUIRED_PACKAGES=(
  ca-certificates curl git git-lfs openssh-client rsync tmux
  build-essential clang lld cmake pkg-config libssl-dev
  unzip zip xz-utils zstd tar gzip sudo jq file less vim locales
)

APT_OPTIONAL_PACKAGES=(
  vainfo mesa-utils vulkan-tools clinfo libva-drm2
  mesa-va-drivers mesa-vulkan-drivers intel-media-va-driver i965-va-driver
)

SUDO_KEEPALIVE_PID=""
TMP_DIRS=()

usage() {
  cat <<'EOF'
Usage: scripts/bootstrap-ubuntu-server.sh

Initialize the current Ubuntu Server user with the dev-home toolchain outside
of a container image. Run this as a normal sudo-capable user, not as root.

Environment:
  GITHUB_TOKEN              Optional token for GitHub release API requests.
  NUSHELL_VERSION=latest    Set a specific Nushell release tag if needed.
EOF
}

info() {
  printf '==> %s\n' "$*"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_ubuntu() {
  [ -r /etc/os-release ] || die "/etc/os-release is missing."
  # shellcheck disable=SC1091
  . /etc/os-release
  [ "${ID:-}" = "ubuntu" ] || die "This script targets Ubuntu Server; detected ID=${ID:-unknown}."
}

require_non_root_user() {
  [ "$(id -u)" != "0" ] || die "Run as your normal user, not root. The script uses sudo for system packages."
  command -v sudo >/dev/null 2>&1 || die "sudo is required."
  sudo -v
}

cleanup() {
  if [ -n "$SUDO_KEEPALIVE_PID" ]; then
    kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
  fi
  local dir
  for dir in "${TMP_DIRS[@]}"; do
    rm -rf "$dir"
  done
}

start_sudo_keepalive() {
  while true; do
    sudo -n true 2>/dev/null || exit
    sleep 60
  done &
  SUDO_KEEPALIVE_PID=$!
}

install_apt_packages() {
  info "Installing apt packages..."
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    "${APT_REQUIRED_PACKAGES[@]}"

  local installable_optional=()
  local missing_optional=()
  local pkg
  for pkg in "${APT_OPTIONAL_PACKAGES[@]}"; do
    if apt-cache show "$pkg" >/dev/null 2>&1; then
      installable_optional+=("$pkg")
    else
      missing_optional+=("$pkg")
    fi
  done

  if [ "${#installable_optional[@]}" -gt 0 ]; then
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
      -o Dpkg::Options::="--force-confdef" \
      -o Dpkg::Options::="--force-confold" \
      "${installable_optional[@]}"
  fi

  if [ "${#missing_optional[@]}" -gt 0 ]; then
    warn "Optional packages unavailable in enabled apt repositories: ${missing_optional[*]}"
  fi
}

configure_locale() {
  info "Configuring locale..."
  if ! grep -Eq '^[[:space:]]*en_US.UTF-8[[:space:]]+UTF-8' /etc/locale.gen; then
    if grep -Eq '^[[:space:]]*#[[:space:]]*en_US.UTF-8[[:space:]]+UTF-8' /etc/locale.gen; then
      sudo sed -i 's/^[[:space:]]*#[[:space:]]*en_US.UTF-8[[:space:]]\+UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    else
      printf '%s\n' 'en_US.UTF-8 UTF-8' | sudo tee -a /etc/locale.gen >/dev/null
    fi
  fi
  sudo locale-gen en_US.UTF-8
  sudo update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en
}

github_curl() {
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" "$@"
  else
    curl -fsSL "$@"
  fi
}

install_nushell() {
  if command -v nu >/dev/null 2>&1; then
    info "Nushell already installed: $(command -v nu)"
    return
  fi

  info "Installing Nushell..."
  local machine target_arch release_tag asset url fallback_url tmp_dir archive nu_bin
  machine=$(uname -m)
  case "$machine" in
    x86_64|amd64) target_arch="x86_64" ;;
    aarch64|arm64) target_arch="aarch64" ;;
    *) die "Unsupported architecture for Nushell release install: $machine" ;;
  esac

  if [ "${NUSHELL_VERSION:-latest}" = "latest" ]; then
    release_tag=$(github_curl https://api.github.com/repos/nushell/nushell/releases/latest | jq -r '.tag_name')
  else
    release_tag="${NUSHELL_VERSION}"
  fi
  [ -n "$release_tag" ] && [ "$release_tag" != "null" ] || die "Could not resolve Nushell release tag."

  asset="nu-${release_tag}-${target_arch}-unknown-linux-gnu.tar.gz"
  url="https://github.com/nushell/nushell/releases/download/${release_tag}/${asset}"
  fallback_url="https://sourceforge.net/projects/nushell.mirror/files/${release_tag}/${asset}/download"
  tmp_dir=$(mktemp -d)
  TMP_DIRS+=("$tmp_dir")
  archive="${tmp_dir}/${asset}"

  if ! curl -fL -o "$archive" "$url"; then
    warn "GitHub release download failed; retrying via SourceForge mirror."
    curl -fL -o "$archive" "$fallback_url"
  fi
  tar -xzf "$archive" -C "$tmp_dir"
  nu_bin=$(find "$tmp_dir" -type f -name nu -perm -u+x | head -n 1)
  [ -n "$nu_bin" ] || die "Downloaded Nushell archive did not contain an executable nu binary."
  sudo install -m 0755 "$nu_bin" /usr/local/bin/nu
}

install_mise() {
  export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$HOME/.cargo/bin:$HOME/go/bin:$PATH"
  if ! command -v mise >/dev/null 2>&1; then
    info "Installing mise..."
    curl https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
    hash -r
  fi
  command -v mise >/dev/null 2>&1 || die "mise was not found after installation."
}

install_mise_tools() {
  info "Installing mise tools..."
  export MISE_YES=1
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
}

timestamp() {
  date +%Y%m%d%H%M%S
}

backup_path() {
  local path backup
  path=$1
  [ -e "$path" ] || [ -L "$path" ] || return 0
  backup="${path}.dev-home-backup.$(timestamp)"
  info "Backing up $path to $backup"
  mv "$path" "$backup"
}

repo_origin() {
  git -C "$1" remote get-url origin 2>/dev/null || true
}

ensure_checkout() {
  local repo target origin
  repo=$1
  target=$2

  if [ -d "$target/.git" ]; then
    origin=$(repo_origin "$target")
    if [ "$origin" = "$repo" ]; then
      info "Updating $target"
      git -C "$target" pull --ff-only || warn "Could not fast-forward $target; leaving existing checkout in place."
      return 0
    fi
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    backup_path "$target"
  fi

  mkdir -p "$(dirname "$target")"
  git clone --single-branch "$repo" "$target"
}

write_profile_block() {
  local profile
  profile="$HOME/.profile"
  touch "$profile"
  sed -i '/^# >>> dev-home ubuntu bootstrap$/,/^# <<< dev-home ubuntu bootstrap$/d' "$profile"
  cat >> "$profile" <<'EOF'
# >>> dev-home ubuntu bootstrap
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$HOME/.cargo/bin:$HOME/go/bin:$PATH"
# <<< dev-home ubuntu bootstrap
EOF
}

configure_nushell() {
  info "Configuring Nushell..."
  ensure_checkout "$OHMYNUSHELL_REPO" "$HOME/.config/nushell"

  mkdir -p "$HOME/.config/nushell/inits"
  cat > "$HOME/.config/nushell/inits/linux.nu" <<'NUSHEOF'
# Ubuntu Server init
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

  local vendor_dir
  vendor_dir="$HOME/.local/share/nushell/vendor/autoload"
  mkdir -p "$vendor_dir"
  rm -f "$vendor_dir/mise.nu" "$vendor_dir/starship.nu" "$vendor_dir/zoxide.nu"
  curl -fsSL https://raw.githubusercontent.com/catppuccin/starship/refs/heads/main/starship.toml \
    -o "$vendor_dir/starship.toml"
  mise exec -- starship init nu > "$vendor_dir/starship.nu"
  mise exec -- zoxide init nushell > "$vendor_dir/zoxide.nu"
  mise activate nu > "$vendor_dir/mise.nu"
  mise reshim
}

configure_tmux() {
  info "Configuring tmux..."
  ensure_checkout "$OHMYTMUX_REPO" "$HOME/.tmux"
  if [ -e "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
    backup_path "$HOME/.tmux.conf"
  fi
  ln -sfn "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"

  local tmux_local nu_path
  tmux_local="$HOME/.tmux.conf.local"
  if [ ! -f "$tmux_local" ]; then
    if [ -f "$HOME/.tmux/.tmux.conf.local" ]; then
      cp "$HOME/.tmux/.tmux.conf.local" "$tmux_local"
    else
      touch "$tmux_local"
    fi
  fi

  nu_path=$(command -v nu)
  sed -i '/^# >>> dev-home ubuntu bootstrap$/,/^# <<< dev-home ubuntu bootstrap$/d' "$tmux_local"
  cat >> "$tmux_local" <<EOF
# >>> dev-home ubuntu bootstrap
set -g default-shell "$nu_path" #!important
set -g default-command "$nu_path --login" #!important
set -g mouse on #!important
# <<< dev-home ubuntu bootstrap
EOF
}

main() {
  case "${1:-}" in
    -h|--help|help)
      usage
      exit 0
      ;;
    "")
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac

  require_ubuntu
  require_non_root_user
  trap cleanup EXIT
  start_sudo_keepalive

  info "dev-home Ubuntu Server bootstrap ${BOOTSTRAP_VERSION}"
  install_apt_packages
  configure_locale
  install_nushell
  install_mise
  install_mise_tools
  write_profile_block
  configure_nushell
  configure_tmux

  info "Done. Open a new login shell, or run: exec nu --login"
}

main "$@"
