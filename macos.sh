#!/bin/zsh
# macOS preferences. Safe to re-run: every line writes one setting to its desired value.
#   ./macos.sh              or   ./bootstrap.sh --macos
# Key repeat and trackpad settings take full effect after logging out and back in.

setopt err_exit no_unset pipe_fail

# Dock
defaults write com.apple.dock autohide -bool true                 # auto-hide
defaults write com.apple.dock tilesize -int 29                    # icon size
defaults write com.apple.dock show-recents -bool false            # no recent apps
defaults write com.apple.dock mru-spaces -bool false              # don't rearrange Spaces by recent use
defaults write com.apple.dock wvous-br-corner -int 1              # bottom-right hot corner off (default: Quick Note)

# Finder
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv           # list view
defaults write com.apple.finder FXPreferredSearchViewStyle -string Nlsv     # search results as a list too
defaults write com.apple.finder NewWindowTarget -string PfDe                # new windows open the Desktop
defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/Desktop/"
defaults write com.apple.finder FXDefaultSearchScope -string SCcf           # search the current folder
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false # no external drives on the desktop
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false     # no USB/SD on the desktop
defaults write com.apple.finder FXPreferredGroupBy -string Name             # group by name
defaults write com.apple.finder ShowPathbar -bool true                      # folder path at the bottom of windows
defaults write NSGlobalDomain AppleShowAllExtensions -bool true             # show all file extensions
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true # no .DS_Store on network shares
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true     # no .DS_Store on USB drives

# Trackpad and typing
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true                 # tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true # (Magic Trackpad)
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2                     # pointer speed
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false            # no auto-capitalization
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false        # no autocorrect
defaults write NSGlobalDomain KeyRepeat -int 2                                        # fast key repeat
defaults write NSGlobalDomain InitialKeyRepeat -int 15                                # short delay before repeat

# Appearance and windows
defaults write NSGlobalDomain AppleInterfaceStyle -string Dark                # dark mode
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false   # no margins between tiled windows
defaults write com.apple.WindowManager HideDesktop -bool true                 # hide desktop items

# Apply the changes (open Finder windows are reopened).
killall Dock Finder SystemUIServer 2>/dev/null || true
print -P "%F{green}==>%f macos: preferences written"
