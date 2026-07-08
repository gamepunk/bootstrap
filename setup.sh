#!/bin/bash
set -e

echo "==> 1. 安装 Homebrew"
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "Homebrew 已安装，跳过"
fi

echo "==> 2. 安装 oh-my-zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "oh-my-zsh 已安装，跳过"
fi

echo "==> 3. 安装 chezmoi 并恢复配置"
brew install chezmoi
chezmoi init --apply https://github.com/gamepunk/bootstrap.git

echo "==> 4. 安装所有软件（brew / cask / App Store / VS Code 插件）"
brew bundle install --file=~/.config/brew/Brewfile

echo "==> 5. 重新加载 shell 配置"
source ~/.zshrc

echo "==> 6. 安装语言运行时"
mise install

echo "==> 7. 登录 GitHub CLI"
gh auth login

echo "==> 8. 修复 xbar 插件执行权限"
if [ -d "$HOME/Library/Application Support/xbar/plugins" ]; then
  chmod +x "$HOME/Library/Application Support/xbar/plugins"/*
fi

echo ""
echo "=================================================="
echo "  自动化部分已全部完成！"
echo "  以下步骤需要手动操作，请逐项检查完成："
echo "=================================================="
echo ""
echo "  [ ] 1. VS Code：打开后登录账号，开启 Settings Sync"
echo "         （账户图标 -> Turn on Settings Sync）"
echo ""
echo "  [ ] 2. Sublime Text：打开后 Package Control 会根据"
echo "         已同步的配置提示恢复插件，按提示确认安装"
echo ""
echo "  [ ] 3. NetNewsWire：打开后 File -> Import Subscriptions..."
echo "         选择 ~/.config/netnewswire/Subscriptions-OnMyMac.opml"
echo ""
echo "  [ ] 4. SSH key：本机没有同步旧密钥（出于安全考虑），"
echo "         需要重新生成并添加到 GitHub："
echo "         ssh-keygen -t ed25519 -C \"你的邮箱\""
echo "         然后到 https://github.com/settings/keys 添加公钥"
echo ""
echo "  [ ] 5. Clash Verge Rev：订阅链接未同步（含敏感信息），"
echo "         需要手动重新添加订阅"
echo ""
echo "  [ ] 6. 账号类应用需要重新登录："
echo "         Bitwarden / ChatGPT / Codex App / QQ / 微信 /"
echo "         Telegram / Tailscale / 迅雷 / TradingView"
echo ""
echo "  [ ] 7. BetterDisplay / Loop / Raycast："
echo "         配置未同步，需要手动重新设置一次"
echo ""
echo "  [ ] 8. 邮件规则（Mail Rules）：脚本已恢复相关的"
echo "         .scpt 脚本和提示音文件，但邮件规则本身"
echo "         （SyncedRules.plist）未纳入管理，如需要"
echo "         请手动在 Mail 偏好设置里重新配置规则"
echo ""
echo "=================================================="