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

# Lint shell scripts (not .tmpl files)
shellcheck update-version.sh home/dot_utilities.sh

# Update pinned versions and checksums (requires gh, curl, chezmoi, sha256sum)
./update-version.sh

# Build the base devcontainer
devcontainer build --workspace-folder .

# Build a language-specific devcontainer
devcontainer build --workspace-folder . --config .devcontainer/node/devcontainer.json
```

There is no test suite in this repo. For single-file validation, diff or execute-template the specific template being changed rather than applying the full source tree.

## Detailed instructions

- [Architecture & File Layout](ARCHITECTURE.md)
- [Template Patterns](docs/templates.md)
- [References](docs/references.md)
