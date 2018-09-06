#!/bin/bash
if [ "$PWD" != "$HOME/.xydacshell"  ]; then
    echo " ERROR - Please run from $HOME/.xydacshell directory.";
else
    echo "Checking out awesome stuffs"
    git submodule update --init --recursive

    chmod -R go-w /.

    echo "Creating Backups now !!";
    # Create Backups
    mv ~/.zshrc ~/.xydacshell/backup/.zshrc
    mv ~/.vimrc ~/.xydacshell/backup/.vimrc

    # Copy config files
    echo "Creating Symlinks now"
    ln -s ~/.xydacshell/vimrc.file ~/.vimrc
    ln -s ~/.xydacshell/zshrc.file ~/.zshrc

    echo "All Done !!"
fi
