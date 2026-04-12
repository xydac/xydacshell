#!/usr/bin/env bash
# xydacshell doctor — report current install state.

xs_cmd_doctor() {
  local xh="$XYDACSHELL_HOME"

  printf '\n%s\n' "xydacshell doctor"
  printf '==================\n'

  # Paths.
  printf '\npaths\n'
  printf '  XYDACSHELL_HOME  %s\n' "$xh"
  printf '  dispatcher       %s\n' "$xh/bin/xydacshell"

  # Profile.
  local profile
  if [ -f "$xh/profile" ]; then
    profile="$(cat "$xh/profile")"
  else
    profile="(unset — dispatcher defaults to classic)"
  fi
  printf '\nprofile          %s\n' "$profile"

  # Symlinks.
  printf '\nsymlinks\n'
  local f
  for f in "$HOME/.zshrc" "$HOME/.vimrc" \
           "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.lua" \
           "${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"; do
    if [ -L "$f" ]; then
      printf '  %-44s → %s\n' "$f" "$(readlink "$f")"
    elif [ -e "$f" ]; then
      printf '  %-44s (regular file, not managed by xydacshell)\n' "$f"
    fi
  done

  # Sacred custom files.
  printf '\ncustom files (never touched by installer)\n'
  local c size="-"
  for c in "$xh/zshrc.custom" "$xh/vimrc.custom" "$xh/nvim.custom.lua"; do
    if [ -f "$c" ]; then
      size="$(wc -c < "$c" | tr -d ' ')"
      printf '  %-44s %s bytes\n' "$c" "$size"
    else
      printf '  %-44s (absent)\n' "$c"
    fi
  done

  # Environment + tool status.
  # shellcheck source=../modern-tools.sh
  . "$xh/lib/modern-tools.sh"
  xs_detect_pm
  printf '\nenvironment\n'
  printf '  OS               %s\n' "$XS_OS"
  printf '  package manager  %s\n' "$XS_PM"

  printf '\ntools\n'
  local t
  for t in starship nvim fzf zoxide lsd bat ncdu dust duf; do
    if xs_command_exists "$t"; then
      printf '  %-10s ✓\n' "$t"
    else
      printf '  %-10s missing\n' "$t"
    fi
  done

  # Backups.
  printf '\nbackups\n'
  if [ -d "$xh/backup" ]; then
    local latest
    latest="$(find "$xh/backup" -maxdepth 1 -type d -name '[0-9]*T[0-9]*Z' 2>/dev/null | sort | tail -1)"
    if [ -n "$latest" ]; then
      printf '  latest timestamped  %s\n' "$(basename "$latest")"
    else
      printf '  latest timestamped  (none)\n'
    fi
    local legacy=0
    [ -f "$xh/backup/.zshrc" ] && legacy=$((legacy + 1))
    [ -f "$xh/backup/.vimrc" ] && legacy=$((legacy + 1))
    printf '  legacy pre-install  %d file(s)\n' "$legacy"
  else
    printf '  (no backup directory)\n'
  fi

  # Git state.
  if [ -d "$xh/.git" ]; then
    printf '\ngit\n'
    printf '  branch           %s\n' "$(git -C "$xh" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
    printf '  head             %s\n' "$(git -C "$xh" rev-parse --short HEAD 2>/dev/null || echo '?')"
    local dirty
    dirty="$(git -C "$xh" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
    printf '  uncommitted      %s file(s)\n' "$dirty"
  fi

  printf '\n'
}
