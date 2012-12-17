#!/bin/bash

DOT_FILES=( .zshrc .zshrc.antigen )

for file in ${DOT_FILES[@]}
do
    ln -s $HOME/dotfiles/$file $HOME/$file
done