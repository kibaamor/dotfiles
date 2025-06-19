# dotfiles

Personal dotfiles.

## Install

### Linux

```bash
# "~/.customrc.pre.sh" is a custom shell script that runs before most other commands
# There is also a custom shell script "~/.customrc.post.sh" that runs after most other commands
cat <<- EOF >> ~/.customrc.pre.sh
# (Optional) Set the value of 'DOTFILES_INSTALL_EXTRA_BINS' to non-empty to install extra binaries, 
# see below for more details.
export DOTFILES_INSTALL_EXTRA_BINS=1
# (Optional) Set the value of 'DOTFILES_INSTALL_ARKADE_BINS' to non-empty to install all binaries 
# that can be installed via arkade, see below for more details.
export DOTFILES_INSTALL_ARKADE_BINS=1
# Set the value of 'GIT_USERNAME' to set the default git user name.
export GIT_USERNAME=x
# Set the value of 'GIT_USEREMAIL' to set the default git user email.
export GIT_USEREMAIL=x@x.x
EOF

export HTTP_PROXY=http://localhost:7890
export HTTPS_PROXY=http://localhost:7890
sh -c "$(curl kibazen.cn/install.sh)"
```

### Windows

```powershell
# Install WinGet on Windows Sandbox
# https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget-on-windows-sandbox

winget install --id twpayne.chezmoi --accept-source-agreements

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

$env:HTTP_PROXY = 'http://localhost:7890'
$env:HTTPS_PROXY = 'http://localhost:7890'
chezmoi init --apply kibaamor
```

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
1. [gdu](https://github.com/zu1k/nali)
1. [nali](https://github.com/zu1k/nali)
1. [tproxy](https://github.com/kevwan/tproxy)
1. [gping](https://github.com/orf/gping)
1. [doggo](https://github.com/mr-karan/doggo)
1. [nexttrace](https://github.com/nxtrace/NTrace-core)
1. [ctop](https://github.com/bcicen/ctop)
1. [kubecolor](https://github.com/kubecolor/kubecolor)
1. [arkade](https://github.com/alexellis/arkade)

### Extra Binaries

> Only install those binaries if the value of the environment variable 'DOTFILES_INSTALL_EXTRA_BINS' is non-empty.

1. [kubeshark](https://github.com/kubeshark/kubeshark)
1. [kubefwd](https://github.com/txn2/kubefwd)

### Binaries Can Be Installed Via Arkade

> You can set the value of the environment variable 'DOTFILES_INSTALL_ARKADE_BINS' to empty, so that chezmoi installs these bins instead of arkade.

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
# (Optional) Set the value of 'TMPDIR' if the directory '/tmp' is mounted with 'noexec'.
export TMPDIR=~/.tmp
```
