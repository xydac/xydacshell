#!/usr/bin/env bash
# xydacshell rollback — restore files from a timestamped backup.

xs_cmd_rollback() {
  local xh="$XYDACSHELL_HOME"
  local stamp=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --stamp)    stamp="${2:-}"; shift 2 ;;
      --stamp=*)  stamp="${1#--stamp=}"; shift ;;
      --dry-run)  XS_DRY_RUN=1; export XS_DRY_RUN; shift ;;
      --force)    FORCE=1; export FORCE; shift ;;
      -h|--help)
        cat <<'EOF'
usage: xydacshell rollback [--stamp YYYYMMDDTHHMMSSZ] [--dry-run] [--force]

Restore files from a timestamped backup created by install.sh. If no
--stamp is given, the most recent backup is used. Prompts before writing.
EOF
        return 0
        ;;
      *) xs_err "unknown flag: $1"; return 2 ;;
    esac
  done

  if [ -z "$stamp" ]; then
    stamp="$(find "$xh/backup" -maxdepth 1 -type d -name '[0-9]*T[0-9]*Z' 2>/dev/null | sort | tail -1 | xargs -n1 basename 2>/dev/null || true)"
  fi

  if [ -z "$stamp" ]; then
    xs_err "no timestamped backups found in $xh/backup/"
    return 1
  fi

  local dir="$xh/backup/$stamp"
  if [ ! -d "$dir" ]; then
    xs_err "backup dir not found: $dir"
    return 1
  fi

  xs_info "rolling back from: $dir"
  xs_dim "contents:"
  ls -la "$dir" 2>/dev/null | sed 's/^/  /' >&2

  if ! xs_prompt_yn "restore these files to their original locations?" "n"; then
    xs_dim "aborted."
    return 0
  fi

  local f name target
  for f in "$dir"/*; do
    [ -e "$f" ] || continue
    name="$(basename "$f")"
    case "$name" in
      .zshrc)         target="$HOME/.zshrc" ;;
      .vimrc)         target="$HOME/.vimrc" ;;
      init.lua)       target="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.lua" ;;
      starship.toml)  target="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml" ;;
      *) xs_warn "  don't know where to restore '$name', skipping"; continue ;;
    esac
    if [ -e "$target" ] || [ -L "$target" ]; then
      xs_run rm -f "$target"
    fi
    xs_run cp -a "$f" "$target"
    xs_ok "restored $target"
  done
}
