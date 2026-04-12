#!/usr/bin/env bash
# xydacshell storage — disk-usage report with optional cleanup prompts.

xs_cmd_storage() {
  local flag_caches_only=0 flag_clean=0 top=10

  while [ $# -gt 0 ]; do
    case "$1" in
      --caches)    flag_caches_only=1; shift ;;
      --clean)     flag_clean=1; shift ;;
      --top)       top="${2:-10}"; shift 2 ;;
      --top=*)     top="${1#--top=}"; shift ;;
      --dry-run)   XS_DRY_RUN=1; export XS_DRY_RUN; shift ;;
      --force)     FORCE=1; export FORCE; shift ;;
      -h|--help)
        cat <<'EOF'
usage: xydacshell storage [--caches] [--top N] [--clean] [--dry-run] [--force]

Disk-usage report covering filesystems, $HOME top directories, package-manager
caches, containers, and trash.

  --caches   only show package-manager caches (skip filesystems and $HOME)
  --top N    number of $HOME top dirs to show (default 10)
  --clean    after the report, prompt per-cache to run its cleanup command
  --dry-run  preview (affects --clean)
  --force    accept all prompts (affects --clean)
EOF
        return 0
        ;;
      *) xs_err "unknown flag: $1"; return 2 ;;
    esac
  done

  if [ "$flag_caches_only" != 1 ]; then
    _xs_storage_filesystems
    _xs_storage_home "$top"
  fi
  _xs_storage_caches
  _xs_storage_containers
  _xs_storage_trash

  if [ "$flag_clean" = 1 ]; then
    _xs_storage_clean
  fi
}

# Report filesystems (prefers duf when available, else df -h).
_xs_storage_filesystems() {
  printf '\nfilesystems\n'
  if xs_command_exists duf; then
    duf --only local 2>/dev/null | sed 's/^/  /'
  else
    df -h 2>/dev/null | head -12 | sed 's/^/  /'
  fi
}

# Top N $HOME directories by size. Uses dust when available, else du | sort.
_xs_storage_home() {
  local n="${1:-10}"
  printf '\n$HOME top %s directories\n' "$n"
  if xs_command_exists dust; then
    dust -d 1 -n "$n" "$HOME" 2>/dev/null | sed 's/^/  /'
  else
    du -sh "$HOME"/* 2>/dev/null | sort -hr | head -"$n" | sed 's/^/  /'
  fi
}

# Return human-readable size of a path, or '-' if absent/empty.
_xs_size() {
  local p="$1"
  if [ -n "$p" ] && { [ -d "$p" ] || [ -f "$p" ]; }; then
    du -sh "$p" 2>/dev/null | awk '{print $1}'
  else
    printf '-'
  fi
}

_xs_storage_caches() {
  printf '\npackage-manager caches\n'

  local brew_cache="" npm_cache="" pnpm_cache="" cargo_cache="$HOME/.cargo" pip_cache=""
  xs_command_exists brew && brew_cache="$(brew --cache 2>/dev/null || true)"
  xs_command_exists npm  && npm_cache="$(npm config get cache 2>/dev/null || true)"
  xs_command_exists pnpm && pnpm_cache="$(pnpm store path 2>/dev/null || true)"
  if xs_command_exists pip; then
    pip_cache="$(pip cache dir 2>/dev/null || true)"
  elif xs_command_exists pip3; then
    pip_cache="$(pip3 cache dir 2>/dev/null || true)"
  fi

  local uv_cache=""
  xs_command_exists uv && uv_cache="$(uv cache dir 2>/dev/null || true)"

  _row() { printf '  %-8s %-8s %s\n' "$1" "$(_xs_size "$2")" "$3"; }
  _row brew   "$brew_cache"   "brew cleanup -s"
  _row npm    "$npm_cache"    "npm cache clean --force"
  _row pnpm   "$pnpm_cache"   "pnpm store prune"
  _row cargo  "$cargo_cache"  "cargo cache --autoclean  (needs cargo-cache)"
  _row pip    "$pip_cache"    "pip cache purge"
  [ -n "$uv_cache" ] && _row uv "$uv_cache" "uv cache clean"
}

_xs_storage_containers() {
  if xs_command_exists docker; then
    printf '\ncontainers (docker system df)\n'
    docker system df 2>/dev/null | sed 's/^/  /' | head -5
  fi
}

_xs_storage_trash() {
  local t=""
  case "$(uname -s)" in
    Darwin) t="$HOME/.Trash" ;;
    Linux)  t="$HOME/.local/share/Trash" ;;
  esac
  if [ -n "$t" ] && [ -d "$t" ]; then
    printf '\ntrash\n  %s  %s\n' "$(_xs_size "$t")" "$t"
  fi
}

_xs_storage_clean() {
  printf '\ncleanup (interactive)\n'
  xs_command_exists brew   && xs_prompt_yn "  brew cleanup -s?" n            && xs_run brew cleanup -s
  xs_command_exists npm    && xs_prompt_yn "  npm cache clean?" n            && xs_run npm cache clean --force
  xs_command_exists pnpm   && xs_prompt_yn "  pnpm store prune?" n           && xs_run pnpm store prune
  xs_command_exists pip    && xs_prompt_yn "  pip cache purge?" n            && xs_run pip cache purge
  xs_command_exists uv     && xs_prompt_yn "  uv cache clean?" n             && xs_run uv cache clean
  xs_command_exists docker && xs_prompt_yn "  docker system prune -f?" n     && xs_run docker system prune -f
}
