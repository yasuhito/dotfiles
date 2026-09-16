# dotfiles

個人用の設定ファイルです。`home/` 以下は `$HOME` に配置する内容と同じ構成になっています。

## 収録している設定

- Git、gh-dash、mise
- Omarchy のデフォルトを読み込む Hyprland Lua 設定と個人用 override 一式
- WezTerm と、Omarchy のデフォルトターミナルを WezTerm にする設定
- エージェント向けの共通指示

Hyprland 設定には、フォーカス中のウィンドウを示す赤い枠線と、非アクティブなウィンドウを暗くする設定が含まれます。Omarchy が提供する Lua モジュールを前提とし、モニター固有の EDID やバックアップ、生成された設定は収録していません。

## セットアップ

新しく clone したリポジトリで、適用先のホームディレクトリを明示して次の 1 コマンドを実行します。

```bash
./install.sh "$HOME"
```

`install.sh` は `home/` 内の Git 管理対象ファイルへのシンボリックリンクを作ります。Hyprland と WezTerm の設定もそれぞれ `~/.config/hypr/` と `~/.config/wezterm/` に配置されます。同じコマンドは何度実行しても安全です。同じ Git リポジトリの別 checkout を指す既存リンクは、現在の checkout を指すように更新します。適用先に管理外のファイルや別リポジトリのリンクがある場合は、どの設定も変更せずエラーにします。別のホームディレクトリで試す場合も、たとえば `./install.sh "/tmp/test home"` のように適用先を引数で指定してください。

## Omarchy のデフォルトターミナル

この設定には WezTerm と `xdg-terminal-exec` が必要です。Omarchy 4.x が `$TERMINAL=xdg-terminal-exec` として起動するターミナルは、`~/.config/xdg-terminals.list` の先頭にある `org.wezfurlong.wezterm.desktop` を選択します。Ghostty などの他のターミナルは削除せず、Omarchy や `xdg-terminal-exec` 側の fallback として残します。

WezTerm の system desktop entry には `xdg-terminal-exec` 用の引数情報がないため、同じ desktop ID の user entry を `~/.local/share/applications/` に配置しています。これは WezTerm の選択時だけ system entry を補完します。`~/.local/bin/wezterm-xdg-terminal-exec` は通常起動、作業ディレクトリ、Wayland app-id/class、タイトル、`-e` のコマンド実行を WezTerm の CLI に変換します。Hyprland では native Wayland の class `org.wezfurlong.wezterm` だけを既存の `terminal` tag に追加し、Omarchy の TUI 用 app-id に対する float/tile rule はそのまま利用します。

Omarchy や WezTerm の更新後は、desktop ID と CLI metadata の前提が変わっていないか次のコマンドで確認してください。確認だけなら Hyprland や Waybar の reload は不要です。

```bash
xdg-terminal-exec --print-id
xdg-terminal-exec --print-cmd --dir=/tmp --app-id=TUI.float --title=Check -e printf '%s\n' ok
wezterm start --help
```

1 つ目は `org.wezfurlong.wezterm.desktop`、2 つ目は `wezterm-xdg-terminal-exec` に続いて `--class TUI.float`、`--title Check`、`--cwd /tmp`、`--` と実行コマンドを表示するのが期待値です。実ウィンドウの class は `hyprctl clients` でも確認できます。

## 以前のレイアウトからの移行

以前のセットアップ手順で作った、リポジトリ直下の設定を指すリンクは `./install.sh "$HOME"` が新しい `home/` 内のリンクへ安全に更新します。リンク元が現在とは別の場所にある checkout でも、その checkout と実行中の checkout に同じ Git remote が設定されていれば移行対象です。remote のない別コピーは自動移行せず、管理外のリンクとして扱います。

適用先に自分で作った同名ファイルや別リポジトリのリンクがある場合は自動では上書きしません。必要な内容を退避して競合を解消してから、コマンドを再実行してください。リポジトリ内の設定を編集するときは、今後は `home/` 以下を編集します。

`~/.config/git/local` はマシン固有の Git 設定用です。このファイルは Git 管理せず、インストーラーも変更しません。

## テスト

実際のホームディレクトリには触れず、一時ディレクトリでインストールを検証できます。

```bash
./tests/install.test.sh
```
