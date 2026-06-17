# Template Patterns

## `.tmpl` files are Go templates

Do not shellcheck `.sh.tmpl` or `.ps1.tmpl` files directly. Use `chezmoi execute-template` to render them first. Template delimiters (`{{- ... -}}`) and whitespace trimming are intentional.

## Whitespace in `.tmpl` files matters

Many OS-gated blocks use `{{- ... -}}` to suppress blank lines. Don't "fix" the formatting.

## `data` is init-time-only; `env` is update-time

Variables in `.chezmoi.yaml.tmpl` → `data` are frozen at `chezmoi init`. For flags that must be re-read at `chezmoi update` (like `DOTFILES_MIRROR`), use `{{ env "VAR" }}` directly in `.chezmoiexternal.yaml.tmpl` — never pipe them through `data`.

## `mirror_urls` template

When adding a new GitHub-hosted binary, call `{{ template "mirror_urls" (dict "root" $ "path" $xxx_url) }}` instead of inline `url`/`urls`/`checksum`. Non-GitHub hosts (e.g., `get.helm.sh`) should use inline `url` + `checksum` without the template since `cdn.gh-proxy.org` does not proxy them.

## Three surfaces to update when adding a binary

1. `update-version.sh` repo list
2. `home/.chezmoidata/versions.yaml` (via running the script)
3. `home/.chezmoiexternal.yaml.tmpl` — call `{{ template "mirror_urls" (dict "root" $ "path" $xxx_url) }}` for GitHub hosts, or inline `url` + `checksum` for non-GitHub hosts.

## Version keys

Map to GitHub repo names with hyphens removed. `update-version.sh` uses this transformation. When adding to `.chezmoiexternal.yaml.tmpl`, the `"path"` value passed to `mirror_urls` must match the URL path after stripping `https://` and `cdn.gh-proxy.org/https://` prefixes (same as the old `key` in `checksum`).