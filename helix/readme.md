# Helix Editor Configuration

This is a custom Helix configuration with opinionated keybindings and settings optimized for productivity.

## Important Note - Helix Preparation

### Install Language Server Protocol (LSP) Services

```sh
# Essential language services (must install)
npm install -g typescript-language-server typescript vscode-langservers-extracted emmet-ls prettier @postgrestools/postgrestools sql-formatter bash-language-server

# dprint formatter
curl -fsSL https://dprint.dev/install.sh | sh

# Deno service for TypeScript files
curl -fsSL https://deno.land/x/install/install.sh | sh

# Grammar and language server check
brew install harper shfmt yaml-language-server

# Install and check Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup component add rust-analyzer
command -v rust-analyzer
```

---

## Editor Features

- **Theme**: `sonokai_custom`
- **Relative line numbers** with cursorline and cursorcolumn
- **Bufferline** always visible
- **LSP enabled** with snippets support
- **Auto-pairs** for brackets and quotes
- **Soft-wrap** enabled
- **Indent guides** with custom character `┊`
- **Jump labels**: `jfkdls;aurieowpqnvmcxz`

---

## Cheat Sheet & Keymaps

### 🎯 Navigation

#### Word Navigation
- `*` - Select current word and jump to next occurrence
- `#` - Select current word and jump to previous occurrence
- `n` - Next search match
- `N` - Previous search match

#### Paragraph Navigation
- `}` - Go to next paragraph
- `{` - Go to previous paragraph

#### View/Window Navigation
- `Ctrl+j` - Jump view down
- `Ctrl+k` - Jump view up
- `Ctrl+h` - Jump view left
- `Ctrl+l` - Jump view right

---

### 📝 Normal Mode

#### File Operations
- `Ctrl+s` - Format and save current file
- `Ctrl+r` - Reload file
- `Ctrl+e` - Open Yazi file manager
- `Ctrl+g` - Open Lazygit

#### Clipboard Operations
- `y` - Yank (copy) to system clipboard
- `Y` - Yank entire line to system clipboard
- `D` - Delete line and copy to clipboard

#### Buffer Management
- `H` - Go to previous buffer
- `L` - Go to next buffer
- `,` - Open buffer picker

#### Selection
- `V` - Enter visual mode (select line)
- `Shift+Up` - Extend selection up one line
- `Shift+Down` - Extend selection down one line

#### Window Management (Space prefix)
- `Space Space` - File picker in current directory
- `Space |` - Vertical split
- `Space -` - Horizontal split
- `Space q` - Close window
- `Space l` - Toggle LSP inlay hints

#### Buffer Commands (Space b prefix)
- `Space b b` - Buffer picker
- `Space b d` - Close current buffer
- `Space b D` - Force close current buffer
- `Space b o` - Close other buffers
- `Space b O` - Force close other buffers
- `Space b a` - Close all buffers
- `Space b A` - Force close all buffers

---

### ✏️ Insert Mode

- `Ctrl+s` - Format, save, and return to normal mode
- `Escape` - Exit to normal mode

---

### 🎨 Select/Visual Mode

#### Text Objects
- `i` - Select text object inner (e.g., `iw` for inner word)
- `a` - Select text object around (e.g., `aw` for around word)

#### Clipboard
- `y` - Yank selection to clipboard
- `Y` - Yank entire line to clipboard

#### Move Lines
- `Alt+j` - Move selected line(s) down
- `Alt+k` - Move selected line(s) up

#### Selection Extension
- `Shift+Up` - Extend selection up
- `Shift+Down` - Extend selection down

---

## Common Workflows

### Multi-cursor Editing
```
1. Place cursor on word
2. Press `v` to enter select mode
3. Press `*` to select word and jump to next
4. Press `n` repeatedly to add more cursors
5. Press `c` to change text on all cursors
6. Press `,` when done to collapse to single cursor
```

### Moving Lines
```
1. Select line(s) with `V` or `x`
2. Press `Alt+j` to move down or `Alt+k` to move up
```

### Buffer Navigation
```
1. Press `H` to go to previous buffer
2. Press `L` to go to next buffer
3. Press `,` to see all buffers and pick one
```

### Quick File Save
```
1. In normal mode: `Ctrl+s`
2. In insert mode: `Ctrl+s` (also exits to normal mode)
```

---

## Tips

- Use `Space Space` for quick file navigation in current directory
- Use `Ctrl+e` to open Yazi file manager for visual file browsing
- Use `Ctrl+g` to access Git operations through Lazygit
- Remember: `Escape` always returns you to normal mode with collapsed selection
- The `*` key is your friend for multi-cursor workflows

---

## Customization

This configuration can be found at: `~/.config/helix/config.toml`
The custom theme is located at: `~/.config/helix/themes/sonokai_custom.toml`
Feel free to modify keybindings to suit your workflow.
