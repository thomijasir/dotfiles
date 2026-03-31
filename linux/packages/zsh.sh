#!/bin/bash
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
export ZDOTDIR=\$HOME
export PATH="\$HOME/bin:\$PATH"

# Enable Antidote
source $ANTIDOTE_DIR/antidote.zsh

# Load plugins
antidote load <<'PLUGINS'
zsh-users/zsh-autosuggestions
zsh-users/zsh-syntax-highlighting
zsh-users/zsh-completions
PLUGINS

# Completion
autoload -Uz compinit && compinit

# History
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY

# Prompt
autoload -Uz promptinit
promptinit
prompt pure

# Aliases
alias ls='ls --color=auto'
alias ll='ls -lah'
alias grep='grep --color=auto'

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
