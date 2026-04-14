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
    tree-sitter:brew) echo tree-sitter ;;
    tree-sitter:apt|tree-sitter:dnf|tree-sitter:pacman) echo tree-sitter-cli ;;
    tree-sitter:apk) echo "" ;;
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

  # Bucket missing tools into (a) native PM packages and (b) fallback commands.
  local pm_pkgs=() pm_tools=() fallback_tools=() no_recipe=()
  for t in "${missing[@]}"; do
    local pkg
    pkg="$(xs_pkg_for "$t" "$XS_PM")"
    if [ -n "$pkg" ]; then
      pm_pkgs+=("$pkg")
      pm_tools+=("$t")
    elif [ -n "$(xs_fallback_for "$t")" ]; then
      fallback_tools+=("$t")
    else
      no_recipe+=("$t")
    fi
  done

  # Batch-install everything the native PM handles in one shot.
  if [ "${#pm_pkgs[@]}" -gt 0 ]; then
    local batch_cmd
    case "$XS_PM" in
      brew)    batch_cmd="brew install ${pm_pkgs[*]}" ;;
      apt)     batch_cmd="sudo apt-get update && sudo apt-get install -y ${pm_pkgs[*]}" ;;
      dnf)     batch_cmd="sudo dnf install -y ${pm_pkgs[*]}" ;;
      pacman)  batch_cmd="sudo pacman -S --noconfirm ${pm_pkgs[*]}" ;;
      apk)     batch_cmd="sudo apk add ${pm_pkgs[*]}" ;;
    esac

    printf '\n'
    xs_info "install ${#pm_tools[@]} tool(s) via $XS_PM: ${pm_tools[*]}"
    xs_dim "    $batch_cmd"
    if xs_prompt_yn "    proceed?" "y"; then
      if [ "${XS_DRY_RUN:-0}" = 1 ]; then
        xs_dim "    (dry run) would run the command above"
      else
        if sh -c "$batch_cmd"; then
          xs_ok "  installed via $XS_PM: ${pm_tools[*]}"
        else
          xs_err "  batch install failed — try individual installs, or see each project's docs"
        fi
      fi
    else
      xs_dim "    skipped."
    fi
  fi

  # Fallback installs: per-tool because they're all different curl/cargo scripts.
  if [ "${#fallback_tools[@]}" -gt 0 ]; then
    printf '\n'
    xs_info "tools without a $XS_PM package:"
    for t in "${fallback_tools[@]}"; do
      local cmd
      cmd="$(xs_fallback_for "$t")"
      printf '\n'
      xs_dim "  $t: $cmd"
      if xs_prompt_yn "  install $t?" "n"; then
        if [ "${XS_DRY_RUN:-0}" = 1 ]; then
          xs_dim "    (dry run) would run the command above"
        else
          sh -c "$cmd" && xs_ok "    $t installed" || xs_err "    $t install failed"
        fi
      fi
    done
  fi

  if [ "${#no_recipe[@]}" -gt 0 ]; then
    xs_warn "no install recipe on $XS_PM for: ${no_recipe[*]}"
  fi

  # The Debian/Ubuntu batcat → bat alias is handled automatically in the
  # modern profile zshrc; no note needed.
}

# Detect whether any Nerd Font is installed on the system.
xs_has_nerd_font() {
  # Font names appear as both 'NerdFont' (filename, no space) and 'Nerd Font'
  # (family name, with space). Match either.
  if xs_command_exists fc-list; then
    fc-list 2>/dev/null | grep -qiE 'nerd.?font' && return 0
  fi
  # Scan common font directories on macOS and Linux.
  local d
  for d in \
    "$HOME/Library/Fonts" \
    /Library/Fonts \
    "$HOME/.local/share/fonts" \
    "$HOME/.fonts" \
    /usr/share/fonts \
    /usr/local/share/fonts; do
    [ -d "$d" ] || continue
    if find "$d" -maxdepth 4 -type f \( -iname '*nerdfont*' -o -iname '*nerd*font*' \) 2>/dev/null | head -1 | grep -q .; then
      return 0
    fi
  done
  return 1
}

# Offer to install a Nerd Font. lsd's file-type icons and some starship glyphs
# require one; without it, they render as empty boxes.
xs_modern_fonts_offer() {
  xs_detect_pm

  if xs_has_nerd_font; then
    xs_ok "Nerd Font detected"
    return 0
  fi

  printf '\n'
  xs_warn "no Nerd Font detected — lsd icons and some starship glyphs won't render"
  cat <<'EOF'

pick a Nerd Font to install (or skip):
  1) JetBrains Mono   (coding-oriented, sharp)
  2) Meslo LGM        (popular for terminals)
  3) Fira Code        (with ligatures)
  4) Hack             (simple, clean)
  s) skip
EOF
  local choice=""
  if [ "${FORCE:-0}" = 1 ]; then
    choice=1
  elif [ "${XS_DRY_RUN:-0}" = 1 ]; then
    choice=1
  else
    printf 'choice [1]: '
    read -r choice
  fi
  : "${choice:=1}"

  local cask name
  case "$choice" in
    1) cask=font-jetbrains-mono-nerd-font; name=JetBrainsMono ;;
    2) cask=font-meslo-lg-nerd-font;        name=Meslo ;;
    3) cask=font-fira-code-nerd-font;       name=FiraCode ;;
    4) cask=font-hack-nerd-font;            name=Hack ;;
    s|S) xs_dim "  skipped."; return 0 ;;
    *) xs_warn "  invalid choice; skipping."; return 0 ;;
  esac

  case "$XS_OS" in
    macos)
      if ! xs_command_exists brew; then
        xs_err "  brew required for macOS font install — skipping."
        return 0
      fi
      local cmd="brew install --cask $cask"
      xs_info "  installing: $cmd"
      if [ "${XS_DRY_RUN:-0}" = 1 ]; then
        xs_dim "    (dry run) would run the command above"
      else
        sh -c "$cmd" && xs_ok "  installed $cask" || xs_err "  font install failed"
      fi
      xs_dim "  → set your terminal font to '$name Nerd Font', then restart it"
      ;;
    linux)
      _xs_install_nerd_font_linux "$name"
      ;;
    *)
      xs_warn "  unsupported OS for auto-font install"
      xs_dim "  see https://www.nerdfonts.com/font-downloads"
      ;;
  esac
}

_xs_install_nerd_font_linux() {
  local name="$1"
  local zip="/tmp/${name}.zip"
  local dest="$HOME/.local/share/fonts/${name}NerdFont"
  local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${name}.zip"

  xs_info "  downloading $name Nerd Font"
  xs_dim "    $url"

  if [ "${XS_DRY_RUN:-0}" = 1 ]; then
    xs_dim "    (dry run) would download + extract + fc-cache"
    return 0
  fi

  xs_run mkdir -p "$dest"
  if curl -fsSL "$url" -o "$zip" 2>/dev/null; then
    if command -v unzip >/dev/null 2>&1; then
      unzip -oq "$zip" -d "$dest" 2>/dev/null || { xs_err "  unzip failed"; return 0; }
    else
      xs_err "  unzip not available; install it and retry"
      return 0
    fi
    if command -v fc-cache >/dev/null 2>&1; then
      fc-cache -f "$dest" 2>/dev/null
    else
      xs_warn "  fc-cache missing; fonts copied but not registered — install fontconfig"
    fi
    rm -f "$zip"
    xs_ok "  installed $name Nerd Font to $dest"
    xs_dim "  → set your terminal font to '$name Nerd Font', then restart it"
  else
    xs_err "  download failed; install manually from https://www.nerdfonts.com/"
  fi
}
