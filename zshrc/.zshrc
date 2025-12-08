export DOTFILES_ROOT="${HOME}/Workspace/dotfiles"

# --- Homebrew Init ---
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ---------------------------------------------------------------
# PATH CONFIGURATION
# ---------------------------------------------------------------

# Custom Scripts dot files
export PATH="$DOTFILES_ROOT/scripts:$PATH"

# Library paths
export LIBRARY_PATH="/opt/homebrew/lib:$LIBRARY_PATH"

# General PATH improvements
export PATH="/usr/local/git/bin:/sw/bin:/usr/local/bin:/usr/local/sbin:/usr/local/mysql/bin:$PATH"

# --- Java ---
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"

# --- Ruby (RVM) ---
export PATH="$PATH:$HOME/.rvm/bin"
function rvm() {
  unset -f rvm
  [[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
  rvm "$@"
}

#--- Node (NVM) Lazymode ---
# export NVM_DIR="$HOME/.nvm"
# [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
# [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"
# function _load_nvm() {
#   unset -f nvm node npm npx
#   [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
#   # This loads nvm bash_completion
#   [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"
# }
# function nvm() { _load_nvm; nvm "$@"; }
# function node() { _load_nvm; node "$@"; }
# function npm() { _load_nvm; npm "$@"; }
# function npx() { _load_nvm; npx "$@"; }

# --- Android ---
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin

# Default Terminal editor (helix or nvim)
# export EDITOR=/opt/homebrew/bin/nvim
export EDITOR=/opt/homebrew/bin/hx
# Visual Studio Code
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
# Windsurf (Added by Windsurf)
export PATH="$HOME/.codeium/windsurf/bin:$PATH"
export PATH="/opt/homebrew/opt/trash-cli/bin:$PATH"

# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS

# Performance tweaks
zstyle ':completion:*' rehash true
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

# Make terminal snappier
export KEYTIMEOUT=1

# Completion using arrow keys (based on history)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# ---------------------------------------------------------------
# PLUGIN CONFIGURATION
# ---------------------------------------------------------------

# --- START Antidote Plugin Manager ---
source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh

# Generate new static antidote if .zsh_plugins has exists (follows symlink) and has no file .zsh_plugins.zsh or diff timestamps
if [[ -e ~/.zsh_plugins ]] && { [[ ! -f ~/.zsh_plugins.zsh ]] || [[ ~/.zsh_plugins -nt ~/.zsh_plugins.zsh ]]; }; then
  antidote bundle <~/.zsh_plugins >|~/.zsh_plugins.zsh
fi

# Load the static bundle
[[ -f ~/.zsh_plugins.zsh ]] && source ~/.zsh_plugins.zsh

# --- END Antidote Plugin Manager ---

# Smarter completion initialization
autoload -Uz compinit
if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
  compinit
else
  compinit -C
fi
# autoload -Uz compinit
# compinit -C

# Prompt (fast & clean)
# autoload -Uz promptinit && promptinit
# prompt pure

# Zoxide (smart cd)
# if command -v zoxide &>/dev/null; then
#   eval "$(zoxide init zsh)"
# fi

# --- python environment ---
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# --- Load Aliases ---
[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases
[[ -f ~/.zsh_help ]] && source ~/.zsh_help

# # FZF (fuzzy finder)
# if [[ ! -f ~/.zsh_fzf ]]; then
#   fzf --zsh > ~/.zsh_fzf
# fi
# source ~/.zsh_fzf
