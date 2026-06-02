#!/usr/bin/env bash
#
# install.sh — install brew packages used by this dotfiles repo.
#
# Usage:
#   bash install.sh            install all CLI formulas
#   bash install.sh --cask     install all casks
#   bash install.sh --all      install CLI formulas + casks
#   bash install.sh --dry-run  print what would be installed, do nothing
#   bash install.sh -h         show this help
#
# Requires Homebrew. If brew is not found, prints install instructions and exits.

set -euo pipefail

# ---------- colors / log helpers ----------
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_DIM=$'\033[2m'; C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'
else
  C_RESET=''; C_DIM=''; C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''
fi

info()  { printf '%s[info]%s %s\n'  "$C_BLUE"   "$C_RESET" "$*"; }
ok()    { printf '%s[ ok ]%s %s\n'  "$C_GREEN"  "$C_RESET" "$*"; }
skip()  { printf '%s[skip]%s %s\n'  "$C_DIM"    "$C_RESET" "$*"; }
warn()  { printf '%s[warn]%s %s\n'  "$C_YELLOW" "$C_RESET" "$*" >&2; }
err()   { printf '%s[fail]%s %s\n'  "$C_RED"    "$C_RESET" "$*" >&2; }

# ---------- usage ----------
usage() {
  cat <<'EOF'
Usage: bash install.sh [FLAG]

Flags:
  (none)        Install all CLI formulas
  --cask        Install all casks
  --all         Install CLI formulas + casks
  --dry-run     Print what would be installed; do nothing (combine with others)
  -h, --help    Show this help

Examples:
  bash install.sh                 # CLI only
  bash install.sh --cask          # casks only
  bash install.sh --all           # everything
  bash install.sh --all --dry-run # preview everything
EOF
}

# ---------- flag parsing ----------
DO_CLI=0
DO_CASK=0
DRY_RUN=0
EXPLICIT_GROUP=0

for arg in "$@"; do
  case "$arg" in
    --cask)    DO_CASK=1; EXPLICIT_GROUP=1 ;;
    --all)     DO_CLI=1; DO_CASK=1; EXPLICIT_GROUP=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *)         err "unknown flag: $arg"; usage; exit 1 ;;
  esac
done

# default when no group flag given: install CLI
if [[ $EXPLICIT_GROUP -eq 0 ]]; then
  DO_CLI=1
fi

# ---------- brew availability check ----------
if ! command -v brew >/dev/null 2>&1; then
  err "Homebrew not found."
  cat <<'EOF' >&2

Install Homebrew first:

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

See https://brew.sh for details. Then re-run this script.
EOF
  exit 1
fi

# ---------- package lists ----------
# CLI formulas — see /Users/sniper/.claude/plans/install-sh-* for rationale.
CLI_FORMULAS=(
  # Yazi preview stack
  yazi
  glow
  bat
  exiftool
  ffmpeg
  imagemagick
  poppler
  rich-cli
  sevenzip
  fd
  ripgrep
  fzf
  zoxide

  # Shell
  starship
  zsh-autosuggestions
  zsh-syntax-highlighting

  # Editor / git / dotfiles tooling
  neovim
  tmux
  lazygit
  stow

  # Daily productivity CLI
  jq
  tree
  tlrc
  eza
  lsd
  markdownlint-cli2
  ruff
  uv
  node
  kubernetes-cli
  gnupg
  merve
)

CASKS=(
  ghostty
  wezterm
  karabiner-elements
  font-lxgw-wenkai
)

# ---------- install helpers ----------
FAILED=()

install_formula() {
  local pkg="$1"
  if brew list --formula "$pkg" >/dev/null 2>&1; then
    skip "formula: $pkg (already installed)"
    return 0
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    info "[dry-run] would install formula: $pkg"
    return 0
  fi
  info "installing formula: $pkg"
  if brew install "$pkg"; then
    ok "installed: $pkg 🍺"
  else
    err "failed to install: $pkg"
    FAILED+=("formula:$pkg")
  fi
}

install_cask() {
  local pkg="$1"
  if brew list --cask "$pkg" >/dev/null 2>&1; then
    skip "cask: $pkg (already installed)"
    return 0
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    info "[dry-run] would install cask: $pkg"
    return 0
  fi
  info "installing cask: $pkg"
  if brew install --cask "$pkg"; then
    ok "installed: $pkg 🍺"
  else
    err "failed to install: $pkg"
    FAILED+=("cask:$pkg")
  fi
}

# ---------- main flow ----------
if [[ $DRY_RUN -eq 1 ]]; then
  info "dry-run mode: no packages will be installed"
fi

if [[ $DO_CLI -eq 1 ]]; then
  info "==> CLI formulas (${#CLI_FORMULAS[@]} packages)"
  for pkg in "${CLI_FORMULAS[@]}"; do
    install_formula "$pkg"
  done
fi

if [[ $DO_CASK -eq 1 ]]; then
  info "==> Casks (${#CASKS[@]} packages)"
  for pkg in "${CASKS[@]}"; do
    install_cask "$pkg"
  done
fi

# ---------- summary ----------
echo
if [[ ${#FAILED[@]} -gt 0 ]]; then
  warn "Some packages failed to install:"
  for f in "${FAILED[@]}"; do
    printf '  - %s\n' "$f" >&2
  done
  exit 1
fi

ok "Done. 🍺"
