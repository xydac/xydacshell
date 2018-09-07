#!/bin/bash
if ! [ -x "$(command -v git)"   ]; then
    echo 'Error: git is not installed.' >&2
    exit 1
fi
if ! [ -x "$(command -v zsh)"   ]; then
    echo 'Error: zsh is not installed.' >&2
    exit 1
fi

if [ "$PWD" != "$HOME/.xydacshell"  ]; then
    echo " Error: Please run from $HOME/.xydacshell directory.";
    exit 1
fi

echo "Checking out awesome stuffs"
git submodule update --init --recursive

chmod -R go-w ./

echo "Creating Backups now ";
# Create Backups
if [ -f ~/.zshrc  ]; then
    mv ~/.zshrc ~/.xydacshell/backup/.zshrc
fi
if [ -f ~/.vimrc  ]; then
    mv ~/.vimrc ~/.xydacshell/backup/.vimrc
fi

# Copy config files
echo "Creating Symlinks now"
ln -s ~/.xydacshell/vimrc.file ~/.vimrc
ln -s ~/.xydacshell/zshrc.file ~/.zshrc

echo "All Done !!"
