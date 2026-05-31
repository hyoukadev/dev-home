#!/bin/sh
set -eu

DEFAULT_IMAGE="ghcr.io/hyoukadev/dev-home:latest"
HOME_DIR="${HOME:-$PWD}"

IMAGE="${DEV_HOME_IMAGE:-$DEFAULT_IMAGE}"
NAME="${DEV_HOME_CONTAINER_NAME:-dev-home}"
INSTALL_DIR="${DEV_HOME_NAS_DIR:-$PWD/dev-home}"
WORKSPACE_DIR="${DEV_HOME_WORKSPACE_DIR:-}"
SSH_DIR="${DEV_HOME_SSH_DIR:-$HOME_DIR/.ssh}"
DO_PULL=1
DO_START=1
FORCE=0
CHECK_SSH=1
UID_VALUE="${DEV_UID:-$(id -u 2>/dev/null || echo 1000)}"
GID_VALUE="${DEV_GID:-$(id -g 2>/dev/null || echo 1000)}"

usage() {
  cat <<'EOF'
Usage: sh nas-install.sh [options]

Options:
  --dir DIR          Directory for compose.yml and .env (default: ./dev-home)
  --workspace DIR    Host workspace path mounted to /workspace (default: DIR/workspace)
  --ssh-dir DIR      Host SSH directory mounted read-only to /host-ssh (default: ~/.ssh)
  --image IMAGE      Container image (default: ghcr.io/hyoukadev/dev-home:latest)
  --name NAME        Container name (default: dev-home)
  --uid UID          Container dev uid (default: current user id, or 1000 for root)
  --gid GID          Container dev gid (default: current group id, or 1000 for root)
  --no-pull          Write files but skip docker compose pull
  --no-start         Write files and pull image, but skip docker compose up -d
  --no-ssh-check     Skip github.com known_hosts/auth checks
  --force            Regenerate compose.yml and .env if they already exist
  -h, --help         Show this help
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

warn() {
  echo "warning: $*" >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dir)
      [ "$#" -ge 2 ] || die "--dir requires a value"
      INSTALL_DIR=$2
      shift 2
      ;;
    --workspace)
      [ "$#" -ge 2 ] || die "--workspace requires a value"
      WORKSPACE_DIR=$2
      shift 2
      ;;
    --ssh-dir)
      [ "$#" -ge 2 ] || die "--ssh-dir requires a value"
      SSH_DIR=$2
      shift 2
      ;;
    --image)
      [ "$#" -ge 2 ] || die "--image requires a value"
      IMAGE=$2
      shift 2
      ;;
    --name)
      [ "$#" -ge 2 ] || die "--name requires a value"
      NAME=$2
      shift 2
      ;;
    --uid)
      [ "$#" -ge 2 ] || die "--uid requires a value"
      UID_VALUE=$2
      shift 2
      ;;
    --gid)
      [ "$#" -ge 2 ] || die "--gid requires a value"
      GID_VALUE=$2
      shift 2
      ;;
    --no-pull)
      DO_PULL=0
      shift
      ;;
    --no-start)
      DO_START=0
      shift
      ;;
    --no-ssh-check)
      CHECK_SSH=0
      shift
      ;;
    --force)
      FORCE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

abs_dir() {
  path=$1
  mkdir -p "$path" || die "cannot create directory: $path"
  (cd "$path" && pwd -P) || die "cannot resolve directory: $path"
}

detect_compose() {
  if docker compose version >/dev/null 2>&1; then
    echo "plugin"
    return
  fi
  if command -v docker-compose >/dev/null 2>&1; then
    echo "v1"
    return
  fi
  die "Docker Compose is not available. Install the docker compose plugin or docker-compose."
}

compose() {
  case "$COMPOSE_IMPL" in
    plugin) docker compose "$@" ;;
    v1) docker-compose "$@" ;;
    *) die "Docker Compose is not available" ;;
  esac
}

compose_label() {
  case "$COMPOSE_IMPL" in
    plugin) echo "docker compose" ;;
    v1) echo "docker-compose" ;;
    *) echo "docker compose" ;;
  esac
}

ensure_github_known_host() {
  known_hosts="$SSH_DIR/known_hosts"
  touch "$known_hosts" 2>/dev/null || {
    warn "cannot write $known_hosts; GitHub SSH may fail during first bootstrap"
    return
  }
  chmod 600 "$known_hosts" 2>/dev/null || true

  if command -v ssh-keygen >/dev/null 2>&1 && ssh-keygen -F github.com -f "$known_hosts" >/dev/null 2>&1; then
    return
  fi

  if command -v ssh-keyscan >/dev/null 2>&1; then
    echo "==> Adding github.com to $known_hosts"
    ssh-keyscan github.com >> "$known_hosts" 2>/dev/null || \
      warn "ssh-keyscan github.com failed; GitHub SSH may require manual known_hosts setup"
  else
    warn "ssh-keyscan is not available; GitHub SSH may require manual known_hosts setup"
  fi
}

