#!/bin/bash
set -e

echo "📦 Installing Node.js via NVM..."

export NVM_DIR="$HOME/.nvm"

if [ ! -d "$NVM_DIR" ]; then
	echo "Cloning NVM repository..."
	rm -rf "$NVM_DIR"
	git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
	cd "$NVM_DIR"
	git checkout $(git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1))
fi

echo "Loading NVM..."
. "$NVM_DIR/nvm.sh"

echo "Installing latest Node.js..."
nvm install node
nvm use node
nvm alias default node

echo ""
echo "📦 Installing global npm packages..."

NPM_PACKAGES=(
	typescript-language-server
	typescript
	vscode-langservers-extracted
	emmet-ls
	prettier
	@postgrestools/postgrestools
	sql-formatter
	bash-language-server
	mdts
	@vlabo/cspell-lsp
	@tailwindcss/language-server
	eslint_d
	@google/gemini-cli
	@anthropic-ai/claude-code
)

for package in "${NPM_PACKAGES[@]}"; do
	echo "  [+] Installing $package..."
	npm install -g "$package"
done

echo ""
echo "✅ Node.js and npm packages installed!"
