#!/usr/bin/env bash
# x switch <profile> — shorthand for install --profile <profile>.

xs_cmd_switch() {
  local profile="${1:-}"
  case "$profile" in
    classic|modern) ;;
    -h|--help|"")
      cat <<'EOF'
usage: x switch <classic|modern> [--dry-run] [--force]

Switches the active xydacshell profile. Equivalent to:
  bash install.sh --profile <profile>
EOF
      [ -z "$profile" ] && return 2 || return 0
      ;;
    *) xs_err "unknown profile: $profile (expected classic|modern)"; return 2 ;;
  esac
  shift
  (cd "$XYDACSHELL_HOME" && bash "$XYDACSHELL_HOME/install.sh" --profile "$profile" "$@")
}
