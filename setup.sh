#!/bin/bash

DOT_FILES=( .zshrc .zshrc.antigen )

for file in ${DOT_FILES[@]}
do
    ln -s $HOME/dotfiles/$file $HOME/$file
done


EMACS_FILES=( init.el yasuhito.el )

for file in ${EMACS_FILES[@]}
do
    ln -s $HOME/dotfiles/$file $HOME/.emacs.d/$file
done


