# dotfiles

Personal dotfiles.

## Install

### Linux

```bash
# Set the default Git user name and email.
export GIT_USERNAME=x
export GIT_USEREMAIL=x@x.x
# (Optional) Install extra binaries.
export DOTFILES_INSTALL_EXTRA_BINS=1
# (Optional) Install binaries through arkade.
export DOTFILES_INSTALL_ARKADE_BINS=1
# (Optional) Use the GitHub CDN proxy in China.
export DOTFILES_USE_CDN=1
# (Optional) Set a proxy; replace this URL with your proxy address.
export HTTP_PROXY=http://localhost:7890
export HTTPS_PROXY=http://localhost:7890
export default_proxy=http://localhost:7890
# (Optional) Set the GitHub proxy.
git config --global url."https://cdn.gh-proxy.org/https://github.com/".insteadOf "https://github.com/"
git config --file ~/.gitconfig-proxy url."https://cdn.gh-proxy.org/https://github.com/".insteadOf "https://github.com/"

# Install dotfiles
sh -c "$(curl kibazen.cn/dotfiles.sh)"
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
# (Optional) Install extra binaries.
$env:DOTFILES_INSTALL_EXTRA_BINS = "1"
# (Optional) Install binaries through arkade.
$env:DOTFILES_INSTALL_ARKADE_BINS = "1"
# (Optional) Use the GitHub CDN proxy in China.
$env:DOTFILES_USE_CDN = "1"
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

## Installed Binaries

### Default Installed Binaries

1. [delta](https://github.com/dandavison/delta)
1. [bat](https://github.com/sharkdp/bat)
1. [fd](https://github.com/sharkdp/fd)
1. [fzf](https://github.com/junegunn/fzf)
1. [direnv](https://github.com/direnv/direnv)
1. [rg](https://github.com/BurntSushi/ripgrep)
1. [lsd](https://github.com/lsd-rs/lsd)
1. [duf](https://github.com/muesli/duf)
1. [age, age-keygen](https://github.com/FiloSottile/age)
1. [tldr](https://github.com/tldr-pages/tlrc)
1. [jq](https://github.com/jqlang/jq)
1. [yq](https://github.com/mikefarah/yq)
1. [gdu](https://github.com/dundee/gdu)
1. [nali](https://github.com/zu1k/nali)
1. [tproxy](https://github.com/kevwan/tproxy)
1. [gping](https://github.com/orf/gping)
1. [doggo](https://github.com/mr-karan/doggo)
1. [nexttrace](https://github.com/nxtrace/NTrace-core)
1. [ctop](https://github.com/bcicen/ctop)
1. [kubecolor](https://github.com/kubecolor/kubecolor)
1. [arkade](https://github.com/alexellis/arkade)
1. [upx](https://github.com/upx/upx)
1. [ShellCheck](https://github.com/koalaman/shellcheck) (Linux/macOS)

### Extra Binaries

> These binaries are installed only when `DOTFILES_INSTALL_EXTRA_BINS` is non-empty.

1. [kubeshark](https://github.com/kubeshark/kubeshark)
1. [kubefwd](https://github.com/txn2/kubefwd)

### Binaries Installed via Arkade

> These binaries are installed through arkade only when `DOTFILES_INSTALL_ARKADE_BINS` is non-empty.

1. [mkcert](https://github.com/FiloSottile/mkcert)
1. [dive](https://github.com/wagoodman/dive)
1. [lazydocker](https://github.com/jesseduffield/lazydocker)
1. [minikube](https://github.com/kubernetes/minikube)
1. [kind](https://github.com/kubernetes-sigs/kind)
1. [kubectx, kubens](https://github.com/ahmetb/kubectx)
1. [k9s](https://github.com/derailed/k9s)
1. [helm](https://helm.sh/)

## Troubleshooting

### `chezmoi: fork/exec /tmp/XXXXXXXXXX.XX: permission denied`

```bash
# (Optional) Set `TMPDIR` if `/tmp` is mounted with `noexec`.
export TMPDIR=~/.tmp
```
