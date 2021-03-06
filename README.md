
# Xydac Shell
Opinionated Awesome Shell with cherry picked awesomeness.

## Includes
* [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)
* [vim rc](https://github.com/amix/vimrc)
* [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
* [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
* [k](https://github.com/supercrabtree/k)

## Features
A lovely and Customized terminal System that declutters your shell customzations


## Screenshots
Prompt Preview
![Prompt Theme](https://raw.githubusercontent.com/xydac/xydacshell/master/screenshots/screenshot-prompt.png)
VIM Preview
![VI](https://raw.githubusercontent.com/xydac/xydacshell/master/screenshots/screenshot-vi.png)

## Installation, Updates, Uninstallation
### Installation :
``` 
git clone https://github.com/xydac/xydacshell.git  ~/.xydacshell && cd ~/.xydacshell && bash install.sh
```
### Update:
```
cd ~/.xydacshell && git pull --rebase
```
### Uninstall
Restores Backup 
```
rm ~/.zshrc ~/.vimrc && mv ~/.xydacshell/backup/.zshrc ~/.zshrc && ~/.xydacshell/backup/.vimrc ~/.vimrc
```
## Tweaks
* Alias : ```c``` --> Clears Screen
* Alias : ```gitlog``` --> One Liner Git Logs

### VI Tweaks
* Leader Key : ``` ` ```
* Shortcut : ``` ` + <Arrow Keys>``` --> Move Panes
* Shortcut : ``` ` + <TAB>``` --> Recent Files


## Further Customization
* Vim Customization : update your custom tweaks in ```~/.xydacshell/vimrc.custom```
* ZSH Customization : update your custom tweaks in ```~/.xydacshell/zshrc.custom```

## Minimum Requirement
* zsh
* git

## License
MIT

- Pull Request Welcome
