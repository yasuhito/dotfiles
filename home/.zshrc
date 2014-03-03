export LANG=ja_JP.UTF-8

## Customize to your needs...
export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/X11/bin:/usr/local/texlive/2012/bin/x86_64-darwin:~/bin:$PATH
export EDITOR=emacsclient

## Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"

## RVM
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

source $HOME/.zshrc.antigen
