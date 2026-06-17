# AGENTS.md

Chezmoi dotfiles repo at `kibaamor/dotfiles`. `.chezmoiroot` is `home`, so all files under `home/` map to `~`.

## Commands

```bash
# Preview changes (always do this before applying)
chezmoi --source . diff

# Apply dotfiles locally
chezmoi --source . apply

# Test a template without applying
chezmoi --source . execute-template < home/.chezmoi.yaml.tmpl

# Verify mirror mode for external downloads
DOTFILES_MIRROR=https://cdn.gh-proxy.org chezmoi --source . execute-template < home/.chezmoiexternal.yaml.tmpl | head -30

# Lint shell scripts (not .tmpl files — see below)
shellcheck update-version.sh home/dot_utilities.sh find-gh-mirror.sh

# Find the fastest GitHub mirror (outputs export DOTFILES_MIRROR=...)
./find-gh-mirror.sh

# Update pinned versions and checksums (requires gh, curl, chezmoi, sha256sum)
./update-version.sh

# Build the base devcontainer
devcontainer build --workspace-folder .

# Build a language-specific devcontainer
devcontainer build --workspace-folder . --config .devcontainer/node/devcontainer.json
```

There is no test suite in this repo. For single-file validation, diff or execute-template the specific template being changed rather than applying the full source tree.

## Key rules

- **`.tmpl` files are Go templates.** Do not shellcheck `.sh.tmpl` or `.ps1.tmpl` files directly — render with `chezmoi execute-template` first. Template delimiters (`{{- ... -}}`) and whitespace trimming are intentional.
- **`data` is init-time; `env` is update-time.** Variables in `.chezmoi.yaml.tmpl` → `data` are frozen at `chezmoi init`. For flags re-read at `chezmoi update` (like `DOTFILES_MIRROR`), use `{{ env "VAR" }}` directly in `.chezmoiexternal.yaml.tmpl`.
- **When adding a binary**, update three surfaces: (1) `update-version.sh` repo list, (2) `home/.chezmoiexternal.yaml.tmpl` using `{{ template "mirror_urls" ... }}` for GitHub hosts or inline `url`+`checksum` for non-GitHub hosts, (3) run `./update-version.sh`.
- **Generated files:** `home/.chezmoidata/versions.yaml` and `home/.chezmoidata/checksums.yaml` are machine-written by `update-version.sh`. Never hand-edit.
- **Version keys** strip hyphens from GitHub repo names (e.g., `NTrace-core` → `NTracecore`). Match this in `.chezmoiexternal.yaml.tmpl` path values.

## Detailed docs

- [Architecture & File Layout](ARCHITECTURE.md)
- [Template Patterns](docs/templates.md)
- [References](docs/references.md)
