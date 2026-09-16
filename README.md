# dotfiles

個人用の設定ファイルです。`home/` 以下は `$HOME` に配置する内容と同じ構成になっています。

## 収録している設定

- Git、gh-dash、mise
- Omarchy のデフォルトを読み込む Hyprland Lua 設定と個人用 override 一式
- Ghostty と WezTerm、および Omarchy のデフォルトターミナルを Ghostty にする設定
- エージェント向けの共通指示

Hyprland 設定には、フォーカス中のウィンドウを示す赤い枠線と、非アクティブなウィンドウを暗くする設定が含まれます。Omarchy が提供する Lua モジュールを前提とし、モニター固有の EDID やバックアップ、生成された設定は収録していません。

## セットアップ

新しく clone したリポジトリで、適用先のホームディレクトリを明示して次の 1 コマンドを実行します。

```bash
./install.sh "$HOME"
```

`install.sh` は `home/` 内の Git 管理対象ファイルへのシンボリックリンクを作ります。Ghostty、Hyprland、WezTerm の設定もそれぞれ `~/.config/ghostty/`、`~/.config/hypr/`、`~/.config/wezterm/` に配置されます。同じコマンドは何度実行しても安全です。同じ Git リポジトリの別 checkout を指す既存リンクは、現在の checkout を指すように更新します。適用先に管理外のファイルや別リポジトリのリンクがある場合は、どの設定も変更せずエラーにします。別のホームディレクトリで試す場合も、たとえば `./install.sh "/tmp/test home"` のように適用先を引数で指定してください。

## Ghostty

`~/.config/ghostty/config` ではフォント、ウィンドウ、カーソル、キーバインド、スクロール、Hyprland 向けバックエンドを管理します。Omarchy の動的テーマは、存在する場合だけ `~/.local/state/omarchy/current/theme/ghostty.conf` から読み込みます。

元のローカル設定が参照していた `shaders/cursor_warp.glsl` と `shaders/ripple_cursor.glsl` は別リポジトリ由来で、この dotfiles の管理対象ではなかったため、公開環境で欠落ファイルを参照しないよう `custom-shader` の 2 行を除外しました。また、後続の `shift+enter=text:\n` に上書きされて効いていなかった Shift+Enter の CSI-u keybind とそのコメントも削除しました。どちらも実際の動作は変えていません。

既存の管理外 `~/.config/ghostty/config` は自動で上書きしません。実環境を移行するときは、先に既存ファイルをバックアップしてから競合を解消し、`./install.sh "$HOME"` を改めて実行してください。

## Omarchy のデフォルトターミナル

この設定には Ghostty と `xdg-terminal-exec` が必要です。Omarchy 4.x が `$TERMINAL=xdg-terminal-exec` として起動するターミナルは、`~/.config/xdg-terminals.list` に指定した、インストール済み Ghostty の desktop entry `com.mitchellh.ghostty.desktop` を選択します。

WezTerm の設定、user desktop entry、`xdg-terminal-exec` 用 wrapper も引き続き配置します。WezTerm は削除されず、明示的に起動できる非デフォルトのターミナルとして残ります。Hyprland の既存動作も変更しません。

Ghostty や Omarchy の更新後は、desktop ID の前提が変わっていないか次のコマンドで確認してください。確認だけなら Hyprland や Waybar の reload は不要です。

```bash
xdg-terminal-exec --print-id
```

`com.mitchellh.ghostty.desktop` と表示されるのが期待値です。

## 以前のレイアウトからの移行

以前のセットアップ手順で作った、リポジトリ直下の設定を指すリンクは `./install.sh "$HOME"` が新しい `home/` 内のリンクへ安全に更新します。リンク元が現在とは別の場所にある checkout でも、その checkout と実行中の checkout に同じ Git remote が設定されていれば移行対象です。remote のない別コピーは自動移行せず、管理外のリンクとして扱います。

適用先に自分で作った同名ファイルや別リポジトリのリンクがある場合は自動では上書きしません。必要な内容を退避して競合を解消してから、コマンドを再実行してください。リポジトリ内の設定を編集するときは、今後は `home/` 以下を編集します。

`~/.config/git/local` はマシン固有の Git 設定用です。このファイルは Git 管理せず、インストーラーも変更しません。

## テスト

実際のホームディレクトリには触れず、一時ディレクトリでインストールを検証できます。

```bash
./tests/install.test.sh
```
