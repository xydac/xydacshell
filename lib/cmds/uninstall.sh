#!/usr/bin/env bash
# xydacshell uninstall — remove our symlinks and restore legacy backups.
# Never touches the xydacshell repo itself; user deletes manually.

xs_cmd_uninstall() {
  local xh="$XYDACSHELL_HOME"

  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run)  XS_DRY_RUN=1; export XS_DRY_RUN; shift ;;
      --force)    FORCE=1; export FORCE; shift ;;
      -h|--help)
        cat <<'EOF'
usage: xydacshell uninstall [--dry-run] [--force]

Remove xydacshell symlinks and restore the original pre-install files
if they're in backup/.zshrc / backup/.vimrc. Does NOT delete the
xydacshell repo itself.
EOF
        return 0
        ;;
      *) xs_err "unknown flag: $1"; return 2 ;;
    esac
  done

  xs_warn "about to uninstall xydacshell"
  xs_dim "  will remove our symlinks at ~/.zshrc, ~/.vimrc, and the"
  xs_dim "  modern-profile starship/nvim configs if they point into $xh."
  xs_dim "  will restore $xh/backup/.zshrc and /.vimrc (pre-install originals)"
  xs_dim "  if they exist."
  xs_dim "  will NOT delete $xh itself — rm -rf it manually when ready."

  if ! xs_prompt_yn "proceed?" "n"; then
    xs_dim "aborted."
    return 0
  fi

  _restore_or_remove() {
    local link="$1" legacy="$2"
    if [ -L "$link" ] && [[ "$(readlink "$link")" == "$xh"/* ]]; then
      xs_run rm -f "$link"
      if [ -f "$legacy" ]; then
        xs_run mv "$legacy" "$link"
        xs_ok "restored $link from $legacy"
      else
        xs_ok "removed $link"
      fi
    fi
  }

  _restore_or_remove "$HOME/.zshrc" "$xh/backup/.zshrc"
  _restore_or_remove "$HOME/.vimrc" "$xh/backup/.vimrc"

  local nvim="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.lua"
  if [ -L "$nvim" ] && [[ "$(readlink "$nvim")" == "$xh"/* ]]; then
    xs_run rm -f "$nvim"
    xs_ok "removed $nvim"
  fi

  local starship="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
  if [ -L "$starship" ] && [[ "$(readlink "$starship")" == "$xh"/* ]]; then
    xs_run rm -f "$starship"
    xs_ok "removed $starship"
  fi

  printf '\n'
  xs_info "done. to complete removal: rm -rf $xh"
}
