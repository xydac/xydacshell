#!/usr/bin/env bash
# xs_heal — bring the xydacshell checkout into a clean, installable state.
# Sourced by install.sh (preflight) and lib/cmds/update.sh (pre-pull).
#
# What it heals:
#   1. Submodule untracked content (plugin caches, .zcompdump, compiled .zwc).
#   2. User edits to tracked dispatcher files (zshrc.file, vimrc.file):
#      additions migrate to the sacred zshrc.custom / vimrc.custom,
#      then the tracked file is reset.
#
# What it doesn't:
#   - Deletions and in-place modifications are not migrated (can't be done
#     safely). If those remain, we refuse to proceed.
#
# Returns 0 on clean state (healed or already clean), 1 on unresolvable dirt.

_xs_heal_migrate_additions() {
  local xh="$XYDACSHELL_HOME" tracked="$1" custom="$2"
  local additions
  additions="$(git -C "$xh" diff -- "$tracked" | awk '/^\+[^+]/ {sub(/^\+/,""); print}')"

  if [ -z "$additions" ]; then
    xs_dim "  $tracked has only deletions/context changes; leaving as-is"
    return 0
  fi

  printf '\n'
  xs_warn "you've added content to $tracked (a tracked file, not meant for edits):"
  printf '%s\n' "$additions" | sed 's/^/    /' >&2

  if ! xs_prompt_yn "  migrate these additions to $custom and reset $tracked?" y; then
    return 1
  fi

  if [ "${XS_DRY_RUN:-0}" = 1 ]; then
    xs_dim "  (dry run) would append to $custom and reset $tracked"
    return 0
  fi

  {
    printf '\n# ---- migrated from %s on %s ----\n' "$(basename "$tracked")" "$(date -u +%Y-%m-%d)"
    printf '%s\n' "$additions"
  } >> "$xh/$custom"
  xs_run git -C "$xh" checkout -- "$tracked"
  xs_ok "  migrated → $custom"
}

xs_heal() {
  local xh="$XYDACSHELL_HOME"
  [ -d "$xh/.git" ] || return 0

  # 1. Submodule untracked content.
  local sm_dirty
  sm_dirty="$(git -C "$xh" submodule foreach --quiet 'git status --porcelain 2>/dev/null' 2>/dev/null | wc -l | tr -d ' ')"
  if [ "${sm_dirty:-0}" -gt 0 ] 2>/dev/null; then
    xs_warn "submodules have untracked content (plugin caches etc.)"
    if xs_prompt_yn "  clean it?" y; then
      xs_run git -C "$xh" submodule foreach --quiet 'git clean -fd .' 2>/dev/null || true
      xs_ok "  submodules cleaned"
    fi
  fi

  # 2. Migrate edits to tracked dispatcher files.
  for f in zshrc.file vimrc.file; do
    if ! git -C "$xh" diff --quiet -- "$f" 2>/dev/null; then
      case "$f" in
        zshrc.file) _xs_heal_migrate_additions "$f" zshrc.custom || return 1 ;;
        vimrc.file) _xs_heal_migrate_additions "$f" vimrc.custom || return 1 ;;
      esac
    fi
  done

  # 3. Anything tracked still dirty is an unresolvable conflict.
  local dirty
  dirty="$(git -C "$xh" status --porcelain -- ':!zshrc.custom' ':!vimrc.custom' ':!backup' ':!profile' 2>/dev/null || true)"
  if [ -n "$dirty" ]; then
    xs_err "repo has uncommitted changes we couldn't heal:"
    printf '%s\n' "$dirty" >&2
    xs_err "resolve them, then re-run."
    return 1
  fi
  return 0
}
