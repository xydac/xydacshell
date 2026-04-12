#!/usr/bin/env bash
# xydacshell installer.
# Idempotent, profile-aware, non-destructive. Safe to re-run.
#
# Usage:
#   bash install.sh                       interactive
#   bash install.sh --profile classic     pin to the classic profile
#   bash install.sh --profile modern      switch to the modern profile
#   bash install.sh --dry-run             preview without touching the filesystem
#   bash install.sh --force               skip all confirmations (profile switch + tool installs)
#   bash install.sh --help                print this help
#
# Safety guarantees (for existing users):
#   * Never touches $XYDACSHELL_HOME/zshrc.custom or vimrc.custom if they exist.
#   * Never touches the legacy single-file backups (backup/.zshrc, backup/.vimrc).
#   * New backups go to backup/<timestamp>/ — never collide with anything older.
#   * Refuses to run if the xydacshell repo has uncommitted local edits.
#   * Switching profiles requires explicit confirmation (or --force).

set -euo pipefail

XYDACSHELL_HOME="${XYDACSHELL_HOME:-$HOME/.xydacshell}"
export XYDACSHELL_HOME

# shellcheck source=lib/util.sh
. "$XYDACSHELL_HOME/lib/util.sh"
# shellcheck source=lib/modern-tools.sh
. "$XYDACSHELL_HOME/lib/modern-tools.sh"

XS_DRY_RUN=0
REQUESTED_PROFILE=""
FORCE=0

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --profile)       REQUESTED_PROFILE="${2:-}"; shift 2 ;;
    --profile=*)     REQUESTED_PROFILE="${1#--profile=}"; shift ;;
    --dry-run)       XS_DRY_RUN=1; export XS_DRY_RUN; shift ;;
    --force)         FORCE=1; shift ;;
    -h|--help)       usage; exit 0 ;;
    *) xs_err "unknown flag: $1"; usage; exit 2 ;;
  esac
done

# Preflight checks.
for bin in git zsh; do
  if ! xs_command_exists "$bin"; then
    xs_err "required command missing: $bin"
    exit 1
  fi
done

if [ "$PWD" != "$XYDACSHELL_HOME" ]; then
  xs_err "please run from $XYDACSHELL_HOME (current: $PWD)"
  exit 1
fi

# Refuse to run if the user has made uncommitted changes to tracked files.
# (Unstaged changes to tracked files = potentially custom edits to zshrc.file/vimrc.file
# that git pull would clobber.)
if [ -d "$XYDACSHELL_HOME/.git" ]; then
  dirty="$(git -C "$XYDACSHELL_HOME" status --porcelain -- ':!zshrc.custom' ':!vimrc.custom' ':!backup' ':!profile' 2>/dev/null || true)"
  if [ -n "$dirty" ]; then
    xs_err "xydacshell repo has uncommitted local changes:"
    printf '%s\n' "$dirty" >&2
    xs_err "commit, stash, or discard them before re-running install.sh"
    exit 1
  fi
fi

