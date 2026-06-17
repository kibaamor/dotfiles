# Architecture & File Layout

## Architecture

- `.chezmoiroot` → `home/`, so `home/dot_zshrc.tmpl` maps to `~/.zshrc`, `home/.chezmoiscripts/run_onchange_*` are lifecycle scripts, and `create_empty_dot_gitconfig-*` are empty include files.
- `home/.chezmoi.yaml.tmpl` is the central data template. It derives flags from env vars (`DOTFILES_CAN_SUDO`, `DOTFILES_NONPERSONAL`, git identity) and exposes normalized values: OS-specific archive suffixes, executable extensions, architecture aliases, and sudo capability.
- `home/.chezmoidata/` holds structured data: package lists, external tool versions, Windows optional features. Version keys strip hyphens from GitHub repo names (e.g., `NTrace-core` → `NTracecore`).
- `home/.chezmoiexternal.yaml.tmpl` downloads third-party binaries and archives. Uses the `mirror_urls` named template for all GitHub-hosted entries; `DOTFILES_MIRROR=https://cdn.gh-proxy.org` swaps the CDN mirror to primary URL at `chezmoi update` time. Non-GitHub entries (helm) use inline `url` + `checksum` only. Gates Linux/macOS-only assets with `if ne .chezmoi.os "windows"`, and optional Kubernetes/container tools behind `DOTFILES_EXTRA_BINS` and `DOTFILES_ARKADE_BINS` env vars.
- `home/.chezmoiscripts/`: Debian/CentOS package installs run before apply; Vim plugin setup and zsh shell switching run after apply; Windows scripts configure PATH, git/proxy, winget/scoop, Explorer preferences, and optional features.
- Devcontainer: `.devcontainer/Dockerfile` installs dotfiles into Ubuntu with extra+arkade bins enabled. `.github/workflows/devcontainers.yml` publishes base + Node/Go variants to GHCR and Docker Hub.

## File layout summary

| Path | Purpose |
|---|---|
| `home/.chezmoi.yaml.tmpl` | Central config: env vars → template data (OS, arch, flags) |
| `home/.chezmoidata/versions.yaml` | Generated: pinned release versions |
| `home/.chezmoidata/checksums.yaml` | Generated: sha256 of every external download URL |
| `home/.chezmoidata/packages.yaml` | OS package lists for Debian/CentOS |
| `home/.chezmoidata/windows.yaml` | Windows optional features |
| `home/.chezmoiexternal.yaml.tmpl` | Third-party downloads via `mirror_urls` template (47 entries) + helm (inline) |
| `home/.chezmoiscripts/run_onchange_*` | Install-time side effects (packages, chsh, vim setup, Windows config) |
| `update-version.sh` | Fetches latest GitHub releases, regenerates version + checksum data |