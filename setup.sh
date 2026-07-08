#!/bin/bash
set -e  # 任何一步出错就停止,避免后面步骤在错误状态下继续执行

echo "==> 1. 安装 Homebrew"
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "Homebrew 已安装,跳过"
fi

echo "==> 2. 安装 chezmoi 并恢复配置"
brew install chezmoi
chezmoi init --apply https://github.com/gamepunk/bootstrap.git

echo "==> 3. 安装所有软件"
brew bundle install --file=~/.config/brew/Brewfile

echo "==> 4. 重新加载 shell 配置"
source ~/.zshrc

echo "==> 5. 安装语言运行时"
mise install

echo "==> 6. 登录 GitHub CLI"
gh auth login

echo "==> 全部完成!"
