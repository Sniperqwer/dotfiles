export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export STARSHIP_CONFIG=~/.config/starship/starship.toml
export EDITOR="nvim"

# 设置别名
alias gc='cd ~/.config/'
alias gs='cd ~/self/'
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

# Activate syntax highlighting
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# Activate autosuggestions
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# Load machine-local overrides if present.
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/work.zsh" ] \
  && source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/work.zsh"
