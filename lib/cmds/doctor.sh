#!/usr/bin/env bash
# x doctor — report current install state, and offer profile upgrades
# when appropriate (classic + clean repo + interactive tty).

xs_cmd_doctor() {
  local xh="$XYDACSHELL_HOME"
  local flag_no_prompt=0 flag_report=0

  while [ $# -gt 0 ]; do
    case "$1" in
      --no-prompt|--report) flag_no_prompt=1; flag_report=1; shift ;;
      --dry-run)            XS_DRY_RUN=1; export XS_DRY_RUN; shift ;;
      --force)              FORCE=1; export FORCE; shift ;;
      -h|--help)
        cat <<'EOF'
usage: x doctor [--no-prompt|--report]

Reports the current install state (profile, symlinks, custom files, PM,
tool presence, backups, git state).

When on the classic profile with a clean repo and an interactive terminal,
doctor offers to preview and switch to the modern profile. Pass --no-prompt
(alias: --report) to skip that and just print the diagnostic.
EOF
        return 0
        ;;
      *) xs_err "unknown flag: $1"; return 2 ;;
    esac
  done

  printf '\n%s\n' "x doctor"
  printf '=========\n'

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
      printf '  %-44s (regular file, not managed by x)\n' "$f"
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

  # Optional: offer a profile upgrade if conditions are right.
  if [ "$flag_no_prompt" != 1 ]; then
    _xs_doctor_maybe_offer_upgrade "$profile"
  fi
}

# If the user is on classic, the repo is clean, and stdin is a tty, offer
# to preview and switch to modern. Otherwise return silently.
_xs_doctor_maybe_offer_upgrade() {
  local current="$1"
  local xh="$XYDACSHELL_HOME"

  [ "$current" = classic ] || return 0
  [ -t 0 ] || return 0

  if [ -d "$xh/.git" ]; then
    local dirty
    dirty="$(git -C "$xh" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
    if [ "$dirty" != 0 ]; then
      xs_dim "you're on classic, with uncommitted changes in the repo."
      xs_dim "  run 'x update --profile modern' to heal and switch in one step,"
      xs_dim "  or 'x update' to just heal and stay on classic."
      return 0
    fi
  fi

  xs_info "you're on the classic profile."
  xs_dim "  modern swaps in starship + nvim + fzf/zoxide/lsd/bat."
  xs_dim "  your zshrc.custom and vimrc.custom stay untouched."
  xs_dim "  revertible any time with 'x update --profile classic'."

  if ! xs_prompt_yn "preview a switch to modern?" "n"; then
    xs_dim "staying on classic."
    return 0
  fi

  printf '\n'
  xs_info "preview (dry run):"
  (cd "$xh" && XS_DRY_RUN=1 bash "$xh/install.sh" --dry-run --profile modern) || return 0

  printf '\n'
  if xs_prompt_yn "switch to modern now?" "n"; then
    printf '\n'
    (cd "$xh" && bash "$xh/install.sh" --profile modern --force)
  else
    xs_dim "staying on classic."
  fi
}
