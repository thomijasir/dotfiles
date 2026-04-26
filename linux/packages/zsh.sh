#!/usr/bin/env bash
set -euo pipefail
# ================================
# CONFIG
# ================================
INSTALL_ANTIDOTE=true
FORCE_REPLACE_SH=false # ⚠️ VERY DANGEROUS — READ BELOW

ZSH_DIR="$HOME/.zsh"
ANTIDOTE_DIR="$ZSH_DIR/antidote"

# ================================
# ROOT CHECK
# ================================
if [[ "$EUID" -ne 0 ]]; then
  echo "ℹ️  Script will request sudo when needed."
fi

# ================================
# INSTALL ZSH
# ================================
echo "📦 Installing zsh..."
sudo apt update
sudo apt install -y zsh git curl

# ================================
# SET ZSH AS DEFAULT SHELL
# ================================
if [[ "$SHELL" != "$(which zsh)" ]]; then
  echo "🔁 Setting zsh as default shell..."
  chsh -s "$(which zsh)"
fi

# ================================
# INSTALL ANTIDOTE
# ================================
if [[ "$INSTALL_ANTIDOTE" == true ]]; then
  echo "⚡ Installing Antidote..."
  mkdir -p "$ZSH_DIR"
  if [[ ! -d "$ANTIDOTE_DIR" ]]; then
    git clone https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
  fi
fi

# ================================
# CREATE .zshrc
# ================================
ZSHRC="$HOME/.zshrc"

if [[ ! -f "$ZSHRC" ]]; then
  echo "📝 Creating .zshrc..."
  cat <<EOF >"$ZSHRC"
# ================================
# ZSH CONFIG
# ================================
# Path Variable
export ZDOTDIR=\$HOME
export ZSH_DIR="\$HOME/.zsh"
export ANTIDOTE_DIR="\$ZSH_DIR/antidote"

# Path Export
export PATH="\$HOME/bin:\$PATH"
export PATH="\$HOME/.local/bin:\$PATH"

# History
ZSH_DISABLE_COMPFIX=true
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

# Enable Antidote
source $ANTIDOTE_DIR/antidote.zsh

# Generate new static antidote if .zsh_plugins has exists (follows symlink) and has no file .zsh_plugins.zsh or diff timestamps
if [[ -e ~/.zsh_plugins ]] && { [[ ! -f ~/.zsh_plugins.zsh ]] || [[ ~/.zsh_plugins -nt ~/.zsh_plugins.zsh ]]; }; then
  antidote bundle <~/.zsh_plugins >|~/.zsh_plugins.zsh
fi

# Load the static bundle
[[ -f ~/.zsh_plugins.zsh ]] && source ~/.zsh_plugins.zsh

# Completion
autoload -Uz compinit && compinit

# Aliases
alias grep='grep --color=auto'
alias q='exit;'
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'
alias ll='ls -FGlAhp'
alias ls="eza --no-filesize --no-permissions --long --color=always --icons=always --no-user -a"
alias cd='z'
alias lg="lazygit"
alias ld="lazydocker"
alias rm_node='rm -rf node_modules package-lock.json'

EOF
fi

# ================================
# CREATE .zsh_plugins
# ================================

ZSHRC_PLUGINS="$HOME/.zsh_plugins"
if [[ ! -f "$ZSHRC_PLUGINS" ]]; then

  echo "📝 Creating .zsh_plugins..."
  cat <<EOF >"$ZSHRC_PLUGINS"
zsh-users/zsh-completions
ajeetdsouza/zoxide path:zoxide.plugin.zsh
sindresorhus/pure
junegunn/fzf path:shell kind:defer
lukechilds/zsh-nvm kind:defer
zsh-users/zsh-autosuggestions kind:defer
aloxaf/fzf-tab kind:defer
zsh-users/zsh-syntax-highlighting kind:defer
EOF

fi

# ================================
# ⚠️ SYSTEM SH REPLACEMENT
# ================================
if [[ "$FORCE_REPLACE_SH" == true ]]; then
  echo "⚠️⚠️⚠️ FORCING /bin/sh to use zsh ⚠️⚠️⚠️"
  echo "This may BREAK system scripts."

  sudo ln -sf "$(which zsh)" /bin/sh
else
  echo "✅ Keeping /bin/sh as system default (recommended)"
fi

# ================================
# DONE
# ================================
echo "✅ Zsh installation complete!"
echo "➡️ Log out and log back in to start using zsh."
