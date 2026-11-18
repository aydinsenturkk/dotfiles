load test_helper

# Checks both that macos.sh writes the key and that the machine has the right value.
# Checking the value alone is not enough: the preferences are already set, so the test would pass without macos.sh.
check() {
  local domain=$1 key=$2 want=$3
  grep -qE "^defaults write $domain \"?$key\"? " "$REPO/macos.sh" || { echo "macos.sh does not write: $domain $key"; return 1; }
  local got; got=$(defaults read "$domain" "$key")
  [ "$got" = "$want" ] || { echo "$domain $key: $got (expected $want)"; return 1; }
}

# Dock
@test "com.apple.dock autohide = 1" { check com.apple.dock autohide 1; }
@test "com.apple.dock tilesize = 29" { check com.apple.dock tilesize 29; }
@test "com.apple.dock show-recents = 0" { check com.apple.dock show-recents 0; }
@test "com.apple.dock mru-spaces = 0" { check com.apple.dock mru-spaces 0; }
@test "com.apple.dock wvous-br-corner = 1" { check com.apple.dock wvous-br-corner 1; }

# Finder
@test "com.apple.finder FXPreferredViewStyle = Nlsv" { check com.apple.finder FXPreferredViewStyle Nlsv; }
@test "com.apple.finder FXPreferredSearchViewStyle = Nlsv" { check com.apple.finder FXPreferredSearchViewStyle Nlsv; }
@test "com.apple.finder NewWindowTarget = PfDe" { check com.apple.finder NewWindowTarget PfDe; }
@test "com.apple.finder FXDefaultSearchScope = SCcf" { check com.apple.finder FXDefaultSearchScope SCcf; }
@test "com.apple.finder ShowExternalHardDrivesOnDesktop = 0" { check com.apple.finder ShowExternalHardDrivesOnDesktop 0; }
@test "com.apple.finder ShowRemovableMediaOnDesktop = 0" { check com.apple.finder ShowRemovableMediaOnDesktop 0; }
@test "com.apple.finder FXPreferredGroupBy = Name" { check com.apple.finder FXPreferredGroupBy Name; }
@test "com.apple.finder ShowPathbar = 1" { check com.apple.finder ShowPathbar 1; }
@test "NSGlobalDomain AppleShowAllExtensions = 1" { check NSGlobalDomain AppleShowAllExtensions 1; }
@test "com.apple.desktopservices DSDontWriteNetworkStores = 1" { check com.apple.desktopservices DSDontWriteNetworkStores 1; }
@test "com.apple.desktopservices DSDontWriteUSBStores = 1" { check com.apple.desktopservices DSDontWriteUSBStores 1; }

# Trackpad and typing
@test "com.apple.AppleMultitouchTrackpad Clicking = 1" { check com.apple.AppleMultitouchTrackpad Clicking 1; }
@test "com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking = 1" { check com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking 1; }
@test "NSGlobalDomain com.apple.trackpad.scaling = 2" { check NSGlobalDomain com.apple.trackpad.scaling 2; }
@test "NSGlobalDomain NSAutomaticCapitalizationEnabled = 0" { check NSGlobalDomain NSAutomaticCapitalizationEnabled 0; }
@test "NSGlobalDomain NSAutomaticSpellingCorrectionEnabled = 0" { check NSGlobalDomain NSAutomaticSpellingCorrectionEnabled 0; }
@test "NSGlobalDomain KeyRepeat = 2" { check NSGlobalDomain KeyRepeat 2; }
@test "NSGlobalDomain InitialKeyRepeat = 15" { check NSGlobalDomain InitialKeyRepeat 15; }

# Appearance and windows
@test "NSGlobalDomain AppleInterfaceStyle = Dark" { check NSGlobalDomain AppleInterfaceStyle Dark; }
@test "com.apple.WindowManager EnableTiledWindowMargins = 0" { check com.apple.WindowManager EnableTiledWindowMargins 0; }
@test "com.apple.WindowManager HideDesktop = 1" { check com.apple.WindowManager HideDesktop 1; }

@test "bootstrap --macos runs macos.sh" {
  grep -q 'macos.sh' "$REPO/bootstrap.sh"
  run "$REPO/bootstrap.sh" --help
  [[ "$output" == *--macos* ]] || { echo "$output"; false; }
}
