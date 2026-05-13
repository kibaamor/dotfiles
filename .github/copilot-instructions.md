# Copilot instructions for this repository

## Build, test, and lint commands

- Generate output for review from a chezmoi template without applying changes:
  `chezmoi --source /home/k/repos/dotfiles execute-template < home/.chezmoi.yaml.tmpl`
- Preview what chezmoi would change on the current machine:
  `chezmoi --source /home/k/repos/dotfiles diff`
- Apply the dotfiles locally:
  `chezmoi --source /home/k/repos/dotfiles apply`
- Update pinned external tool versions in `home/.chezmoidata/versions.yaml`:
  `./update-version.sh`
- Lint shell scripts that are not Go templates:
  `shellcheck update-version.sh home/dot_utilities.sh`
- Shell script templates in `home/.chezmoiscripts/*.sh.tmpl` contain Go template directives; render them with `chezmoi execute-template` before running shellcheck.
- Build the base devcontainer image locally from the default config:
  `devcontainer build --workspace-folder .`
- Build a language-specific devcontainer:
  `devcontainer build --workspace-folder . --config .devcontainer/node/devcontainer.json`

There is no standalone application test suite in this dotfiles repo. For a single-file validation, generate output for review or diff the specific chezmoi template being changed rather than applying the full source tree. If a script, build, or template command fails, report the failing command, summarize the relevant error output, and suggest the smallest corrective action.

## High-level architecture

- This is a chezmoi dotfiles repo. `.chezmoiroot` points at `home/`, so files under `home/` map to the target home directory. Chezmoi special names are used throughout, such as `dot_zshrc.tmpl` for `~/.zshrc`, `private_helix/` for private config directories, `create_empty_dot_gitconfig-*` for empty include files, and `.chezmoiscripts/run_onchange_*` for lifecycle scripts.
- `home/.chezmoi.yaml.tmpl` is the central data/bootstrap template. It derives flags from environment variables (`DOTFILES_INSTALL_EXTRA_BINS`, `DOTFILES_INSTALL_ARKADE_BINS`, `DOTFILES_USE_CDN`, `DOTFILES_CAN_SUDO`, `DOTFILES_NONPERSONAL`, git identity variables) and exposes normalized values used by other templates, including OS-specific archive suffixes, executable extensions, GitHub URL prefixes, and sudo capability.
- `home/.chezmoidata/` holds structured data consumed by templates: package lists, external tool versions, and Windows optional features. Keep version keys aligned with names used in `.chezmoiexternal.yaml.tmpl`; `update-version.sh` generates release keys from the GitHub repo name with hyphens removed.
- `home/.chezmoiexternal.yaml.tmpl` downloads most third-party binaries and external config archives into the target home directory. It gates Linux/macOS-only assets with `if ne .chezmoi.os "windows"` and gates optional Kubernetes/container tools behind `.extra_bins` and `.arkade_bins`.
- Install-time side effects live in `home/.chezmoiscripts/`: Debian/CentOS package installation runs before apply, Vim plugin setup and zsh shell switching run after apply, and Windows scripts configure PATH, git/proxy settings, winget/scoop packages, Explorer preferences, and optional Windows features.
- The devcontainer setup builds on this dotfiles install flow. `.devcontainer/Dockerfile` installs the dotfiles into an Ubuntu image with extra and arkade binaries enabled, then `.github/workflows/devcontainers.yml` publishes the base image and the Node/Go variants defined under `.devcontainer/node/` and `.devcontainer/golang/`.

## Key conventions

1. Template editing: preserve chezmoi template delimiters and whitespace trimming (`{{- ... -}}`) when editing `.tmpl` files; many files intentionally avoid emitting blank lines around OS-gated blocks.
2. Formatting: follow `.editorconfig`: two-space indentation for YAML/JSON/templates/shell, four spaces by default, LF line endings except PowerShell scripts which use CRLF and UTF-8 BOM rules.
3. OS behavior: keep OS-specific behavior gated with `.chezmoi.os`, `.chezmoi.osRelease`, `.interactive`, and `.can_sudo` rather than adding unconditional package installs or shell changes.
4. Versions: do not duplicate version literals in templates. Add or update entries in `home/.chezmoidata/versions.yaml` and reference them as `.versions.<key>`.
5. External binaries: update all related surfaces together: README installed-binary lists, `update-version.sh` repo list, `home/.chezmoidata/versions.yaml`, and `home/.chezmoiexternal.yaml.tmpl`.
6. Proxy and CDN support: use `.github_url_prefix` for GitHub-hosted downloads and preserve `default_proxy`/`default_no_proxy` handling in shell and Windows profile scripts.
7. Git identity: generated global config and include files are split between GitHub/GitLab/proxy. Keep `create_empty_dot_gitconfig-*`, `dot_gitconfig.tmpl`, and shell/PowerShell runtime updates consistent.
8. Zsh startup: `dot_zshrc.tmpl` is intentionally defensive. Most integrations are loaded only when commands exist, custom hooks are sourced from `~/.customrc.pre.sh` and `~/.customrc.post.sh`, and the file ends with a successful return for sourced-shell compatibility.
