# Changelog

## Unreleased — upgrade-path branch

### Added
- **`xydacshell` command.** A PATH-installed dispatcher (`bin/xydacshell`) with subcommands: `install`, `update`, `switch`, `doctor`, `rollback`, `storage`, `uninstall`. Both profile zshrcs prepend `$XYDACSHELL_HOME/bin` to PATH so it "just works" after install.
- **`xydacshell doctor`.** One-command diagnostic: current profile, managed symlinks, sacred custom file sizes, detected OS + package manager, modern-tool presence, most recent backup, git state.
- **`xydacshell rollback`.** Restore files from a timestamped backup dir (most recent by default; `--stamp` to pick one). Prompts before writing; `--dry-run` previews.
- **`xydacshell storage`.** Disk-usage report: local filesystems (via `duf`/`df`), top `$HOME` directories (via `dust`/`du`), package-manager caches (brew, npm, pnpm, cargo, pip, uv), docker, trash. `--caches` to focus, `--top N` to expand, `--clean` to prompt per-cache cleanup.
- **`xydacshell uninstall`.** Removes our symlinks, restores legacy `backup/.zshrc` / `backup/.vimrc` pre-install files when present. Does not delete the repo itself.
- **More modern tools in the installer.** `ncdu`, `dust`, `duf` added alongside starship/nvim/fzf/zoxide/lsd/bat. `dust` uses `cargo install du-dust` as fallback on apt/apk.
- **`LICENSE` file.** Formalizes the MIT license already declared in the README.
- **Modern-profile tool installer.** The installer now detects the OS (macOS / Linux) and an available package manager (brew / apt / dnf / pacman / apk), lists missing tools (starship, nvim, fzf, zoxide, lsd, bat) with their install commands, and prompts per tool. Uses the native package manager where possible; falls back to official curl installers (starship, zoxide) or `cargo install` (lsd on apt) where the pm doesn't ship the package. `--force` auto-accepts; `--dry-run` previews. Missing tools degrade gracefully — the profile still works without them.
- **Profiles.** Two installable profiles:
  - `classic` — the original oh-my-zsh + materialshell-electro + amix/vimrc stack. Default for existing users.
  - `modern` — starship prompt, Neovim with a small `init.lua`, graceful use of fzf/zoxide/lsd/bat when present, no oh-my-zsh dependency.
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
