#!/bin/bash
if [ "$PWD" != "$HOME/.xydacshell"  ]; then
    echo " ERROR - Please run from $HOME/.xydacshell directory.";
else
    echo "Checking out awesome stuffs"
    git submodule update --init --recursive
    
    echo "Creating Backups now !!";
    # Create Backups
    cp ~/.zshrc ~/.xydacshell/backup/.zshrc
    cp ~/.vimrc ~/.xydacshell/backup/.vimrc

    # Copy config files
    echo "Creating Symlinks now"
    ln -s ~/.xydacshell/vimrc.file ~/.vimrc
    ln -s ~/.xydacshell/zshrc.file ~/.zshrc

    echo "All Done !!"
fi
