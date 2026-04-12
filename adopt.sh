#!/usr/bin/env bash
# adopt.sh — migrate edits from tracked dispatcher files into sacred custom files.
#
# Users sometimes edit zshrc.file or vimrc.file directly (despite the "do not edit"
# header). This script moves their additions into zshrc.custom / vimrc.custom,
# which are never overwritten by installs, profile switches, or updates — and
# then resets the tracked files so 'git pull' is clean.
#
# Safe to re-run; safe to run before 'git pull'.
#
# Usage:
#   cd ~/.xydacshell
#   bash adopt.sh               # interactive
#   bash adopt.sh --dry-run     # preview
#   bash adopt.sh --yes         # non-interactive (accept all)
#
# Limitations:
#   - Only captures ADDITIONS (lines prefixed '+' in the diff). Deletions and
#     in-place modifications can't be migrated safely and are left as-is.
#   - Lines that depend on context (e.g., inside an if block) may be orphaned
#     when appended to a custom file. Review after.

set -euo pipefail

XYDACSHELL_HOME="${XYDACSHELL_HOME:-$HOME/.xydacshell}"
DRY=0
YES=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)   DRY=1; shift ;;
    --yes|-y)    YES=1; shift ;;
    -h|--help)
      sed -n '1,22p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "adopt.sh: unknown flag: $1" >&2; exit 2 ;;
  esac
done

cd "$XYDACSHELL_HOME"

if [ ! -d ".git" ]; then
  echo "adopt.sh: $XYDACSHELL_HOME is not a git checkout" >&2
  exit 1
fi

_prompt_yn() {
  local q="$1" default="${2:-y}" hint ans
  [ "$YES" = 1 ] && return 0
  case "$default" in y|Y) hint="[Y/n]" ;; *) hint="[y/N]" ;; esac
  printf '  %s %s ' "$q" "$hint" >&2
  read -r ans
  : "${ans:=$default}"
  case "$ans" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

_adopt_one() {
  local tracked="$1" custom="$2"

  [ -f "$tracked" ] || return 0
  git ls-files --error-unmatch "$tracked" >/dev/null 2>&1 || return 0
  git diff --quiet -- "$tracked" && return 0

  local additions
  additions="$(git diff -- "$tracked" | awk '/^\+[^+]/ {sub(/^\+/,""); print}')"

  if [ -z "$additions" ]; then
    printf '→ %s: only deletions/context changes; nothing to migrate.\n' "$tracked" >&2
    return 0
  fi

  printf '\n→ %s — additions to migrate to %s:\n' "$tracked" "$custom" >&2
  printf '%s\n' "$additions" | sed 's/^/    /' >&2

  if ! _prompt_yn "migrate these lines?" y; then
    printf '  skipped %s\n' "$tracked" >&2
    return 0
  fi

  if [ "$DRY" = 1 ]; then
    printf '  (dry run) would append to %s and reset %s\n' "$custom" "$tracked" >&2
    return 0
  fi

  {
    printf '\n# ---- migrated from %s on %s ----\n' "$(basename "$tracked")" "$(date -u +%Y-%m-%d)"
    printf '%s\n' "$additions"
  } >> "$custom"
  git checkout -- "$tracked"
  printf '  ✓ migrated to %s; %s reset.\n' "$custom" "$tracked" >&2
}

_adopt_one zshrc.file zshrc.custom
_adopt_one vimrc.file vimrc.custom

echo "done." >&2
