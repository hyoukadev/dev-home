# dev-home

基于 `podman compose` 的个人开发容器。镜像只做本地基础固化，所有需要网络的初始化都在容器启动后执行，方便走宿主机代理和网络环境。

## 目标

- 统一的 Nushell + tmux 终端入口
- Python / Node.js / Go / Rust 等 AI bot 常用开发栈
- `uv`、`pnpm`、`bun`、`gh`、`kubectl`、`terraform`、`flyctl` 等开发和部署工具
- 通过 `mise use -g tool@version` 继续安装工具
- Nushell 配置从 `git@github.com:hyoukadev/ohmynushell.git` 克隆，并预置 `mise`、`starship`、`zoxide`、`yazi` 集成
- `/home/dev` 使用 compose named volume 持久化，重建容器不丢工具和配置
- `/workspace` 挂载宿主机项目目录
- `userns_mode: keep-id` + `/host-ssh:ro` 让容器内 `dev` 用户使用宿主机 SSH key，同时把 `known_hosts` 修正到可读的容器内副本
- 默认工作目录为 `/home/dev`

## 快速开始

```bash
cp .env.example .env
# 可选：编辑 .env，写入 GITHUB_TOKEN 和 DEV_HOME_HOST_WORKSPACE
./dev build
./dev start
./dev enter
```

首次启动会安装 apt 依赖、mise 工具、Nushell 配置和 tmux 配置。Nushell 配置通过 SSH 直接克隆 `git@github.com:hyoukadev/ohmynushell.git` 到 `~/.config/nushell`，初始化完成后，后续启动会复用 `/home/dev` 的持久化结果。

容器内 `dev` 和 `root` 密码默认都是同名密码：`dev` / `root`。正常提权使用 `sudo`，已配置 `dev ALL=(ALL) NOPASSWD: ALL`。

## 命令

| 命令 | 作用 |
|------|------|
| `./dev build` | 构建镜像 |
| `./dev rebuild` | 无缓存重建镜像 |
| `./dev pull` | 拉取 `.env` 中 `DEV_HOME_IMAGE` 配置的远程镜像 |
| `./dev start` | 启动容器 |
| `./dev stop` | 停止容器 |
| `./dev restart` | 重启容器 |
| `./dev recreate` | 使用当前镜像重建容器 |
| `./dev status` | 查看 compose 状态 |
| `./dev logs` | 跟随容器日志 |
| `./dev enter` | 进入 tmux 会话 |
| `./dev nu` | 进入 Nushell |
| `./dev sh` | 进入 POSIX shell |
| `./dev install node@24 uv@latest` | 安装全局 mise 工具 |
| `./dev clean` | 删除容器和本地镜像，保留 home volume |
| `./dev reset-home` | 删除持久化 home volume |
| `./dev purge` | 深度清理 Podman/Buildah 构建缓存和 dangling 镜像，保留 home volume |

## 安装工具

容器内直接使用 mise：

```bash
mise use -g python@3.13
mise use -g node@24
mise use -g go@1.24
mise use -g github-cli@latest
```

或者从宿主机执行：

```bash
./dev install deno@latest ripgrep@latest
```

## 工作目录

默认把仓库上级目录挂载到 `/workspace`。需要指定其它目录时，在 `.env` 中设置：

```bash
DEV_HOME_HOST_WORKSPACE=/home/hyouka/item
```

然后重启：

```bash
./dev restart
```

## 默认工具

默认版本在 [entrypoint.sh](/home/hyouka/item/dev-home/entrypoint.sh) 顶部维护。修改后提升 `BOOTSTRAP_VERSION`，再执行：

```bash
./dev restart
```

如需完全重新初始化用户环境：

```bash
./dev reset-home
./dev start
```

Nushell 登录后会自动加载：

- `mise` activation
- `starship` prompt
- Catppuccin starship theme
- `zoxide` jump
- ohmynushell 中的 `y`/yazi 辅助命令

## SSH

容器内 `dev` 用户默认使用 `1000:1000`。宿主机 `~/.ssh` 只读挂载到 `/host-ssh`，entrypoint 会生成容器内 `~/.ssh`：私钥用 symlink 指向 `/host-ssh`，`config` 和 `known_hosts` 使用容器内副本，避免旧 rootless UID 导致 host key 读取失败。

```bash
ssh -T git@github.com
```

如果宿主机用户不是 `1000:1000`，构建时覆盖：

```bash
podman compose build --build-arg DEV_UID=$(id -u) --build-arg DEV_GID=$(id -g)
./dev recreate
```

## GHCR 私有镜像

仓库包含 GitHub Actions workflow，会在 push 到默认分支或 `v*` tag 时构建并推送镜像到 GHCR：

- `ghcr.io/<owner>/<repo>:sha-<short-sha>`
- 默认分支额外推送 `ghcr.io/<owner>/<repo>:latest`
- `v*` tag 额外推送原始 tag 和去掉 `v` 的版本 tag

workflow 使用仓库 secret `GHCR_TOKEN` 登录 GHCR。这个 token 需要是 classic PAT，并至少包含 `write:packages` 和 `read:packages`。如果需要删除已发布的 package 版本，还需要 `delete:packages`。

GHCR package 是否私有由 GitHub package visibility 控制。对于 public repo，建议先确认 package settings 中 visibility 为 private，再作为日常镜像源使用；public package 在 Container registry 中允许匿名拉取。

本机拉取私有 GHCR 镜像需要先登录：

```bash
echo '<token-with-read:packages>' | podman login ghcr.io -u '<github-user>' --password-stdin
```

然后在 `.env` 里指定镜像：

```bash
DEV_HOME_IMAGE=ghcr.io/<owner>/<repo>:latest
```

拉取并重建容器：

```bash
./dev pull
./dev recreate
```

## 设计约束

- 只通过 `podman compose --in-pod false` 编排和进入容器，避免 Podman pod 与 `userns_mode: keep-id` 冲突
- `Containerfile` 不做网络安装，只保留本地操作
- `entrypoint.sh` 负责运行时 apt、mise、Nushell、tmux 初始化
- tmux 使用 `nu --login`，确保 Nushell 环境和 PATH 正常加载
