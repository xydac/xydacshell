#!/usr/bin/env bash
# xydacshell install — delegates to the root install.sh.

xs_cmd_install() {
  (cd "$XYDACSHELL_HOME" && bash "$XYDACSHELL_HOME/install.sh" "$@")
}
