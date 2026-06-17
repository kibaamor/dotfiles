# References

## `.editorconfig` rules

YAML/JSON/templates/shell use 2-space indent; everything else 4-space. PowerShell files use CRLF + UTF-8-BOM.

## `update-version.sh` generates `versions.yaml` and `checksums.yaml`

These are machine-written. The script strips hyphens from repo names to create keys. Never hand-edit these files.

## Architecture normalization

`uname_arch`, `go_arch`, and `rust_arch` are derived in `.chezmoi.yaml.tmpl` from `.chezmoi.arch` (`amd64`→`x86_64`, `arm64`→`aarch64` on linux). External download URLs use the appropriate arch variant per tool.

## Proxy/CDN pattern

All GitHub-hosted downloads use the `mirror_urls` template which produces a primary URL. Set `DOTFILES_MIRROR=https://cdn.gh-proxy.org` at update time to route downloads through a mirror with GitHub as fallback in `urls`. When unset, downloads go directly to GitHub (no fallback). Preserve `default_proxy`/`default_no_proxy` handling in shell and Windows profile scripts.

## OS gating

Keep OS-specific behavior gated with `.chezmoi.os`, `.chezmoi.osRelease`, `.interactive`, and `.can_sudo` rather than adding unconditional package installs or shell changes.

## Git identity

Global config and include files split between GitHub/GitLab/proxy. Keep `create_empty_dot_gitconfig-*`, `dot_gitconfig.tmpl`, and shell/PowerShell runtime updates consistent.

## Zsh startup

`dot_zshrc.tmpl` is intentionally defensive. Most integrations are loaded only when commands exist; custom hooks are sourced from `~/.customrc.pre.sh` and `~/.customrc.post.sh`; file ends with a successful return for sourced-shell compatibility.