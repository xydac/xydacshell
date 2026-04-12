# Changelog

## Unreleased — upgrade-path branch

### Added
- **Profiles.** Two installable profiles:
  - `classic` — the original oh-my-zsh + materialshell-electro + amix/vimrc stack. Default for existing users.
  - `modern` — starship prompt, Neovim with a small `init.lua`, graceful use of fzf/zoxide/eza/bat when present, no oh-my-zsh dependency.
- **Profile dispatcher** in `zshrc.file` and `vimrc.file` — reads `~/.xydacshell/profile` and loads the active profile. Missing file → defaults to `classic`. Your `~/.zshrc` symlink keeps working; no action required for existing users.
- **Idempotent installer.** Re-running `install.sh` is safe. Creates a new `backup/<timestamp>/` directory per run; never touches existing backups.
- **Profile-switch flow.** `install.sh --profile modern` flips profile with confirmation.
- **Dry-run mode.** `install.sh --dry-run` prints everything it would do.
- **Safety preflight.** Installer refuses to run if there are uncommitted local edits to tracked files. Sacred files (`zshrc.custom`, `vimrc.custom`) are hash-verified before and after.
- **CI.** `shellcheck` on all shell scripts; `zsh -n` syntax-check on all zshrc files; `nvim --headless` load-check on the modern `init.lua`.

### Fixed
- **Broken git-status escape sequences** in `materialshell-electro.zsh-theme` (lines 68–73). Previously missing `%` before `%{$reset_color%}` would leak raw escape characters into the prompt. Classic users running a dirty repo would see garbled output.

### Preserved (intentionally unchanged)
- Existing users' `~/.xydacshell/backup/.zshrc` and `backup/.vimrc` (their pre-install configs) remain untouched.
- `zshrc.custom` and `vimrc.custom` are never rewritten by the installer.
- Every submodule. Classic still needs them.
- The `~/.zshrc` / `~/.vimrc` symlink targets stay the same paths (`zshrc.file` / `vimrc.file`) — existing symlinks continue to work without modification.

### Planned for a future major
- Retire the `classic` profile; drop `oh-my-zsh`, `amix/vimrc`, and `k` submodules.
- Make the modern profile fully submodule-free (source zsh plugins from `brew`/`apt`).
- Publish as a Homebrew tap for brew-managed upgrades.
