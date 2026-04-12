# xydacshell

An opinionated terminal setup. Two profiles, one install script, safe to re-run.

- **classic** — oh-my-zsh with the `materialshell-electro` theme, amix/vimrc, and a handful of zsh plugins. The original xydacshell stack.
- **modern** — starship prompt, Neovim with a small `init.lua`, and graceful use of fzf / zoxide / eza / bat when they're installed.

Existing users: your setup still works. You stay on `classic` until you opt into `modern`.

## Install

```bash
git clone --recurse-submodules https://github.com/xydac/xydacshell.git ~/.xydacshell
cd ~/.xydacshell
bash install.sh                       # fresh: defaults to classic
bash install.sh --profile modern      # opt into modern
```

The installer is idempotent — running it twice is safe.

## Update

```bash
cd ~/.xydacshell
git pull --rebase
git submodule update --init --recursive
bash install.sh
```

## Switch profile

```bash
cd ~/.xydacshell
bash install.sh --profile modern
# or: bash install.sh --profile classic
```

Your `~/.xydacshell/zshrc.custom` and `vimrc.custom` are never touched.

## Customize

Add your personal settings here — they outlive any profile switch or upgrade.

- zsh: `~/.xydacshell/zshrc.custom`
- vim (classic): `~/.xydacshell/vimrc.custom`
- nvim (modern): `~/.xydacshell/nvim.custom.lua`

## Modern profile — optional tool install hints

The modern profile degrades gracefully when these are missing. To get the full experience:

```bash
# macOS
brew install starship neovim fzf zoxide eza bat

# Debian/Ubuntu
sudo apt install neovim fzf
# For starship, zoxide, eza, bat — see each project's release page or use a user-local install.
```

## Uninstall

```bash
# Restore the original pre-install configs if present.
[ -f ~/.xydacshell/backup/.zshrc ] && mv ~/.xydacshell/backup/.zshrc ~/.zshrc || rm -f ~/.zshrc
[ -f ~/.xydacshell/backup/.vimrc ] && mv ~/.xydacshell/backup/.vimrc ~/.vimrc || rm -f ~/.vimrc
rm -rf ~/.xydacshell
```

## What ships

```
xydacshell/
├── install.sh                           # idempotent, profile-aware, --dry-run, --force
├── lib/util.sh                          # shell helpers
├── zshrc.file, vimrc.file               # dispatchers (read the profile, load the right config)
├── profiles/
│   ├── classic/ { zshrc, vimrc }        # the original setup
│   └── modern/  { zshrc, starship.toml, nvim/init.lua }
├── materialshell-electro.zsh-theme      # classic prompt theme
├── backup/                              # timestamped backups per install run
└── .github/workflows/ci.yml             # shellcheck + zsh/nvim syntax checks
```

## Compatibility

- `zsh` required.
- `git` required.
- `classic` profile: submodules are used (oh-my-zsh, amix/vimrc, etc.).
- `modern` profile: Neovim recommended; starship, fzf, zoxide, eza, bat are optional and each has a fallback.

## License

MIT. Pull requests welcome.
