# dotfiles

個人用の設定ファイルです。

## セットアップ

```bash
mkdir -p ~/.config/{gh-dash,git,mise,tmux}
ln -sfn ~/Work/dotfiles/.config/gh-dash/config.yml ~/.config/gh-dash/config.yml
ln -sfn ~/Work/dotfiles/.config/git/config ~/.config/git/config
ln -sfn ~/Work/dotfiles/.config/mise/config.toml ~/.config/mise/config.toml
ln -sfn ~/Work/dotfiles/.config/tmux/tmux.conf ~/.config/tmux/tmux.conf
ln -sfn ~/Work/dotfiles/.tmux.conf ~/.tmux.conf
```

`~/.config/git/local` はマシン固有のGit設定用です。このファイルはGit管理しません。
