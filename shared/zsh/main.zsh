export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export STARSHIP_CONFIG=~/.config/starship/starship.toml
export EDITOR="nvim"

# 设置别名
alias gc='cd ~/.config/'
alias lg='lazygit'
alias md='open -a "Typora"'

# Copy command output to clipboard (safe: only works in a pipeline)
ccp() {
  if [ -t 0 ]; then
    echo "Usage: some_command | ccp" >&2
    return 1
  fi
  tee /dev/tty | pbcopy
}

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

ZSH_HIGHLIGHTING="/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
ZSH_AUTOSUGGESTIONS="/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Activate shell integrations when their brew packages are installed.
[ -r "$ZSH_HIGHLIGHTING" ] && source "$ZSH_HIGHLIGHTING"
[ -r "$ZSH_AUTOSUGGESTIONS" ] && source "$ZSH_AUTOSUGGESTIONS"

command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# Load machine-local overrides if present.
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/local.zsh" ] \
  && source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/local.zsh"
