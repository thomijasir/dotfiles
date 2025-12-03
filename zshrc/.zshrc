#!/bin/zsh
# =========================
# ZSH CONFIGURATION
# =========================

# load env vars from .zprofile into the shells
if [[ -z "$ZPROFILE_LOADED" && -r ~/.zprofile ]]; then
  source ~/.zprofile
fi

# =========================
# HISTORY SETTINGS
# =========================

# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS

# Performance tweaks
export ZSH_DISABLE_COMPFIX=true
zstyle ':completion:*' rehash true
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

# Make terminal snappier
export KEYTIMEOUT=1

# =============================================================================
# PLUGIN CONFIGURATION
# =============================================================================

# Antidote Plugin Manager
# Load antidote
if [[ -f /opt/homebrew/share/antidote/antidote.zsh ]]; then
  source /opt/homebrew/share/antidote/antidote.zsh
  antidote load
elif [[ -f /usr/local/share/antidote/antidote.zsh ]]; then
  source /usr/local/share/antidote/antidote.zsh
  antidote load
fi

# Zoxide (smart cd)
eval "$(zoxide init zsh)"

# FZF (fuzzy finder)
# Cache fzf init
if [[ ! -f ~/.fzf.zsh ]]; then
  fzf --zsh > ~/.fzf.zsh
fi
source ~/.fzf.zsh

# Prompt (fast & clean)
autoload -Uz promptinit && promptinit
prompt pure

# Fix slow compinit (caching)
autoload -Uz compinit
compinit -C

# Completion using arrow keys (based on history)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# =============================================================================
# Helper Scripts
# =============================================================================

# ZSH Configuration commad
alias zsh_profile='hx ~/.zprofile'
alias zsh_config='hx ~/.zshrc'
# reload zsh config
alias zsh_reload='source ~/.zshrc && source ~/.zprofile'

# -- Development Tools Scripts
alias react_tools='deno run --allow-read --allow-write $DOTFILES_ROOT/scripts/react-tools.ts'

# --- MacOS Process ---
alias appkill='f() {
  local pid
  pid=$(ps aux | sed 1d | fzf -m --header="[kill process]" --preview="echo {}" --preview-window=down:3:wrap | awk "{print \$2}")
  if [ "x$pid" != "x" ]; then
    echo $pid | xargs kill -9
    echo "Killed process(es): $pid"
  fi
}; f'

# --- File Operations ---
alias cp='cp -iv'       # Preferred 'cp' implementation
alias mv='mv -iv'       # Preferred 'mv' implementation
alias mkdir='mkdir -pv' # Preferred 'mkdir' implementation

# --- Directory Listing ---
alias ll='ls -FGlAhp' # Preferred 'ls' implementation
# options: --no-filesize --no-time --no-permissions
alias ls="eza --no-filesize --long --color=always --icons=always --no-user"

# --- Directory Navigation ---
alias cd='z' # Use zoxide
alias work='cd ~/Workspace'

# --- Tree View ---
alias tree="tree -L 3 -a -I '.git' --charset X "
alias dtree="tree -L 3 -a -d -I '.git' --charset X "

# --- Editor Aliases ---
alias vim='nvim'
alias temp='nvim ~/temp.md'

# --- Development Tools ---
alias lg="lazygit"
alias ld="lazydocker"
alias mdts="npx mdts . --silent"

# --- Replace Script ---
alias sr='replace-str.sh'
alias sf='replace-file.sh'

# --- Git Shortcuts ---
alias ga='git add .'                        # Git Add
alias gf='git fetch && git pull'            # Git Fetch And Pull
alias gp='git push'                         # Git Push
alias gs='git status'                       # Git Status
alias gc='f() { git commit -m "$1"; }; f'   # Git Commit with message
alias gb='f() { git checkout -b "$1"; }; f' # Git create new branch
alias gdb='git-delete-branch.sh'

# --- Open Files Script ---
alias hzo='hx-zoxide.sh'
alias fman="compgen -c | fzf | xargs man"

# --- Configuration Files ---
alias nvim_config='hx ~/.config/nvim'
alias helix_config='hx ~/.config/helix'
alias wezterm_config='hx ~/.wezterm.lua'

# --- Development Environment ---
alias crw='cargo watch -q -c -w src/ -x run' # Cargo watch and run

# --- Mobile Development ---
alias androidUp='emulator -avd Pixel_2_API_28' # Open Emulator
alias iosUp='open -a Simulator'                # Open Simulator

# -- Dart & Flutter
alias dart='fvm dart'
alias flutter='fvm flutter'

# --- Network Tools ---
alias ngrok="$HOME/.ngrok" # add ngrok

# --- Cleanup Commands ---
alias rm_node='rm -rf node_modules package-lock.json'
alias cleanupDS="find . -type f -name '*.DS_Store' -ls -delete" # Auto Clean DS
alias cleadNODE="find . -name 'node_modules' -type d -prune -print -exec rm -rf '{}' \;"

# Super Shell Yazi
y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd <"$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

# Calculate file/directory sizes
dsize() {
  du -sh "${1:-.}"/* 2>/dev/null | sort -hr | head -n 20
}

# Find biggest files in current directory
bigfiles() {
  find . -type f -exec du -h {} + 2>/dev/null | sort -rh | head -n "${1:-10}"
}

# Open project directories with fzf
proj() {
  local dir
  dir=$(find ~/Workspace -maxdepth 3 -type d 2>/dev/null | fzf --preview "ls -la {}")
  [ -n "$dir" ] && cd "$dir"
}

# Get public IP address
myip() {
  curl -s https://api.ipify.org
  echo ""
}

# Get local IP address
localip() {
  ipconfig getifaddr en0 || ipconfig getifaddr en1
}

# make and crete file
cf() {
  mkdir -p "$(dirname "$1")" && touch "$1"
}

