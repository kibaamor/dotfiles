# dotfiles

Personal dotfiles.

## Install

```bash
# Set the environment variable 'TMPDIR' if the directory '/tmp' is mounted with 'noexec'
export TMPDIR=~/.tmp
# Set the environment variable 'GIT_USERNAME' to set the default git user name
export GIT_USERNAME=x
# Set the environment variable 'GIT_USEREMAIL' to set the default git user email
export GIT_USEREMAIL=x@x.x

sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply kibaamor && exec zsh -l
```
