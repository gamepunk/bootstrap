# bootstrap

个人 macOS 环境一键配置仓库，使用 [chezmoi](https://www.chezmoi.io/) 管理配置文件，配合 Homebrew Bundle 恢复软件。仓库为 **私有**。

## 管理内容

| 文件/目录 | 说明 |
|---|---|
| `~/.zshrc` | zsh 配置 |
| `~/.zprofile` | shell 启动配置（含 brew shellenv） |
| `~/.gitconfig` | Git 全局配置 |
| `~/.config/mise/config.toml` | 语言运行时版本管理 |
| `~/.config/zed/settings.json` | Zed 编辑器设置 |
| `~/.config/starship.toml` | 终端提示符配置 |
| `~/.config/gh/config.yml` | GitHub CLI 配置（不含 token） |
| `~/.config/brew/Brewfile` | 所有 brew / cask / App Store / VS Code 插件清单 |
| `~/.config/ghostty/config.ghostty` | Ghostty 终端配置 |
| `~/.config/netnewswire/Subscriptions-OnMyMac.opml` | RSS 订阅列表 |
| `~/Library/Application Support/Sublime Text/Packages/User` | Sublime 用户配置与插件清单 |
| `~/Library/Application Support/xbar/plugins` | xbar 自定义脚本插件 |
| `~/Library/Application Scripts/com.apple.mail/mail-motherfucker.scpt` | 邮件自动化脚本 |
| `~/Library/Sounds/Motherfucker.caf` | 自定义提示音 |

**说明**：VS Code 的设置/插件/快捷键交给官方 **Settings Sync** 管理，不在本仓库中。

## 新电脑配置

仓库为私有，需要先通过 `gh auth login` 完成身份验证：

```bash
brew install chezmoi gh
gh auth login
chezmoi init --apply https://github.com/gamepunk/bootstrap.git
bash ~/.local/share/chezmoi/setup.sh
```

`setup.sh` 会自动完成：

1. 安装 Homebrew（如未安装）
2. 安装 oh-my-zsh（如未安装）
3. 安装 chezmoi 并恢复所有配置文件
4. 通过 Brewfile 安装所有软件（brew / cask / App Store / VS Code 插件）
5. 重新加载 shell 配置
6. 通过 mise 安装语言运行时
7. 登录 GitHub CLI
8. 修复 xbar 插件的可执行权限

脚本结束后会打印一份 **手动操作清单**，请逐项检查完成：

- [ ] **VS Code**：打开后登录账号，开启 Settings Sync（账户图标 → Turn on Settings Sync）
- [ ] **Sublime Text**：打开后 Package Control 会根据同步的配置提示恢复插件，按提示确认安装
- [ ] **NetNewsWire**：打开后 File → Import Subscriptions...，选择 `~/.config/netnewswire/Subscriptions-OnMyMac.opml`
- [ ] **SSH key**：出于安全考虑未同步旧密钥，需要重新生成并添加到 GitHub：
  ```bash
  ssh-keygen -t ed25519 -C "你的邮箱"
  ```
  然后到 [github.com/settings/keys](https://github.com/settings/keys) 添加公钥
- [ ] **Clash Verge Rev**：订阅链接含敏感信息，未同步，需要手动重新添加订阅
- [ ] **账号类应用需要重新登录**：Bitwarden / ChatGPT / Codex App / QQ / 微信 / Telegram / Tailscale / 迅雷 / TradingView
- [ ] **BetterDisplay / Loop / Raycast**：配置未同步，需要手动重新设置一次
- [ ] **邮件规则（Mail Rules）**：脚本已恢复相关的 `.scpt` 脚本和提示音文件，但规则本身（`SyncedRules.plist`）未纳入管理，如需要请在 Mail 偏好设置里手动重新配置

## 常用命令

为方便进入仓库目录，`.zshrc` 中已配置 alias：

```bash
cdz   # 等同于 cd ~/.local/share/chezmoi
```

### 修改配置文件后同步

```bash
chezmoi add ~/.zshrc      # 举例，替换成实际改动的文件
cdz
git add .
git commit -m "update config"
git push
```

### 更新 Brewfile（装/卸软件后）

```bash
brew bundle dump --file=~/.config/brew/Brewfile --force
chezmoi add ~/.config/brew/Brewfile
cdz
git add .
git commit -m "update brewfile"
git push
```

### 检查已卸载的 cask/formula 是否还留在 Brewfile

```bash
brew bundle check --file=~/.config/brew/Brewfile --verbose
```

### 更新 RSS 订阅列表

NetNewsWire 中 File → Export Subscriptions... 覆盖导出到原路径后：

```bash
chezmoi add ~/.config/netnewswire/Subscriptions-OnMyMac.opml
cdz
git add .
git commit -m "update rss subscriptions"
git push
```

### 检查本地是否有未同步的改动

```bash
chezmoi diff
```

### 查看当前管理的所有文件

```bash
chezmoi managed
```

## 未纳入管理的内容（有意排除）

以下内容出于安全或数据体积考虑，不通过本仓库同步：

- `~/.ssh`（私钥，重新生成更安全）
- Clash Verge Rev 的订阅配置（含账号 token）
- 各类账号类应用的登录态（Bitwarden、ChatGPT、QQ、微信等，重新登录即可）
- `~/.oh-my-zsh`（第三方开源项目文件，由 setup.sh 重新安装，不占用仓库空间）
- VS Code 的 User 目录（交给官方 Settings Sync，避免同步缓存/登录态）
- NetNewsWire 的数据库文件（二进制、体积大，仅同步 OPML 订阅列表）