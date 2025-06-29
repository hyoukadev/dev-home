use anyhow::{Context, Result};
use clap::Parser;
use std::fs;
use std::path::{Path, PathBuf, absolute};
use toml::de::from_str;
use serde::Deserialize;

// 新增配置目录获取 trait
trait ConfigDirProvider {
    fn config_dir(&self) -> Result<PathBuf>;
}

// 默认实现（生产环境使用）
struct XdgConfigDirProvider;
impl ConfigDirProvider for XdgConfigDirProvider {
    fn config_dir(&self) -> Result<PathBuf> {
        dirs::config_dir().context("系统配置目录获取失败")
    }
}

#[derive(Deserialize, Debug)]
struct EntireConfig {
    symlinks: Vec<SymlinkConfig>
}

#[derive(Deserialize, Debug)]
struct SymlinkConfig {
    source: PathBuf,
    target: PathBuf,
    filter: SymlinkFilterConfig,
}

#[derive(Deserialize, Debug)]
struct SymlinkFilterConfig {
    os: Vec<String>
}



// fn load_config(file_path: &str) -> Result<EntireConfig> {}

#[derive(Parser, Debug)]
#[clap(about = "跨平台配置同步工具")]
struct Args {
    #[clap(short, long)]
    source_dir: PathBuf,

    #[clap(short, long)]
    config: PathBuf,

    #[clap(short, long)]
    debug: bool,
}

fn main() -> Result<()> {
    let args = Args::parse();
    let source_dir = absolute(args.source_dir.as_path()).unwrap();
    let target_dir_provider = XdgConfigDirProvider;
    let apps = vec!["helix", "nushell", "Rime"];


    let config_path = absolute(args.config.as_path()).unwrap();
    let config_content = fs::read_to_string(config_path.as_path())
    .expect("");

    if args.debug {
        println!(
            "source_dir: {}\ntarget_dir: {}",
            source_dir.display(),
            target_dir_provider.config_dir()?.display()
        );
        println!(
          "config_path: {}\n{}",
          config_path.display(),
          config_content
        );
        return Ok(());
    }

    run_sync(&source_dir, &target_dir_provider, apps)
}

// 核心逻辑抽取为可测试函数
fn run_sync(
    source_dir: &Path,
    target_dir_provider: &dyn ConfigDirProvider,
    apps: Vec<&str>,
) -> Result<()> {
    for app in apps.iter() {
        handle_app(source_dir, target_dir_provider, app)?;
    }
    Ok(())
}

// 修改后的处理函数
fn handle_app(
    source_dir: &Path,
    target_dir_provider: &dyn ConfigDirProvider,
    app: &str,
) -> Result<()> {
    let source = source_dir.join(app);
    let target = target_dir_provider.config_dir()?.join(app);

    // 检查源是否存在
    if !source.exists() {
        anyhow::bail!("应用 {} 的配置源目录不存在: {:?}", app, source);
    }

    // 处理目标路径
    if target.exists() {
        let metadata = std::fs::symlink_metadata(&target)?;
        if metadata.file_type().is_symlink() {
            let current_source = std::fs::read_link(&target)?;
            if current_source == source {
                println!("✅ {} 配置已正确链接，跳过", app);
                return Ok(());
            }
            println!("🔄 检测到旧的符号链接，重新创建 {}", app);
            std::fs::remove_file(&target)?;
        } else {
            let backup = target.with_extension("bak");
            std::fs::rename(&target, &backup).context("无法备份现有配置")?;
            println!("📦 备份 {} 配置至 {:?}", app, backup);
        }
    }

    // 创建符号链接
    symlink(&source, &target).with_context(|| format!("无法为 {} 创建符号链接", app))?;

    println!("🔗 成功链接 {} 配置：{:?} → {:?}", app, source, target);
    Ok(())
}

// 保持原有的符号链接实现
#[cfg(unix)]
fn symlink(source: &Path, target: &Path) -> std::io::Result<()> {
    std::os::unix::fs::symlink(source, target)
}

#[cfg(windows)]
fn symlink(source: &Path, target: &Path) -> std::io::Result<()> {
    // 假设所有配置均为目录
    std::os::windows::fs::symlink_dir(source, target)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::path::PathBuf;
    use uuid::Uuid;


    #[cfg(test)]
    struct TestConfigDirProvider(PathBuf); // 添加 pub 修饰符

    #[cfg(test)]
    impl ConfigDirProvider for TestConfigDirProvider {
        fn config_dir(&self) -> Result<PathBuf> {
            Ok(self.0.clone())
        }
    }

    // 新增：项目相对路径测试目录
    fn create_temp_test_dir_in_project(test_name: &str) -> PathBuf {
        let project_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        let uuid_part = Uuid::new_v4().as_simple().to_string();
        let temp_test_dir = project_dir
            .join("temp")
            .join(format!("{}_{:.6}", test_name, uuid_part));

        let _ = fs::remove_dir_all(&temp_test_dir);
        fs::create_dir_all(&temp_test_dir).unwrap();
        temp_test_dir
    }

    #[test]
    fn test_symlink_to_target_dirs() -> Result<()> {
        // 在项目目录创建测试环境
        let temp_test_dir = create_temp_test_dir_in_project("container");
        let temp_source_dir = temp_test_dir.join("config");
        fs::create_dir(&temp_source_dir)?;

        // 准备测试数据
        let app_name = "sample_app";
        let mock_app_dir = temp_source_dir.join(app_name);
        fs::create_dir(&mock_app_dir)?;
        fs::write(mock_app_dir.join("settings.toml"), "[content]")?;

        // 配置目录放在项目目录内
        let temp_target_dir = temp_test_dir.join("config_symlink");
        fs::create_dir(&temp_target_dir)?;
        let temp_target_dir_provider = TestConfigDirProvider(temp_target_dir.clone());
        run_sync(&temp_source_dir, &temp_target_dir_provider, vec![app_name])?;

        // 验证路径可见性
        println!("测试生成目录位于：{}", temp_target_dir.display());
        assert!(temp_target_dir.exists());

        // 测试结束后不自动删除（需手动清理）
        Ok(())
    }
}
