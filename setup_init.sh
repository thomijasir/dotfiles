#!/bin/bash
set -e

# ==============================================================================
# CONFIGURATION
# ==============================================================================
DOTFILES_ROOT=~/Workspace/dotfiles
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# State tracking
declare -a PENDING_TASKS_DESC
declare -a PENDING_TASKS_CMD

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

add_task() {
  local desc="$1"
  local cmd="$2"
  PENDING_TASKS_DESC+=("$desc")
  PENDING_TASKS_CMD+=("$cmd")
}

command_exists() {
  command -v "$1" &>/dev/null
}

# ==============================================================================
# CHECK & PREPARE FUNCTIONS
# ==============================================================================

check_macos_settings() {
  # Check if hidden files are shown
  local current_setting=$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null || echo "NO")
  if [ "$current_setting" != "YES" ]; then
    add_task "Enable showing hidden files in Finder" "defaults write com.apple.finder AppleShowAllFiles YES"
  fi
}

check_directories() {
  if [ ! -d "$HOME/.config" ]; then
    add_task "Create ~/.config directory" "mkdir -p ~/.config"
  fi
}

check_symlinks() {
  local src="$1"
  local dest="$2"

  # Expand tilde in dest
  dest="${dest/#\~/$HOME}"

  if [ -L "$dest" ]; then
    local current_target=$(readlink "$dest")
    if [ "$current_target" != "$src" ]; then
      add_task "Update symlink $dest -> $src" "ln -sf $src $dest"
    fi
  elif [ -e "$dest" ]; then
    add_task "Backup existing $dest and link to $src" "mv $dest $dest.backup && ln -sf $src $dest"
  else
    add_task "Create symlink $dest -> $src" "ln -sf $src $dest"
  fi
}

safe_brew_install() {
  local pkg="$1"
  local is_cask="$2"

  if [ "$is_cask" == "true" ]; then
    # log_info "Installing Cask: $pkg" # Redundant with main execution log
    brew install --cask "$pkg"
    
    # Verify installation
    if ! brew list --cask "$pkg" &>/dev/null; then
      log_error "Verification failed: $pkg (Cask) was not found after installation."
      return 1
    fi
  else
    # log_info "Installing Formula: $pkg" # Redundant with main execution log
    brew install "$pkg"
    
    # Verify installation
    if ! brew list "$pkg" &>/dev/null; then
      log_error "Verification failed: $pkg (Formula) was not found after installation."
      return 1
    fi
  fi
  
  log_success "Verified installation of $pkg"
  sleep 2 # Brief pause to ensure system settles and release locks
}

check_brew_package() {
  local pkg="$1"
  local is_cask="$2"

  log_info "Brew package check $pkg"
  if [ "$is_cask" == "true" ]; then
    if ! brew list --cask "$pkg" &>/dev/null; then
      add_task "Install Cask: $pkg" "safe_brew_install \"$pkg\" \"true\""
    else
     log_info "Package $pkg (Cask) was installed"
    fi
  else
    if ! brew list "$pkg" &>/dev/null; then
      add_task "Install Formula: $pkg" "safe_brew_install \"$pkg\" \"false\""
    else
      log_info "Package $pkg (Formula) was installed"
    fi
  fi
}

check_rust() {
  log_info "Checking rust environment"
  if ! command_exists rustup; then
    add_task "Install Rust (rustup)" "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
  else
    add_task "Update Rust" "rustup update"
  fi

  # Components
  add_task "Add rust-analyzer component" "rustup component add rust-analyzer"
  add_task "Install cargo-watch" "cargo install cargo-watch"
}

check_rvm() {
  log_info "Checking ruby manager"
  if [ ! -d "$HOME/.rvm" ]; then
    add_task "Install GPG Keys" "sudo gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB"
    add_task "Install RVM (Ruby Version Manager)" "curl -sSL https://get.rvm.io | bash -s stable"
  else
    add_task "Update RVM" "rvm get stable"
  fi
}

check_nvm() {
  log_info "Checking node version manager"
  add_task "Install latest Node.js via NVM" '
    export NVM_DIR="$HOME/.nvm" && (
    rm -rf "$NVM_DIR"
    git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
    cd "$NVM_DIR"
    git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
    ) && \. "$NVM_DIR/nvm.sh"
    nvm install node
    nvm use node
    nvm alias default node
  '
}

check_fvm() {
  log_info "Checking flutter version manager"
  # User uses fvm for dart/flutter
  check_brew_package "fvm" "false"

  # FVM setup usually requires installing a flutter version
  add_task "Setup Flutter via FVM (stable)" '
        fvm install stable
        fvm global stable
    '
}

check_pyenv() {
  log_info "Checking python environment manager"
  check_brew_package "pyenv" "false"
  # Install a recent python version if none global
  add_task "Install Python 3.12 via Pyenv (if missing)" '
        if ! pyenv versions | grep -q "3.12"; then
            pyenv install 3.12.1
            pyenv global 3.12.1
        fi
    '
}

check_zsh_config_alignment() {
  # Check if .zprofile.default has necessary exports
  local zshrc="$DOTFILES_ROOT/zshrc/.zshrc"

  # NVM Check
  if ! grep -q "NVM_DIR" "$zshrc"; then
    log_warn "NVM configuration missing in zsh files. Suggest adding lazy loading:"
  fi

  # Pyenv Check
  if ! grep -q "pyenv init" "$zshrc"; then
    log_warn "Pyenv configuration missing in zsh files. Suggest adding safe init:"
    echo 'if command -v pyenv 1>/dev/null 2>&1; then eval "$(pyenv init -)"; fi'
  fi
}

