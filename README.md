# dotfiles

Personal dotfiles.

## Install

```bash
TMPDIR=~/.tmp \
    CHEZMOI_GET_ALL_RESOURCES=1 \
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply kibaamor && exec zsh -l

# OR

TMPDIR=~/.tmp \
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply kibaamor && exec zsh -l
arkade get kubefwd --path ~/.local/bin/
arkade get kubeshark --path ~/.local/bin/
arkade get k9s --path ~/.local/bin/
arkade get minikube --path ~/.local/bin/
arkade get helm --path ~/.local/bin/
```
