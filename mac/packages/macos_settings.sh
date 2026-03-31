#!/bin/bash

echo "⚙️  Applying macOS settings..."

echo ""
echo "  Enabling showing hidden files in Finder..."
defaults write com.apple.finder AppleShowAllFiles YES

echo "  Setting Finder to show path bar..."
defaults write com.apple.finder ShowPathbar -bool true

echo "  Setting Finder to show status bar..."
defaults write com.apple.finder ShowStatusBar -bool true

echo "  Enabling smooth scrolling..."
defaults write NSGlobalDomain NSScrollAnimationEnabled -bool true

echo "  Expanding save dialog by default..."
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true

echo "  Expanding print panel by default..."
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true

echo "  Disabling automatic termination of inactive apps..."
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

echo "  Allowing text selection in Quick Look..."
defaults write com.apple.finder QLEnableTextSelection -bool true

echo "  Checking disk permission..."
if [ ! -f "/usr/bin/diskutil" ]; then
	echo "  [!] Warning: diskutil not found"
fi

echo ""
echo "✅ macOS settings applied!"
echo ""
echo "Note: Some changes may require restarting Finder."
echo "Run 'killall Finder' to restart Finder."