# ==============================================================================
# MAIN LOGIC
# ==============================================================================

main() {
  echo -e "${CYAN}========================================${NC}"
  echo -e "${CYAN}   MacOS Setup Automation Script        ${NC}"
  echo -e "${CYAN}========================================${NC}"

  # 0. Pre-checks
  # Check for Homebrew
  if ! command -v brew &>/dev/null; then
    log_error "Homebrew is not installed. Please install Homebrew first."
    echo -e "Run: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
  fi

  # Request sudo permission
  log_info "Requesting sudo permissions..."
  sudo -v
  # Keep-alive: update existing `sudo` time stamp until script has finished
  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2>/dev/null &

  # 1. MacOS Defaults
  check_macos_settings
  check_directories

  # 2. Symlinks
  check_symlinks "$DOTFILES_ROOT/zshrc/.zshrc" "~/.zshrc"
  check_symlinks "$DOTFILES_ROOT/zshrc/.zsh_plugins" "~/.zsh_plugins"
  check_symlinks "$DOTFILES_ROOT/zshrc/.zsh_aliases" "~/.zsh_aliases"
  
  check_symlinks "$DOTFILES_ROOT/wezterm/.wezterm.lua" "~/.wezterm.lua"
  check_symlinks "$DOTFILES_ROOT/yazi" "~/.config/yazi"
  # Ensure parent dir exists for lazygit
  add_task "Ensure lazygit config dir exists" "mkdir -p ~/Library/Application\ Support/lazygit"
  check_symlinks "$DOTFILES_ROOT/lazygit/config.yml" "~/Library/Application\ Support/lazygit/config.yml"

  # 3. Homebrew & Taps
  add_task "Update and Upgrade Homebrew" "brew update && brew upgrade"
  add_task "Tap leoafarias/fvm" "brew tap leoafarias/fvm"

  # 4. Core Languages & Managers
  check_rust
  check_rvm
  check_nvm
  check_fvm
  check_pyenv

  # 5. Brew Packages
  # Basic Tools
  local casks=(
    "wezterm" "google-chrome" "visual-studio-code" "bruno" "pgadmin4"
    "notion" "microsoft-teams" "obs" "audacity" "android-studio"
    "zoom" "whatsapp" "docker" "font-jetbrains-mono-nerd-font"
    "font-fira-code-nerd-font"
  )

  local formulas=(
    "deno" "font-symbols-only-nerd-font"
    "harper" "shfmt" "yaml-language-server" "dprint"
    "helix" "neovim" "wget" "openjdk@17" "yazi" "sevenzip"
    "jq" "yq" "fd" "ripgrep" "fzf" "bat" "lazygit" "lazydocker"
    "lazysql" "tig" "eza" "zoxide" "fswatch" "htop" "antidote"
    "mozjpeg" "ffmpeg" "imagemagick" "pngquant" "poppler"
  )

  for cask in "${casks[@]}"; do check_brew_package "$cask" "true"; done
  for formula in "${formulas[@]}"; do check_brew_package "$formula" "false"; done

  # 6. Dprint Init
  if [ ! -f "$HOME/.dprint.json" ]; then
    add_task "Initialize dprint config" "dprint init -c ~/.dprint.json"
  fi

  # 7. NPM Global Packages (LSPs & Formatters)
  local npm_package=(
    "typescript-language-server" "typescript" "vscode-langservers-extracted"
    "emmet-ls" "prettier" "@postgrestools/postgrestools" "sql-formatter"
    "bash-language-server" "mdts" "@vlabo/cspell-lsp" "@tailwindcss/language-server"
    "eslint_d" "@google/gemini-cli" "@anthropic-ai/claude-code"
  )
  add_task "Install essential node package" 'npm install -g "${npm_package[@]}"'

  # ==========================================================================
  # DRY RUN
  # ==========================================================================
  echo -e "\n${YELLOW}--- DRY RUN: The following tasks will be executed ---${NC}"
  if [ ${#PENDING_TASKS_DESC[@]} -eq 0 ]; then
    echo "No tasks to perform. System is up to date."
    exit 0
  fi

  for i in "${!PENDING_TASKS_DESC[@]}"; do
    echo -e "${BLUE}[$((i + 1))]${NC} ${PENDING_TASKS_DESC[$i]}"
    # echo -e "    CMD: ${PENDING_TASKS_CMD[$i]}" # Optional: show command
  done

  # Check ZSH Alignment
  echo -e "\n${YELLOW}--- Configuration Check ---${NC}"
  check_zsh_config_alignment

  # ==========================================================================
  # INTERACTIVE PROMPT
  # ==========================================================================
  echo -e "\n"
  read -p "Do you want to proceed with these changes? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warn "Operation cancelled by user."
    exit 1
  fi

  # ==========================================================================
  # EXECUTION
  # ==========================================================================
  echo -e "\n${GREEN}--- Executing Tasks ---${NC}"

  local total_tasks=${#PENDING_TASKS_DESC[@]}
  for i in "${!PENDING_TASKS_DESC[@]}"; do
    desc="${PENDING_TASKS_DESC[$i]}"
    cmd="${PENDING_TASKS_CMD[$i]}"
    local current_task=$((i + 1))

    log_info "[$current_task/$total_tasks] Executing: $desc"
    if eval "$cmd"; then
      log_success "Done"
    else
      log_error "Failed: $desc"
      read -p "Continue? (y/N) " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
      fi
    fi
    # 👇 Safe execution between task
    sleep 0.5
  done

  echo -e "\n${GREEN}All tasks completed!${NC}"
  echo -e "Please restart your terminal or run 'source ~/.zshrc' to apply changes."
}

main
