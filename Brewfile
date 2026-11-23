# Brewfile — installed by ./bootstrap.sh brew.
# Rule: only tools that are actually used. To add something, add a line here and run
# `brew bundle --no-upgrade --file=~/Github/dotfiles/Brewfile` (or `./bootstrap.sh brew`).
# Language versions (Node, pnpm, Go, Bun) are not here but in mise: home/mise/.config/mise/config.toml

# Taps
tap "momenbasel/pesty"          # Pesty; not in the main cask repo

# Core CLI
brew "stow"                     # symlinks the dotfiles into ~
brew "gitleaks"                 # secret scan before each commit
brew "bats-core"                # dotfiles tests
brew "gh"                       # GitHub CLI; git authentication goes through it too
brew "mise"                     # language versions
brew "uv"                       # Python interpreters and virtual environments

# Shell
brew "starship"                 # prompt
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "zsh-completions"
brew "fzf"                      # Ctrl+R history search
brew "zoxide"                   # jump with `z <dir>`
brew "eza"                      # instead of ls / tree
brew "bat"                      # instead of cat
brew "fd"                       # instead of find
brew "ripgrep"                  # instead of grep
brew "git-delta"                # colored, line-numbered git diffs in the terminal
brew "neovim"                   # terminal editor (EDITOR); config in home/nvim
brew "tree-sitter-cli"          # compiles the parsers Neovim uses for highlighting

# Development
brew "awscli"
brew "libpq"                    # psql, pg_dump; the Postgres server runs in the project's container
brew "mongosh"
brew "helm"
brew "golang-migrate"           # the `migrate` command
brew "mkcert"                   # local HTTPS certificates
brew "cocoapods"                # React Native/Expo iOS builds; no separate Ruby install
brew "watchman"                 # React Native Metro file watcher
cask "ngrok"

# Media and documents
brew "ffmpeg"
brew "pandoc"
cask "basictex"                 # LaTeX for PDF output with pandoc

# Apps
cask "visual-studio-code"       # editor; settings and extensions come from Settings Sync
cask "ghostty"                  # terminal
cask "momenbasel/pesty/pesty"   # clipboard history on Shift+Cmd+V (Paste-style strip)
cask "rectangle"                # window snapping with keyboard shortcuts
cask "orbstack"                 # container and Kubernetes engine
cask "tableplus"                # database GUI
cask "fork"                     # git GUI
cask "cyberduck"                # FTP/SFTP
cask "transmission"             # torrent
cask "google-chrome"
cask "firefox"
cask "firefox@developer-edition"
cask "figma"
cask "clickup"
cask "lm-studio"
cask "claude"
cask "appcleaner"
cask "anydesk"
cask "bambu-studio"
cask "cloudflare-warp"
cask "google-drive"
cask "logi-options+"
cask "spotify"