check_github_ssh() {
  if [ "$CHECK_SSH" != "1" ]; then
    return 0
  fi

  ensure_github_known_host

  if ! command -v ssh >/dev/null 2>&1; then
    warn "ssh is not available on the NAS; skipping GitHub SSH auth check"
    return
  fi

  if [ "$(basename "$SSH_DIR")" != ".ssh" ]; then
    warn "skipping GitHub SSH auth check for non-standard ssh dir: $SSH_DIR"
    return
  fi

  ssh_home=$(dirname "$SSH_DIR")
  set +e
  output=$(HOME="$ssh_home" ssh -o BatchMode=yes -o ConnectTimeout=10 -T git@github.com 2>&1)
  status=$?
  set -e

  if echo "$output" | grep -qi "successfully authenticated"; then
    echo "==> GitHub SSH auth looks usable"
    return
  fi

  if echo "$output" | grep -qi "permission denied"; then
    warn "GitHub SSH auth failed. The container bootstrap clones git@github.com:hyoukadev/ohmynushell.git, so mount a key that can access it."
    return
  fi

  if [ "$status" -ne 0 ]; then
    warn "could not verify GitHub SSH auth: $output"
  fi
  return 0
}

write_file() {
  file=$1
  kind=$2
  if [ -e "$file" ] && [ "$FORCE" != "1" ]; then
    warn "$kind already exists, keeping it: $file"
    return 1
  fi
  return 0
}

if ! command -v docker >/dev/null 2>&1; then
  die "docker is not installed or not in PATH"
fi

if ! docker info >/dev/null 2>&1; then
  die "Docker daemon is not reachable. Check NAS Docker service and current user's Docker permission."
fi

COMPOSE_IMPL=$(detect_compose)
COMPOSE_CMD=$(compose_label)

if [ "$(uname -s 2>/dev/null || echo unknown)" != "Linux" ]; then
  warn "network_mode: host is intended for Linux/NAS Docker. Docker Desktop behaves differently."
fi

INSTALL_DIR=$(abs_dir "$INSTALL_DIR")
if [ -z "$WORKSPACE_DIR" ]; then
  WORKSPACE_DIR="$INSTALL_DIR/workspace"
fi
WORKSPACE_DIR=$(abs_dir "$WORKSPACE_DIR")
SSH_DIR=$(abs_dir "$SSH_DIR")

case "$UID_VALUE" in
  ''|*[!0-9]*) die "--uid must be numeric, got: $UID_VALUE" ;;
esac
case "$GID_VALUE" in
  ''|*[!0-9]*) die "--gid must be numeric, got: $GID_VALUE" ;;
esac
if [ "$UID_VALUE" = "0" ] || [ "$GID_VALUE" = "0" ]; then
  warn "current uid/gid is root; using 1000:1000 for the container dev user"
  UID_VALUE=1000
  GID_VALUE=1000
fi

COMPOSE_FILE="$INSTALL_DIR/compose.yml"
ENV_FILE="$INSTALL_DIR/.env"

if write_file "$COMPOSE_FILE" "compose.yml"; then
  cat > "$COMPOSE_FILE" <<'EOF'
services:
  dev-home:
    image: ${DEV_HOME_IMAGE}
    container_name: ${DEV_HOME_CONTAINER_NAME}
    network_mode: host
    working_dir: /home/dev
    restart: unless-stopped
    stdin_open: true
    tty: true
    environment:
      DEV_HOME_WORKSPACE: /workspace
      DEV_UID: ${DEV_UID}
      DEV_GID: ${DEV_GID}
    volumes:
      - dev-home-home:/home/dev
      - "${DEV_HOME_WORKSPACE_DIR}:/workspace"
      - "${DEV_HOME_SSH_DIR}:/host-ssh:ro"

volumes:
  dev-home-home:
EOF
fi

if write_file "$ENV_FILE" ".env"; then
  old_umask=$(umask)
  umask 077
  cat > "$ENV_FILE" <<EOF
DEV_HOME_IMAGE=$IMAGE
DEV_HOME_CONTAINER_NAME=$NAME
DEV_HOME_WORKSPACE_DIR=$WORKSPACE_DIR
DEV_HOME_SSH_DIR=$SSH_DIR
DEV_UID=$UID_VALUE
DEV_GID=$GID_VALUE
EOF
  umask "$old_umask"
fi

check_github_ssh

echo "==> NAS files"
echo "compose: $COMPOSE_FILE"
echo "env:     $ENV_FILE"
echo "home:    Docker volume dev-home-home"
echo "work:    $WORKSPACE_DIR -> /workspace"
echo "ssh:     $SSH_DIR -> /host-ssh:ro"
echo "uid/gid: $UID_VALUE:$GID_VALUE"

if [ "$DO_PULL" = "1" ]; then
  echo "==> Pulling image"
  (cd "$INSTALL_DIR" && compose pull)
fi

if [ "$DO_START" = "1" ]; then
  echo "==> Starting dev-home"
  (cd "$INSTALL_DIR" && compose up -d)
fi

cat <<EOF

Done.

Enter:
  cd "$INSTALL_DIR"
  $COMPOSE_CMD exec dev-home tmux new -A -s main

Logs:
  cd "$INSTALL_DIR"
  $COMPOSE_CMD logs -f
EOF
