#!/usr/bin/env bash
# xydacshell — modern profile tool installer.
# Detects OS + package manager, offers to install missing tools.
# Sourced by install.sh; not stand-alone. Depends on lib/util.sh.

# Detect OS and a primary package manager.
# Sets: XS_OS, XS_PM.  Values for XS_PM: brew | apt | dnf | pacman | apk | unknown
xs_detect_pm() {
  case "$(uname -s)" in
    Darwin) XS_OS=macos ;;
    Linux)  XS_OS=linux ;;
    *)      XS_OS=unknown ;;
  esac

  if [ "$XS_OS" = macos ]; then
    if xs_command_exists brew; then XS_PM=brew; else XS_PM=unknown; fi
    export XS_OS XS_PM
    return 0
  fi

  for pm in apt-get dnf pacman apk; do
    if xs_command_exists "$pm"; then
      case "$pm" in
        apt-get) XS_PM=apt ;;
        *)       XS_PM="$pm" ;;
      esac
      export XS_OS XS_PM
      return 0
    fi
  done
  XS_PM=unknown
  export XS_OS XS_PM
}

# xs_pkg_for <tool> <pm>: echo the package name for that pm, or empty if unsupported.
xs_pkg_for() {
  local tool="$1" pm="$2"
  case "$tool:$pm" in
    starship:brew)    echo starship ;;
    starship:pacman)  echo starship ;;
    starship:apt|starship:dnf|starship:apk) echo "" ;;  # use fallback curl installer
    nvim:brew)        echo neovim ;;
    nvim:apt|nvim:dnf|nvim:pacman|nvim:apk) echo neovim ;;
    fzf:brew|fzf:apt|fzf:dnf|fzf:pacman|fzf:apk) echo fzf ;;
    zoxide:brew|zoxide:pacman|zoxide:dnf) echo zoxide ;;
    zoxide:apt|zoxide:apk) echo "" ;;
    lsd:brew|lsd:apt|lsd:dnf|lsd:pacman|lsd:apk) echo lsd ;;
    bat:brew|bat:pacman|bat:dnf) echo bat ;;
    bat:apt) echo bat ;;  # on Debian the binary is called batcat — user needs to alias
    bat:apk) echo bat ;;
    ncdu:brew|ncdu:apt|ncdu:dnf|ncdu:pacman|ncdu:apk) echo ncdu ;;
    dust:brew|dust:pacman|dust:dnf) echo dust ;;
    dust:apt|dust:apk) echo "" ;;  # fallback: cargo install du-dust
    duf:brew|duf:apt|duf:dnf|duf:pacman|duf:apk) echo duf ;;
    *) echo "" ;;
  esac
}

# xs_fallback_for <tool>: echo a single-line install command to run when the pm has no pkg.
xs_fallback_for() {
  local tool="$1"
  case "$tool" in
    starship) echo 'curl -sS https://starship.rs/install.sh | sh -s -- --yes' ;;
    zoxide)   echo 'curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh' ;;
    dust)     echo 'cargo install du-dust   # requires Rust toolchain' ;;
    *)        echo "" ;;
  esac
}

# xs_install_cmd <pkg> <pm>: emit the install command for that pm.
xs_install_cmd() {
  local pkg="$1" pm="$2"
  case "$pm" in
    brew)    echo "brew install $pkg" ;;
    apt)     echo "sudo apt-get update && sudo apt-get install -y $pkg" ;;
    dnf)     echo "sudo dnf install -y $pkg" ;;
    pacman)  echo "sudo pacman -S --noconfirm $pkg" ;;
    apk)     echo "sudo apk add $pkg" ;;
    *)       echo "" ;;
  esac
}

# xs_modern_tools_offer: for each tool in $1..., if missing, show install option and install if accepted.
# Returns 0 regardless of individual outcomes (modern profile degrades gracefully).
xs_modern_tools_offer() {
  local tools=("$@")
  xs_detect_pm

  xs_info "modern-profile tools"
  xs_dim "  OS: $XS_OS · package manager: $XS_PM"

  local present=() missing=()
  local t
  for t in "${tools[@]}"; do
    if xs_command_exists "$t"; then
      present+=("$t")
      xs_ok "  $t (installed)"
    else
      missing+=("$t")
    fi
  done

  if [ "${#missing[@]}" -eq 0 ]; then
    xs_ok "all modern tools are installed"
    return 0
  fi

  xs_warn "missing: ${missing[*]}"

  if [ "$XS_PM" = "unknown" ]; then
    xs_warn "no supported package manager detected; skipping install prompts"
    xs_dim "  install manually when ready — the profile degrades gracefully"
    return 0
  fi

  for t in "${missing[@]}"; do
    local pkg cmd
    pkg="$(xs_pkg_for "$t" "$XS_PM")"
    if [ -n "$pkg" ]; then
      cmd="$(xs_install_cmd "$pkg" "$XS_PM")"
    else
      cmd="$(xs_fallback_for "$t")"
    fi

    if [ -z "$cmd" ]; then
      xs_warn "  $t: no install recipe for $XS_PM on $XS_OS"
      continue
    fi

    printf '\n'
    xs_info "install $t?"
    xs_dim "    will run: $cmd"
    if xs_prompt_yn "    install $t" "n"; then
      if [ "${XS_DRY_RUN:-0}" = 1 ]; then
        xs_dim "    would run: $cmd"
      else
        if sh -c "$cmd"; then
          xs_ok "  $t installed"
        else
          xs_err "  $t install failed (continuing — profile tolerates missing tools)"
        fi
      fi
    else
      xs_dim "    skipped $t"
    fi
  done

  # Post-install note for bat on Debian/Ubuntu where the binary is `batcat`.
  if [ "$XS_PM" = apt ] && xs_command_exists batcat && ! xs_command_exists bat; then
    xs_dim "  note: Debian/Ubuntu ships 'bat' as 'batcat'. Add to your zshrc.custom: alias bat=batcat"
  fi
}
