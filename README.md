# 我的跨平台开发工具链配置之旅

## 动机

To make cross-platform developing consistent, efficient and more enjoyable, I start to find some cross-platform alternatives to meet my daily development workflow. Here is the result of my selections for "learn once, use anywhere", and I would like to share them with you.

我日常会使用 Windows、Linux（Native & WSL2）、macOS 进行开发和日常娱乐等活动，也希望跨平台用到的开发工具尽可能保持一致、高效和愉悦的体验。因此，我开始寻找能满足我日常开发工作流的跨平台替代。这里就是我为了达成“learn once， use anywhere”效果所做的选择，我使用了一段时间觉得真不错，也想和你们一起分享这些工具。当然，我还在逐渐完善这套工具集的过程中，其中有些工具在部分平台尚未达到平替效果、或有的工具本身功能还在建设过程中，但都有一定的潜力，我愿意现在就学习和使用他们承担一部分日常使用场景。

这里是所有工具的预览：
- symlink manager (改进中)
- rust-lang + cargo
- nushell
- helix editor
- `zoxide`, `fzf`, `yazi`, `fd`
- `mise`, `uv`
- wezterm

本文不会包含习以为常的跨平台开发工具，如：
- git
- vscode
- vim & emacs
- ...

也不会包含非跨全平台的开发工具，如：
- tmux & itmux & zellij
- bash & zsh & fish shell
- Cygwin & MSYS2 & MinGW
- ...

## 系统配置

### Windows

🔶新机器需要在 设置 -> 系统 -> 开发者选项 中配置
✅PowerShell 执行策略
✅启用 sudo 命令
![Windows Settings about developers](./docs/assets/windows_settings_about_developers.png)

### 原则和行动准则

本着方便安装、更新、卸载、搜索的管理原则

1. Windows 优先用 `winget` 安装命令行工具，而不是 `cargo`
  - 因为 `cargo` 的安装在 Windows 上步骤较多，等待时间较长（需要安装 visual studio 或 msvc）
  - 因为通过 `cargo` 安装需要等待依赖下载和编译，较慢
  - 因为几乎所有开发工具都可以通过 `winget` 安装完成，减少了学习和选择安装方式的成本
2. Linux 优先用 `cargo` 安装命令行工具，而不是 `apt` 等
  - 因为源内的软件版本可能较旧
3. MacOS 优先用 `cargo` 安装命令行工具，而不是 `brew` 等
  - 减少需要关注的命令行
  - 对更多人来说，`cargo` 的安装比 `brew` 换源更简便

## 工具

### Helix Editor
- 🎯 跨平台编辑器配置，满足个人日常开发使用
  - 🟩 一键安装各种字体
  - 🟩 一键安装各种 LSP
  - 🟩 开箱即用的前端开发配置
  - 🟩 开箱即用的 Rust 开发配置
- 🎯 跨平台工具链配置，变成强大的集成开发环境
  - 🟩 yazi
  - 🟩 wezterm
- 🎯 跨平台面向未来和 AI 的配置，满足自动化开发需求

### NuShell + Oh My Posh

🔶为什么我选择使用 NuShell

1. 跨平台，做到 "learn once, use anywhere"
2. 内建命令比 PowerShell 简单、好记，且命令行批处理数据的功能同样强大
3. 统一的快捷键操作：作为 shell 在 Windows 下使用同样支持 unix 快捷键（如 `ctrl+b/f` 将光标按字母移动，`alt+b/f` 将光标按单词移动）


✅ nushell 在 Windows Terminal 中魔法上网配置
- ✅ WSL2 需要在 WSL2 设置中对 Network 选上 Mirror
- ✅ Windows 下：1️⃣开启魔法应用的 Tun 功能 2️⃣或者手动设置 `$env.http_proxy` 等环境变量

✅ nushell 作为默认 shell 程序
![nushell as Windows Terminal default shell](./docs/assets/nushell_as_windows_terminal_default_profile.png)

### Yazi

### Rust 语言和 Cargo

✅ cargo crate 国内镜像配置：[crates.io-index | 镜像站使用帮助 | 清华大学开源软件镜像站 | Tsinghua Open Source Mirror](https://mirrors.tuna.tsinghua.edu.cn/help/crates.io-index/)

把 rust 当做跨平台脚本使用，同时可以编译成多平台可执行文件

#### error: linker `link.exe` not found
在 windows 上使用 rust cargo 安装 just 遇到链接器问题：
原因是 rust 在 windows 上编译依赖 msvc linker
[MSVC prerequisites - The rustup book](https://rust-lang.github.io/rustup/installation/windows-msvc.html)
[在 Windows 上针对 Rust 设置开发环境 | Microsoft Learn](https://learn.microsoft.com/zh-cn/windows/dev-environment/rust/setup)
依赖 msvc linker 的原因是 Windows 上有两种 ABI，一种是 MSVC ABI，一种 GNU ABI

### Symlink Manager

- [mehmet-erim/symlink-manager: Symlink Manager easily manages to symbolic link processes of your dependency packages.](https://github.com/mehmet-erim/symlink-manager)
- [Stow - GNU Project - Free Software Foundation](https://www.gnu.org/software/stow/)
- [vadorovsky / verstau · GitLab](https://gitlab.com/vadorovsky/verstau)
- [thialfi17/lash: Symlink manager for dotfiles - a GNU Stow alternative](https://github.com/thialfi17/lash)

```ts
interface PathConfig {
  source: string;
  target: string;
  action: "soft" | "hard" | "copy"
}
```

### rime

```nu
# macOS
git clone https://github.com/ksqsf/rime-moran ~/Library/Rime --depth=1
```

