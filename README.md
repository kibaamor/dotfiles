# dotfiles

[![Build and Push DevContainers](https://github.com/kibaamor/dotfiles/actions/workflows/devcontainers.yml/badge.svg)](https://github.com/kibaamor/dotfiles/actions/workflows/devcontainers.yml)

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Installation

### Find the fastest mirror (optional; useful in China)

Before installing, run the mirror finder to choose a fast GitHub mirror for your
network. It tests candidates in parallel and exports the selected URL as
`DOTFILES_MIRROR`. Set that variable in your environment before continuing.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/kibaamor/dotfiles/main/find-gh-mirror.sh)
# or
bash <(curl -fsSL https://cdn.gh-proxy.org/https://raw.githubusercontent.com/kibaamor/dotfiles/main/find-gh-mirror.sh)
# or
bash <(curl -fsSL https://ghproxy.net/https://raw.githubusercontent.com/kibaamor/dotfiles/main/find-gh-mirror.sh)
```

See `find-gh-mirror.sh --help` for custom probes, timeouts, extra mirrors, and
other options.

### Linux

```bash
# Set the default Git user name and email.
export GIT_USERNAME=x
export GIT_USEREMAIL=x@x.x
# (Optional) Install extra binaries (takes effect at every chezmoi update).
export DOTFILES_EXTRA_BINS=1
# (Optional) Install binaries through arkade (takes effect at every chezmoi update).
export DOTFILES_ARKADE_BINS=1
# (Optional) Choose an agent skill suite (defaults to matt).
export DOTFILES_AGENT_SKILL_SUIT=matt
# (Optional) Set a mirror for GitHub-hosted downloads.
export DOTFILES_MIRROR=https://cdn.gh-proxy.org
# (Optional) Set a proxy; replace this URL with your proxy address.
export HTTP_PROXY=http://localhost:7890
export HTTPS_PROXY=http://localhost:7890
export default_proxy=http://localhost:7890
# (Optional) Set a GitHub URL rewrite rule.
git config --global url."https://cdn.gh-proxy.org/https://github.com/".insteadOf "https://github.com/"
git config --file ~/.gitconfig-proxy url."https://cdn.gh-proxy.org/https://github.com/".insteadOf "https://github.com/"

# Install dotfiles
sh -c "$(curl -fsLS https://get.chezmoi.io/lb)" -- init --apply kibaamor
```

Set service-specific Git identities with:

- GitHub: `git config --file ~/.gitconfig-github user.name xxx`
- GitLab: `git config --file ~/.gitconfig-gitlab user.name xxx`

### Windows

```powershell
# Install WinGet on Windows Sandbox
# https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget-on-windows-sandbox

# Install chezmoi via WinGet
winget install --id twpayne.chezmoi --accept-source-agreements

# Set the default Git user name and email.
$env:GIT_USERNAME = "x"
$env:GIT_USEREMAIL = "x@x.x"
# (Optional) Install extra binaries (takes effect at every chezmoi update).
$env:DOTFILES_EXTRA_BINS = "1"
# (Optional) Install binaries through arkade (takes effect at every chezmoi update).
$env:DOTFILES_ARKADE_BINS = "1"
# (Optional) Choose an agent skill suite (defaults to matt).
$env:DOTFILES_AGENT_SKILL_SUIT = "matt"
# (Optional) Set a mirror for GitHub-hosted downloads.
$env:DOTFILES_MIRROR = "https://cdn.gh-proxy.org"
# (Optional) Set a proxy; replace this URL with your proxy address.
$env:HTTP_PROXY = "http://localhost:7890"
$env:HTTPS_PROXY = "http://localhost:7890"
$env:default_proxy = "http://localhost:7890"
# (Optional) Set a GitHub URL rewrite rule.
git config --global url."https://cdn.gh-proxy.org/https://github.com/".insteadOf "https://github.com/"
git config --file ~/.gitconfig-proxy url."https://cdn.gh-proxy.org/https://github.com/".insteadOf "https://github.com/"

# Set the execution policy to RemoteSigned for the current user, so that the dotfiles setup scripts can be executed.
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Install dotfiles
chezmoi init --apply kibaamor
```

Set service-specific Git identities with:

- GitHub: `git config --file $env:USERPROFILE/.gitconfig-github user.name xxx`
- GitLab: `git config --file $env:USERPROFILE/.gitconfig-gitlab user.name xxx`

## Usage

### Prefer CDN mirror for downloads

Set `DOTFILES_MIRROR` to a mirror base URL to route GitHub-hosted downloads through a
proxy or CDN. The mirror is tried first, with the original GitHub URL as a fallback.
This setting is re-read at every `chezmoi update`.

```bash
DOTFILES_MIRROR=https://cdn.gh-proxy.org chezmoi update
```

### Choose AI agent skills at update time

`DOTFILES_AGENT_SKILL_SUIT` is re-read at every `chezmoi update`. If unset or empty,
it defaults to `matt`.

| Value | Skills installed |
| --- | --- |
| `none` | none |
| `pony` | `ponytail` only |
| `matt` (default) | `ponytail` and skills from [`mattpocock/skills`](https://github.com/mattpocock/skills) |
| `superpowers` | `ponytail` and all skills from [`obra/superpowers`](https://github.com/obra/superpowers/tree/main/skills) |
| Any other value | Template rendering fails with an error |

```bash
DOTFILES_AGENT_SKILL_SUIT=none chezmoi update
DOTFILES_AGENT_SKILL_SUIT=pony chezmoi update
DOTFILES_AGENT_SKILL_SUIT=matt chezmoi update
DOTFILES_AGENT_SKILL_SUIT=superpowers chezmoi update
```

### Toggle extra binaries at update time

`DOTFILES_EXTRA_BINS` and `DOTFILES_ARKADE_BINS` are re-read at every
`chezmoi update`; no re-initialization is needed.

```bash
# Enable extra binaries on next update
DOTFILES_EXTRA_BINS=1 DOTFILES_ARKADE_BINS=1 chezmoi update

# Disable extra binaries on next update (remove from ~/.local/bin on next apply)
chezmoi update
```

## Installed binaries

### Installed by default

- [delta](https://github.com/dandavison/delta) — Linux / Windows
- [bat](https://github.com/sharkdp/bat) — Linux / macOS / Windows
- [fd](https://github.com/sharkdp/fd) — Linux / Windows
- [fzf](https://github.com/junegunn/fzf) — Linux / macOS / Windows
- [direnv](https://github.com/direnv/direnv) — Linux / macOS / Windows
- [rg](https://github.com/BurntSushi/ripgrep) — Linux / macOS / Windows
- [lsd](https://github.com/lsd-rs/lsd) — Linux / macOS / Windows
- [duf](https://github.com/muesli/duf) — Linux / macOS / Windows
- [age, age-keygen](https://github.com/FiloSottile/age) — Linux / macOS / Windows
- [tldr](https://github.com/tldr-pages/tlrc) — Linux / macOS / Windows
- [jq](https://github.com/jqlang/jq) — Linux / macOS / Windows
- [yq](https://github.com/mikefarah/yq) — Linux / macOS / Windows
- [gdu](https://github.com/dundee/gdu) — Linux / macOS / Windows
- [ipgeo](https://github.com/kibaamor/ipgeo) — Linux / macOS / Windows
- [ipstream](https://github.com/kibaamor/ipstream) — Linux / macOS / Windows
- [tproxy](https://github.com/kevwan/tproxy) — Linux / macOS / Windows
- [gping](https://github.com/orf/gping) — Linux / macOS / Windows
- [doggo](https://github.com/mr-karan/doggo) — Linux / macOS / Windows
- [nexttrace](https://github.com/nxtrace/NTrace-core) — Linux / macOS / Windows
- [ctop](https://github.com/bcicen/ctop) — Linux / Windows
- [kubecolor](https://github.com/kubecolor/kubecolor) — Linux / macOS / Windows
- [arkade](https://github.com/alexellis/arkade) — Linux / macOS / Windows
- [upx](https://github.com/upx/upx) — Linux only
- [ShellCheck](https://github.com/koalaman/shellcheck) — Linux / macOS / Windows

### Extra binaries

These binaries are installed only when `DOTFILES_EXTRA_BINS` is non-empty:

- [kubeshark](https://github.com/kubeshark/kubeshark) — Linux / macOS / Windows
- [kubefwd](https://github.com/txn2/kubefwd) — Linux / macOS / Windows

### Binaries installed via arkade

These binaries are installed through arkade only when `DOTFILES_ARKADE_BINS` is
non-empty:

- [mkcert](https://github.com/FiloSottile/mkcert) — Linux / macOS / Windows
- [dive](https://github.com/wagoodman/dive) — Linux / macOS / Windows
- [lazydocker](https://github.com/jesseduffield/lazydocker) — Linux / macOS / Windows
- [minikube](https://github.com/kubernetes/minikube) — Linux / macOS / Windows
- [kind](https://github.com/kubernetes-sigs/kind) — Linux / macOS / Windows
- [kubectx, kubens](https://github.com/ahmetb/kubectx) — Linux / macOS / Windows
- [k9s](https://github.com/derailed/k9s) — Linux / macOS / Windows
- [helm](https://helm.sh/) — Linux / macOS / Windows

## Troubleshooting

### `chezmoi: fork/exec /tmp/XXXXXXXXXX.XX: permission denied`

```bash
# (Optional) Set `TMPDIR` if `/tmp` is mounted with `noexec`.
export TMPDIR=~/.tmp
```
