# dotfiles

[![Build and Push DevContainers](https://github.com/kibaamor/dotfiles/actions/workflows/devcontainers.yml/badge.svg)](https://github.com/kibaamor/dotfiles/actions/workflows/devcontainers.yml)

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Install

### Find the fastest mirror (optional, useful for users in China)

Before installing, run this script to pick the fastest GitHub mirror for your network.
The script tests multiple mirror candidates in parallel and exports the result as a
`DOTFILES_MIRROR` variable — add it to your environment before running the install
commands below.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/kibaamor/dotfiles/main/find-gh-mirror.sh)
# or
bash <(curl -fsSL https://cdn.gh-proxy.org/https://raw.githubusercontent.com/kibaamor/dotfiles/main/find-gh-mirror.sh)
# or
bash <(curl -fsSL https://ghproxy.net/https://raw.githubusercontent.com/kibaamor/dotfiles/main/find-gh-mirror.sh)
```

> See `find-gh-mirror.sh --help` for additional options (custom probes, timeouts, extra mirrors, etc.).

### Linux

```bash
# Set the default Git user name and email.
export GIT_USERNAME=x
export GIT_USEREMAIL=x@x.x
# (Optional) Install extra binaries (takes effect at every chezmoi update).
export DOTFILES_EXTRA_BINS=1
# (Optional) Install binaries through arkade (takes effect at every chezmoi update).
export DOTFILES_ARKADE_BINS=1
# (Optional) Set a mirror for GitHub-hosted downloads.
export DOTFILES_MIRROR=https://cdn.gh-proxy.org
# (Optional) Set a proxy; replace this URL with your proxy address.
export HTTP_PROXY=http://localhost:7890
export HTTPS_PROXY=http://localhost:7890
export default_proxy=http://localhost:7890
# (Optional) Set the GitHub proxy.
git config --global url."https://cdn.gh-proxy.org/https://github.com/".insteadOf "https://github.com/"
git config --file ~/.gitconfig-proxy url."https://cdn.gh-proxy.org/https://github.com/".insteadOf "https://github.com/"

# Install dotfiles
sh -c "$(curl -fsLS https://get.chezmoi.io/lb)" -- init --apply kibaamor
```

> You can set git config for GitHub via command `git config --file ~/.gitconfig-github user.name xxx`.
>
> You can set git config for GitLab via command `git config --file ~/.gitconfig-gitlab user.name xxx`.

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
# (Optional) Set a mirror for GitHub-hosted downloads.
$env:DOTFILES_MIRROR = "https://cdn.gh-proxy.org"
# (Optional) Set a proxy; replace this URL with your proxy address.
$env:HTTP_PROXY = "http://localhost:7890"
$env:HTTPS_PROXY = "http://localhost:7890"
$env:default_proxy = "http://localhost:7890"
# (Optional) Set the GitHub proxy.
git config --global url."https://cdn.gh-proxy.org/https://github.com/".insteadOf "https://github.com/"
git config --file ~/.gitconfig-proxy url."https://cdn.gh-proxy.org/https://github.com/".insteadOf "https://github.com/"

# Set the execution policy to RemoteSigned for the current user, so that the dotfiles setup scripts can be executed.
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Install dotfiles
chezmoi init --apply kibaamor
```

> You can set git config for GitHub via command `git config --file $env:USERPROFILE/.gitconfig-github user.name xxx`.
>
> You can set git config for GitLab via command `git config --file $env:USERPROFILE/.gitconfig-gitlab user.name xxx`.

## Usage

### Prefer CDN mirror for downloads

Set `DOTFILES_MIRROR` to a mirror base URL to route all GitHub-hosted downloads through
a proxy/CDN instead of fetching directly from GitHub. When set, the mirror becomes the
primary URL and the original GitHub URL is preserved as a fallback. Takes effect at
every `chezmoi update`, not just `chezmoi init`.

```bash
DOTFILES_MIRROR=https://cdn.gh-proxy.org chezmoi update
```

### Toggle extra binaries at update time

`DOTFILES_EXTRA_BINS` and `DOTFILES_ARKADE_BINS` are re-read at every `chezmoi update` — no need to re-initialize.
Enable or disable them before running update:

```bash
# Enable extra binaries on next update
DOTFILES_EXTRA_BINS=1 DOTFILES_ARKADE_BINS=1 chezmoi update

# Disable extra binaries on next update (remove from ~/.local/bin on next apply)
chezmoi update
```

## Installed Binaries

### Default Installed Binaries

1. [delta](https://github.com/dandavison/delta) — Linux / Windows
1. [bat](https://github.com/sharkdp/bat) — Linux / macOS / Windows
1. [fd](https://github.com/sharkdp/fd) — Linux / Windows
1. [fzf](https://github.com/junegunn/fzf) — Linux / macOS / Windows
1. [direnv](https://github.com/direnv/direnv) — Linux / macOS / Windows
1. [rg](https://github.com/BurntSushi/ripgrep) — Linux / macOS / Windows
1. [lsd](https://github.com/lsd-rs/lsd) — Linux / macOS / Windows
1. [duf](https://github.com/muesli/duf) — Linux / macOS / Windows
1. [age, age-keygen](https://github.com/FiloSottile/age) — Linux / macOS / Windows
1. [tldr](https://github.com/tldr-pages/tlrc) — Linux / macOS / Windows
1. [jq](https://github.com/jqlang/jq) — Linux / macOS / Windows
1. [yq](https://github.com/mikefarah/yq) — Linux / macOS / Windows
1. [gdu](https://github.com/dundee/gdu) — Linux / macOS / Windows
1. [ipgeo](https://github.com/kibaamor/ipgeo) — Linux / macOS / Windows
1. [ipstream](https://github.com/kibaamor/ipstream) — Linux / macOS / Windows
1. [tproxy](https://github.com/kevwan/tproxy) — Linux / macOS / Windows
1. [gping](https://github.com/orf/gping) — Linux / macOS / Windows
1. [doggo](https://github.com/mr-karan/doggo) — Linux / macOS / Windows
1. [nexttrace](https://github.com/nxtrace/NTrace-core) — Linux / macOS / Windows
1. [ctop](https://github.com/bcicen/ctop) — Linux / Windows
1. [kubecolor](https://github.com/kubecolor/kubecolor) — Linux / macOS / Windows
1. [arkade](https://github.com/alexellis/arkade) — Linux / macOS / Windows
1. [upx](https://github.com/upx/upx) — Linux only
1. [ShellCheck](https://github.com/koalaman/shellcheck) — Linux / macOS / Windows

### Extra Binaries

> These binaries are installed only when `DOTFILES_EXTRA_BINS` is non-empty.

1. [kubeshark](https://github.com/kubeshark/kubeshark) — Linux / macOS / Windows
1. [kubefwd](https://github.com/txn2/kubefwd) — Linux / macOS / Windows

### Binaries Installed via Arkade

> These binaries are installed through arkade only when `DOTFILES_ARKADE_BINS` is non-empty.

1. [mkcert](https://github.com/FiloSottile/mkcert) — Linux / macOS / Windows
1. [dive](https://github.com/wagoodman/dive) — Linux / macOS / Windows
1. [lazydocker](https://github.com/jesseduffield/lazydocker) — Linux / macOS / Windows
1. [minikube](https://github.com/kubernetes/minikube) — Linux / macOS / Windows
1. [kind](https://github.com/kubernetes-sigs/kind) — Linux / macOS / Windows
1. [kubectx, kubens](https://github.com/ahmetb/kubectx) — Linux / macOS / Windows
1. [k9s](https://github.com/derailed/k9s) — Linux / macOS / Windows
1. [helm](https://helm.sh/) — Linux / macOS / Windows

## Troubleshooting

### `chezmoi: fork/exec /tmp/XXXXXXXXXX.XX: permission denied`

```bash
# (Optional) Set `TMPDIR` if `/tmp` is mounted with `noexec`.
export TMPDIR=~/.tmp
```
