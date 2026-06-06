# dev-home 项目设计原则

## 构建与运行

- **仅使用 compose** — 所有操作通过 `podman compose --in-pod false` 完成，配置集中在 `compose.yml`。
- **分层职责** — Containerfile 负责无需网络的基础固化（apt 换源、用户创建、COPY 入口脚本）；entrypoint.sh 负责运行时初始化（apt 安装、Intel 核显用户态包、nushell、mise、工具、配置），网络操作集中在运行时阶段。

## 文件职责

- `compose.yml` — 容器编排的唯一配置源，`network_mode: host` 使运行时共享宿主机网络；Intel 核显通过 `/dev/dri` 的 `devices` 占位、`group_add: keep-groups`、`security_opt: label=disable` 支持
- `Containerfile` — 镜像定义：基于 `ghcr.io/nushell/nushell:latest-bookworm` (Debian 12)，ENV locale + 时区设置 + 用户创建 + COPY entrypoint.sh。RUN 仅限纯本地操作，不依赖网络。
- `.containerignore` — 本地/CI 构建上下文过滤，必须排除 `.env`、`.env.*`、`.git` 和常见私钥文件
- `entrypoint.sh` — 内置于镜像（`/usr/local/bin/entrypoint.sh`）。Phase 1（root）：Debian apt 换源 → apt 系统依赖与 Intel 核显用户态包 → locale-gen → vendor dir → re-exec 为 dev；Phase 2（dev）：mise + 工具 + ohmynushell 配置 + vendor autoloads + oh-my-tmux
- 工具版本直接在 entrypoint.sh 中通过 `mise use -g` 指定，无需独立配置文件
- `dev` — 便利脚本，封装 compose 命令，执行 `build`/`rebuild`/`pull`/`start`/`stop`/`restart`/`recreate`/`status`/`logs`/`enter`/`nu`/`sh`/`gpu`/`install`/`clean`/`reset-home`/`purge`
- `.env` — GITHUB_TOKEN、DEV_HOME_HOST_WORKSPACE、DEV_HOME_GPU/DEV_HOME_DRI_DEVICE，本地文件，gitignore

## 关键细节

- tmux `default-command` 必须 `nu --login`，否则 env.nu 不加载，`~/.local/bin` 不在 PATH
- compose 和 `dev` exec 默认工作目录必须是 `/home/dev`
- `dev` 用户 sudo 必须 NOPASSWD；root 密码为 `root`，dev 密码为 `dev`
- Containerfile 构建时仅需基础镜像拉取（FROM ghcr.io/nushell/nushell），RUN 指令为纯本地操作无需网络；运行时 `network_mode: host` 共享宿主机网络，apt/mise 通过代理下载
- nushell 来自基础镜像（`/usr/bin/nu`），不再运行时下载
- nushell 配置来自 `git@github.com:hyoukadev/ohmynushell.git`，直接 clone 到 `~/.config/nushell`，inits/linux.nu 被替换为容器版（PATH + 环境变量代理，不硬编码）
- `mise/starship/zoxide` 必须参考 ohmynushell 仓库 `.agent/skills` 写入 `~/.local/share/nushell/vendor/autoload`，`starship.toml` 使用 Catppuccin 主题，`yazi` 通过 ohmynushell 的 `y` helper 使用
- `dev` 用户默认 UID/GID 为 `1000:1000`，compose 使用 `userns_mode: keep-id`；宿主机 `~/.ssh` 只读挂载到 `/host-ssh`，entrypoint 生成容器内 `~/.ssh`（私钥 symlink，config/known_hosts 复制），避免 rootless UID 造成权限问题
- Intel 核显支持保持可选：`DEV_HOME_GPU=auto|none|intel|dri`；默认自动探测 `/dev/dri`，无设备时使用 dummy device 保持云端构建和无核显主机可启动；实际启用 `/dev/dri` 时 entrypoint 必须保留 Podman `keep-groups` 传入的补充组
- GitHub Actions 使用仓库内置 `GITHUB_TOKEN` 发布 GHCR 镜像到 `ghcr.io/<owner>/<repo>`；当前仓库内容允许 public package，本地 compose 镜像名通过 `.env` 中的 `DEV_HOME_IMAGE` 覆盖，默认仍为本地 `dev-home`
