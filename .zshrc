source $HOME/.zshrc.antigen


## Customize to your needs...
export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/X11/bin:/usr/local/texlive/2012/bin/x86_64-darwin:~/bin:$PATH


## set alias
if [ "$SSH_TTY" = "" ]; then
    alias emacs=/Applications/Emacs.app/Contents/MacOS/Emacs
fi


## tmux自動起動
# http://d.hatena.ne.jp/tyru/20100828/run_tmux_or_screen_at_shell_startup
is_tmux_running() {
    [ ! -z "$TMUX" ]
}

shell_has_started_interactively() {
    [ ! -z "$PS1" ]
}

resolve_alias() {
    cmd="$1"
    while \
        whence "$cmd" >/dev/null 2>/dev/null \
        && [ "$(whence "$cmd")" != "$cmd" ]
    do
        cmd=$(whence "$cmd")
    done
    echo "$cmd"
}

if ! is_tmux_running && shell_has_started_interactively; then
    if whence tmux >/dev/null 2>/dev/null; then
        real_tmux=$(resolve_alias "tmux")
        $real_tmux attach || $real_tmux -f $HOME/.tmux.remote.conf
        break
    fi
fi


## change the color of tmux's status line
if ! [ "$TMUX" = "" ]; then
    tmux set-option status-bg $(perl -MList::Util=sum -e'print+(red,green,blue,yellow,cyan,magenta,white)[sum(unpack"C*",shift)%7]' $(hostname)) | cat > /dev/null
fi


## rvm
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"


## Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"
