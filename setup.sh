#!/bin/bash
set -e

echo "==> 1. 安装 Homebrew"
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "==> 2. 安装 oh-my-zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo "==> 3. 安装 chezmoi 并恢复配置"
brew install chezmoi
chezmoi init --apply https://github.com/gamepunk/bootstrap.git

echo "==> 4. 安装所有软件"
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

echo "==> 全部完成!"