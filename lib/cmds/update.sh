#!/usr/bin/env bash
# x update — heal + pull + submodule sync + reinstall.
# Also the replacement for 'x switch': pass --profile to switch profile.
#
# Usage:
#   x update                          heal, pull, reinstall current profile
#   x update --profile modern         heal, pull, switch to modern
#   x update --profile classic        heal, pull, switch to classic
#   x update --dry-run / --force      forwarded to install.sh

# shellcheck source=../heal.sh
. "$XYDACSHELL_HOME/lib/heal.sh"

xs_cmd_update() {
  local xh="$XYDACSHELL_HOME"

  if [ ! -d "$xh/.git" ]; then
    xs_err "$xh is not a git checkout; cannot update."
    return 1
  fi

  xs_info "healing dirty state (if any)"
  xs_heal || return 1

  xs_info "pulling latest"
  xs_run git -C "$xh" pull --rebase --autostash

  xs_info "syncing submodules"
  xs_run git -C "$xh" submodule update --init --recursive

  xs_info "reinstalling"
  (cd "$xh" && bash "$xh/install.sh" "$@")
}
