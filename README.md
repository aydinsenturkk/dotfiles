# dotfiles

Personal setup for an Apple Silicon Mac: zsh, Homebrew, mise, uv, Ghostty and macOS preferences. Config files are
linked into `~` with GNU Stow, and everything is covered by tests.

## Principles

- Only tools that are actually used.
- Everything native (arm64): no Rosetta, no Intel Homebrew.
- No secrets in the repo; a gitleaks pre-commit hook checks every commit.
- One command sets up a new Mac, and running it again changes nothing.
- A fast shell: startup under 200 ms.

## What's inside

| Path | What it does |
| --- | --- |
| `bootstrap.sh` | Single entry point (see below) |
| `Brewfile` | CLI tools and apps |
| `macos.sh` | Dock, Finder, trackpad, keyboard, appearance and window preferences |
| `.githooks/` | gitleaks pre-commit hook |
| `home/zsh` | `.zshenv`, `.zprofile` (Homebrew, PATH, mise shims, OrbStack), `.zshrc` (history, completion, fzf, zoxide, mise, Starship, plugins), aliases, `.hushlogin` |
| `home/git` | `~/.config/git/config` (identity, GitHub credentials via gh), global ignore |
| `home/ghostty` | Ghostty: GitHub Dark Default, JetBrains Mono 16, roomy spacing |
| `home/starship` | Prompt |
| `home/mise` | Node LTS, pnpm, Go, Bun, yarn 1, NestJS CLI |
| `tests/` | bats tests |

Each folder under `home/` is a Stow package whose contents mirror `~`.

## Requirements

- An Apple Silicon Mac with macOS 15 or later.
- An admin account: Homebrew and some apps ask for your password.

## Install on a new Mac

> **These are my settings.** To use them, fork the repo, change `[user]` in `home/git/.config/git/config`,
> review the `Brewfile` and `macos.sh`, then clone your fork instead.

```zsh
xcode-select --install   # git and compilers; wait until the installer window finishes
git clone https://github.com/aydinsenturkk/dotfiles.git ~/Github/dotfiles   # any path works; don't move it after linking
cd ~/Github/dotfiles
./bootstrap.sh --macos
```

When it finishes, **open a new terminal window**: Homebrew, mise and the new shell config only load there.

The steps run in order, and each one is skipped if it is already done:

| Step | What it does |
| --- | --- |
| `clt` | Xcode Command Line Tools (if the installer opens, run bootstrap again when it finishes) |
| `brew` | Homebrew in `/opt/homebrew`, then the `Brewfile` (installs what is missing, never upgrades) |
| `link` | Symlinks the packages under `home/` into `~` (stow `--no-folding`). Existing files are moved to `~/.dotfiles-backup/<time>/`, never deleted |
| `runtimes` | `mise install` and `uv python install --default` |
| `hooks` | Enables the gitleaks pre-commit hook |
| `--macos` | Runs `macos.sh` at the end |

One step or one package: `./bootstrap.sh link`, `./bootstrap.sh link zsh git`, `./bootstrap.sh --help`.

After the first run:

1. `gh auth login` (git uses it for GitHub).
2. Fill in `~/.zshrc.local` (see [Secrets](#secrets)).
3. Install the App Store apps (Xcode, TestFlight, iWork, password manager, chat apps).
4. Sign in to VS Code Settings Sync; settings and extensions come from there.
5. Open OrbStack once (Docker and Kubernetes).

## Daily use

- Files such as `~/.zshrc` are symlinks into this repo, so editing them edits the repo. Review with `git diff`, then commit.
- **New tool:** add a line to the `Brewfile` and run `./bootstrap.sh brew` (installs what is missing, never upgrades).
  Updates are explicit: `brew upgrade`. To list what is no longer in the Brewfile: `brew bundle cleanup --file=…` (`--force` removes it).
- **Language versions (mise):** global versions live in `home/mise/.config/mise/config.toml`; `mise upgrade` updates them.
  Per project: `mise use node@24` (writes `mise.toml`); `.nvmrc` and `.node-version` are read too.
- **Python (uv):** `uv venv`, `uv pip install …`, `uv run …`; another version with `uv python install 3.x`.
- **AWS accounts:** keep no default profile in `~/.aws/config`, so `aws` fails instead of silently using some account.
  Each account is a named profile in `~/.aws/config` (`[profile client-a]`). In the project folder, create `mise.local.toml` with
  `AWS_PROFILE = "client-a"` under `[env]`, then run `mise trust`. Entering the folder selects the profile and leaving clears it;
  the prompt shows the active profile and region. `mise.local.toml` is in the global git ignore, so it never gets committed.
- **Ghostty config:** open it with Cmd+, (it is the repo file), save, then Ghostty menu → Reload Configuration. Spacing changes only show in a new window.
  Don't create a separate config under `~/.config/ghostty/`.
- **macOS preferences:** add a `defaults write` line to `macos.sh` and run `./macos.sh`.
- **Machine-specific settings:** `~/.zshrc.local` (not in the repo, loaded last).

## Secrets

Nothing secret lives in the repo, not even file names; gitleaks scans every commit. A password manager is the source of
truth. On a new Mac, restore:

- machine-specific environment variables in `~/.zshrc.local` (`chmod 600`);
- token and key files in `~` and keys in `~/.ssh`, under the same names;
- GitHub: `gh auth login` (the token lives in the macOS keychain). AWS: `~/.aws` (`aws configure`).

## Tests

On any Mac (safe: nothing in your `~` changes):

```zsh
bats tests/{repo,link,zsh,git,readme,brewfile}.bats
```

On a Mac set up with this repo, `bats tests/` runs everything. `tests/macos.bats` and `tests/tools.bats` compare against
the machine's actual state. `tests/verify.bats` checks the real home: shell startup under 200 ms, arm64 binaries, git
identity, Docker on OrbStack, the Ghostty config location and no secrets in the git history. **It also runs
`bootstrap.sh link` on the real `~`**, so never run it on a Mac this repo hasn't set up.

## Troubleshooting

- Slow shell: `time zsh -i -c exit`. For details, temporarily add `zmodload zsh/zprof` as the first line of `~/.zshrc`
  and `zprof` as the last, then open a new shell.
- `brew bundle check --file=Brewfile`: is everything in the Brewfile installed?
- compinit warns about insecure directories: `chmod go-w /opt/homebrew/share` (`./bootstrap.sh brew` does this).
- Old config files that were moved aside: `~/.dotfiles-backup/`.

## License

[MIT](LICENSE)
