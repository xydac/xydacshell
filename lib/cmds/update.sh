#!/usr/bin/env bash
# xydacshell update — git pull + submodule sync + reinstall.

xs_cmd_update() {
  local xh="$XYDACSHELL_HOME"

  if [ ! -d "$xh/.git" ]; then
    xs_err "$xh is not a git checkout; cannot update."
    return 1
  fi

  xs_info "pulling latest"
  xs_run git -C "$xh" pull --rebase

  xs_info "syncing submodules"
  xs_run git -C "$xh" submodule update --init --recursive

  xs_info "reinstalling current profile"
  (cd "$xh" && bash "$xh/install.sh" "$@")
}
