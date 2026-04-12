#!/usr/bin/env bash
# xydacshell — shared shell helpers. Sourced by install.sh. Not stand-alone.

# Output helpers. Colors only when stdout is a tty.
if [ -t 1 ]; then
  XS_DIM=$'\033[2m'
  XS_BOLD=$'\033[1m'
  XS_RED=$'\033[31m'
  XS_GREEN=$'\033[32m'
  XS_YELLOW=$'\033[33m'
  XS_BLUE=$'\033[34m'
  XS_RESET=$'\033[0m'
else
  XS_DIM=""
  XS_BOLD=""
  XS_RED=""
  XS_GREEN=""
  XS_YELLOW=""
  XS_BLUE=""
  XS_RESET=""
fi

xs_log()  { printf '%s\n' "$*"; }
xs_info() { printf '%s%s%s\n' "$XS_BLUE" "$*" "$XS_RESET"; }
xs_ok()   { printf '%s✓%s %s\n' "$XS_GREEN" "$XS_RESET" "$*"; }
xs_warn() { printf '%s!%s %s\n' "$XS_YELLOW" "$XS_RESET" "$*" >&2; }
xs_err()  { printf '%s✗%s %s\n' "$XS_RED" "$XS_RESET" "$*" >&2; }
xs_dim()  { printf '%s%s%s\n' "$XS_DIM" "$*" "$XS_RESET"; }

# xs_run <cmd...>: run a command, honoring $XS_DRY_RUN. Echoes the command dimly when dry.
xs_run() {
  if [ "${XS_DRY_RUN:-0}" = "1" ]; then
    xs_dim "  would run: $*"
  else
    "$@"
  fi
}

# xs_timestamp: ISO-like stamp safe for filesystem paths.
xs_timestamp() { date -u +"%Y%m%dT%H%M%SZ"; }

# xs_command_exists <cmd>: 0 if on PATH, 1 otherwise.
xs_command_exists() { command -v "$1" >/dev/null 2>&1; }

# xs_backup_file <path> <backup_dir>: move a real file into a timestamped backup dir.
# Skips if the path is a symlink into XYDACSHELL_HOME (our own install) or missing.
xs_backup_file() {
  local path="$1" backup_dir="$2" xhome="${XYDACSHELL_HOME:-$HOME/.xydacshell}"

  if [ ! -e "$path" ] && [ ! -L "$path" ]; then
    return 0
  fi

  if [ -L "$path" ]; then
    local target
    target="$(readlink "$path")"
    case "$target" in
      "$xhome"/*)
        xs_dim "  $path is our symlink, not backing up"
        return 0
        ;;
    esac
  fi

  xs_run mkdir -p "$backup_dir"
  xs_run mv "$path" "$backup_dir/$(basename "$path")"
  xs_ok "backed up $path → $backup_dir/"
}

# xs_symlink <src> <dest>: create an idempotent symlink. Backs up an existing non-symlink.
xs_symlink() {
  local src="$1" dest="$2" backup_dir="$3"

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    xs_dim "  $dest already links to $src"
    return 0
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    xs_backup_file "$dest" "$backup_dir"
  fi

  xs_run ln -s "$src" "$dest"
  xs_ok "linked $dest → $src"
}

# xs_prompt_yn <question> <default>: yes/no prompt. Honors FORCE and XS_DRY_RUN.
# Returns 0 for yes, 1 for no. --force skips ask and returns yes.
# --dry-run also returns yes so previews show what would happen.
xs_prompt_yn() {
  local q="$1" default="${2:-n}"
  if [ "${FORCE:-0}" = 1 ]; then return 0; fi
  if [ "${XS_DRY_RUN:-0}" = 1 ]; then return 0; fi

  local hint
  case "$default" in
    y|Y) hint="[Y/n]" ;;
    *)   hint="[y/N]" ;;
  esac

  printf '%s %s ' "$q" "$hint"
  read -r ans
  : "${ans:=$default}"
  case "$ans" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# xs_profile_read <xhome>: echo the active profile, or "classic" if the file is missing.
xs_profile_read() {
  local xhome="$1" file="$1/profile"
  if [ -f "$file" ]; then
    cat "$file"
  else
    printf 'classic\n'
  fi
}

# xs_profile_write <xhome> <profile>: write the profile file atomically.
xs_profile_write() {
  local xhome="$1" profile="$2"
  xs_run mkdir -p "$xhome"
  if [ "${XS_DRY_RUN:-0}" = "1" ]; then
    xs_dim "  would write profile=$profile to $xhome/profile"
  else
    printf '%s\n' "$profile" > "$xhome/profile"
  fi
  xs_ok "profile set to $profile"
}
