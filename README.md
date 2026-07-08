# bootstrap

个人 macOS 环境一键配置仓库,使用 [chezmoi](https://www.chezmoi.io/) 管理配置文件,配合 Homebrew Bundle 恢复软件。

## 管理内容

- `~/.zshrc`
- `~/.config/mise/config.toml`(语言运行时版本管理)
- `~/.config/zed/settings.json`
- `~/.config/starship.toml`
- `~/.config/gh/config.yml`
- `~/.config/brew/Brewfile`(所有 brew / cask / App Store 软件清单)
- Sublime Text 用户配置(`~/Library/Application Support/Sublime Text/Packages/User`)

## 新电脑恢复步骤

\`\`\`bash
# 1. 安装 Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# 2. 安装 chezmoi 并拉取配置
brew install chezmoi
chezmoi init https://github.com/gamepunk/bootstrap.git

# 3. 跑一键脚本(会自动 apply 配置 + 装软件 + mise install)
bash ~/.local/share/chezmoi/setup.sh
\`\`\`

## 手动步骤(setup.sh 里也会做,但列出来方便单独排查)

\`\`\`bash
chezmoi apply
brew bundle install --file=~/.config/brew/Brewfile
source ~/.zshrc
mise install
gh auth login
\`\`\`

## 日常维护

改了配置文件后,同步进仓库:

\`\`\`bash
chezmoi add ~/.zshrc          # 举例,替换成实际改动的文件
cd $(chezmoi source-path)
git add .
git commit -m "update config"
git push
\`\`\`

更新 Brewfile(装/卸软件后):

\`\`\`bash
brew bundle dump --file=~/.config/brew/Brewfile --force
chezmoi add ~/.config/brew/Brewfile
cd $(chezmoi source-path)
git add .
git commit -m "update brewfile"
git push
\`\`\`
