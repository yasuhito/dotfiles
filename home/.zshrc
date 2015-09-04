export LANG=ja_JP.UTF-8

## Customize to your needs...
export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/X11/bin:/usr/local/texlive/2012/bin/x86_64-darwin:~/bin:$PATH
export EDITOR=emacsclient

## Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"

# Antigen
source $HOME/.zshrc.antigen

# Added by travis gem
[ -f /Users/yasuhito/.travis/travis.sh ] && source /Users/yasuhito/.travis/travis.sh

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
