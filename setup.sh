#!/bin/bash

DOT_FILES=( .zshrc .zshrc.antigen .tmux.conf .tmux.remote.conf .aspell.conf )
for file in ${DOT_FILES[@]}
do
    ln -s $HOME/dotfiles/$file $HOME/$file
done


EMACS_FILES=( init.el keybind.el mew.el org.el skk.el )
for file in ${EMACS_FILES[@]}
do
    ln -s $HOME/dotfiles/$file $HOME/.emacs.d/personal/$file
done
