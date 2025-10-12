# SurrealDB
export PATH=$HOME/.surrealdb:$PATH

export LIBRARY_PATH="/opt/homebrew/lib:$LIBRARY_PATH"
export DYLD_LIBRARY_PATH="/opt/homebrew/lib:$DYLD_LIBRARY_PATH"
# Java Lib Load
#export JAVA_HOME=$(/usr/libexec/java_home)
#export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
#export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"

# ANDROID LIB
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export NDK_HOME="$ANDROID_HOME/ndk/$(ls -1 $ANDROID_HOME/ndk)"

# Flutter
export PATH="$PATH:`pwd`/flutter/bin"
export PATH=$HOME/.gem/bin:$PATH

# IMPROVEMENT
export PATH="$PATH:/usr/local/bin/"
export PATH="/usr/local/git/bin:/sw/bin/:/usr/local/bin:/usr/local/:/usr/local/sbin:/usr/local/mysql/bin:$PATH"

# PYTHON
# export PATH="$HOME/.pyenv/versions/3.9.6/bin:$PATH"
export EDITOR=/opt/homebrew/bin/nvim

# BUN
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Add Visual Studio Code (code)
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"

# Node Version Manager https://github.com/nvm-sh/nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"

# Custom Aliases
alias crw='cargo watch -q -c -w src/ -x run'
alias tencent_sg='ssh -i ~/.ssh-keys/tencent_sg_key.pem root@43.134.91.33'
alias tencent_hk='ssh -i ~/.ssh-keys/tencent_hk_key.pem root@43.159.230.62'
alias auto-translate='python ~/Workspace/minootube/scripts/auto-translate.py'
alias auto-transcribe='python ~/Workspace/minootube/scripts/auto-transcribe.py'
alias video-compress='python ~/Workspace/minootube/scripts/auto-compress.py'
alias androidUp='emulator -avd Pixel_2_API_28'		# Open Emulator	
alias iosUp='open -a Simulator'				# Open Simulator
alias work='cd ~/Workspace'
alias nvim_config='nvim ~/.config/nvim'
alias wezterm_config='nvim ~/.wezterm.lua'
alias zsh_config='nvim ~/.zshrc'
alias zsh_reload='source ~/.zshrc'
alias rm_node='rm -rf node_modules package-lock.json'
#alias py='python3'					# Python Alias
#alias python='python3'					# Python load
#alias pip='pip3'					# Python pip
alias aliyun='ssh root@8.219.9.110 -i ~/aliyun-key.pem' # Aliyun SSH
alias ga='git add .'					            # Git Add
alias gf='git fetch && git pull'			    # Git Fetch And Pull
alias gp='git push'					              # Git Push
alias gs='git status'					            # Git Status
alias gc='f() { git commit -m "$1"; }; f'
alias gb='f() { git checkout -b "$1"; }; f'
alias ngrok="$HOME/.ngrok"				# add ngrok
alias cleadNODE="find . -name 'node_modules' -type d -prune -print -exec rm -rf '{}' \;"
alias cleanupDS="find . -type f -name '*.DS_Store' -ls -delete"	# Auto Clean DS

# Alias tools
alias vim='nvim'
alias ls='ls -n --color=auto'
alias cp='cp -iv'                           		# Preferred 'cp' implementation
alias mv='mv -iv'                           		# Preferred 'mv' implementation
alias mkdir='mkdir -pv'                     		# Preferred 'mkdir' implementation
alias ll='ls -FGlAhp'                       		# Preferred 'ls' implementation
alias temp='nvim ~/temp.md'
# Git zsh Configuration
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '(%b)'
setopt PROMPT_SUBST
PROMPT='${PWD/#$HOME/~} ${vcs_info_msg_0_} '

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f /Users/venobi/.dart-cli-completion/zsh-config.zsh ]] && . /Users/venobi/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# __conda_setup="$('/Users/venobi/miniconda/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
# if [ $? -eq 0 ]; then
#     eval "$__conda_setup"
# else
#     if [ -f "/Users/venobi/miniconda/etc/profile.d/conda.sh" ]; then
#         . "/Users/venobi/miniconda/etc/profile.d/conda.sh"
#     else
#         export PATH="/Users/venobi/miniconda/bin:$PATH"
#     fi
# fi
# unset __conda_setup
# <<< conda initialize <<<

# history setup
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history 
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# completion using arrow keys (based on history)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# syntax auto-completion and highlighting
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

# Added by Windsurf
export PATH="/Users/venobi/.codeium/windsurf/bin:$PATH"