# Detect existing install.
is_existing_install() {
  [ -f "$XYDACSHELL_HOME/profile" ] || \
  { [ -L "$HOME/.zshrc" ] && [[ "$(readlink "$HOME/.zshrc")" == "$XYDACSHELL_HOME"/* ]]; } || \
  [ -f "$XYDACSHELL_HOME/backup/.zshrc" ]
}

current_profile=""
if is_existing_install; then
  current_profile="$(xs_profile_read "$XYDACSHELL_HOME")"
  xs_info "detected existing install; current profile: $current_profile"
fi

# Choose target profile.
if [ -z "$REQUESTED_PROFILE" ]; then
  if [ -n "$current_profile" ]; then
    target_profile="$current_profile"
  else
    target_profile="classic"
    xs_info "fresh install; defaulting to profile: classic"
    xs_dim "  pass --profile modern to try the modern stack (starship + nvim)"
  fi
else
  case "$REQUESTED_PROFILE" in
    classic|modern) target_profile="$REQUESTED_PROFILE" ;;
    *) xs_err "unknown profile: $REQUESTED_PROFILE (expected classic|modern)"; exit 2 ;;
  esac
fi

# Profile-switch confirmation.
if [ -n "$current_profile" ] && [ "$current_profile" != "$target_profile" ]; then
  xs_warn "switching profile: $current_profile → $target_profile"
  xs_dim "  your zshrc.custom and vimrc.custom will be preserved."
  xs_dim "  your previous symlinks will be backed up to backup/<timestamp>/."
  if [ "$FORCE" != "1" ] && [ "$XS_DRY_RUN" != "1" ]; then
    printf 'proceed? [y/N] '
    read -r ans
    case "${ans:-n}" in
      y|Y|yes) ;;
      *) xs_err "aborted."; exit 1 ;;
    esac
  fi
fi

xs_info "installing profile: $target_profile"
[ "$XS_DRY_RUN" = "1" ] && xs_warn "DRY RUN — no filesystem changes will be made"

# Update submodules (classic depends on them; modern ignores them).
if [ "$target_profile" = "classic" ]; then
  xs_info "syncing classic-profile submodules"
  xs_run git -C "$XYDACSHELL_HOME" submodule update --init --recursive
fi

# Sanity snapshot of sacred files (custom overrides). We verify post-run.
snapshot_hash() {
  local f="$1"
  if [ -f "$f" ]; then
    if command -v shasum >/dev/null 2>&1; then
      shasum "$f" | awk '{print $1}'
    elif command -v sha1sum >/dev/null 2>&1; then
      sha1sum "$f" | awk '{print $1}'
    fi
  else
    printf 'absent'
  fi
}
pre_zshrc_custom="$(snapshot_hash "$XYDACSHELL_HOME/zshrc.custom")"
pre_vimrc_custom="$(snapshot_hash "$XYDACSHELL_HOME/vimrc.custom")"

# Timestamped backup dir for this run. Created lazily by xs_backup_file.
stamp="$(xs_timestamp)"
backup_dir="$XYDACSHELL_HOME/backup/$stamp"

# ~/.zshrc always points to our dispatcher.
xs_symlink "$XYDACSHELL_HOME/zshrc.file" "$HOME/.zshrc" "$backup_dir"

case "$target_profile" in
  classic)
    xs_symlink "$XYDACSHELL_HOME/vimrc.file" "$HOME/.vimrc" "$backup_dir"
    ;;
  modern)
    nvim_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
    xs_run mkdir -p "$nvim_config_dir"
    xs_symlink "$XYDACSHELL_HOME/profiles/modern/nvim/init.lua" "$nvim_config_dir/init.lua" "$backup_dir"

    starship_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
    xs_run mkdir -p "$starship_config_dir"
    xs_symlink "$XYDACSHELL_HOME/profiles/modern/starship.toml" "$starship_config_dir/starship.toml" "$backup_dir"

    # Detect missing modern tools and offer to install them.
    # User is prompted per tool; --force accepts all; --dry-run previews without running.
    FORCE="$FORCE" xs_modern_tools_offer starship nvim fzf zoxide lsd bat ncdu dust duf
    ;;
esac

# Custom override files — create empty ONLY if absent. Never touched otherwise.
for custom in zshrc.custom vimrc.custom; do
  target="$XYDACSHELL_HOME/$custom"
  if [ ! -e "$target" ]; then
    if [ "$XS_DRY_RUN" = "1" ]; then
      xs_dim "  would create empty $target"
    else
      : > "$target"
      xs_ok "created empty $target"
    fi
  else
    xs_dim "  preserving existing $target (not touched)"
  fi
done

# Write the profile file last.
xs_profile_write "$XYDACSHELL_HOME" "$target_profile"

# Warn if another `x` is on PATH that isn't ours — it may shadow xydacshell's
# command in scripts or non-interactive shells. Aliases in zsh override PATH
# for interactive shells, so also prompt the user to check.
existing_x="$(type -ap x 2>/dev/null | grep -v "^${XYDACSHELL_HOME}/bin/x\$" || true)"
if [ -n "$existing_x" ]; then
  xs_warn "another 'x' command is on your PATH:"
  printf '%s\n' "$existing_x" | sed 's/^/    /' >&2
  xs_dim "  after this install, xydacshell's 'x' will take precedence in new"
  xs_dim "  shells because \$XYDACSHELL_HOME/bin is prepended to PATH."
  xs_dim "  also check for shell aliases that would shadow it:"
  xs_dim "    alias | grep '^x='"
  xs_dim "  if you want to keep your existing 'x', use 'xydacshell' instead"
  xs_dim "  (it's a symlink to the same command)."
fi

# Verify sacred files are unchanged.
if [ "$XS_DRY_RUN" != "1" ]; then
  post_zshrc_custom="$(snapshot_hash "$XYDACSHELL_HOME/zshrc.custom")"
  post_vimrc_custom="$(snapshot_hash "$XYDACSHELL_HOME/vimrc.custom")"

  if [ "$pre_zshrc_custom" != "absent" ] && [ "$pre_zshrc_custom" != "$post_zshrc_custom" ]; then
    xs_err "internal error: zshrc.custom content changed during install. check backup/$stamp/"
    exit 1
  fi
  if [ "$pre_vimrc_custom" != "absent" ] && [ "$pre_vimrc_custom" != "$post_vimrc_custom" ]; then
    xs_err "internal error: vimrc.custom content changed during install. check backup/$stamp/"
    exit 1
  fi
fi

if [ -d "$backup_dir" ]; then
  xs_info "new backup files for this run: $backup_dir"
fi
if [ -f "$XYDACSHELL_HOME/backup/.zshrc" ] || [ -f "$XYDACSHELL_HOME/backup/.vimrc" ]; then
  xs_dim "legacy pre-install backups are preserved at $XYDACSHELL_HOME/backup/.zshrc / .vimrc"
fi

xs_ok "done. start a new shell: exec zsh"
