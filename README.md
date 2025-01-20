# dotfiles

Personal dotfiles.

## Install

```bash
# "~/.customrc.pre.sh" is a custom shell script that runs before most other commands
# There is also a custom shell script "~/.customrc.post.sh" that runs after most other commands
cat <<- EOF >> ~/.customrc.pre.sh
# Set the environment variable 'DOTFILES_INSTALL_EXTRA_BINS' to a value other than '' to install extra binaries.
export DOTFILES_INSTALL_EXTRA_BINS=1
# Set the environment variable 'TMPDIR' if the directory '/tmp' is mounted with 'noexec'
export TMPDIR=~/.tmp
# Set the environment variable 'GIT_USERNAME' to set the default git user name
export GIT_USERNAME=x
# Set the environment variable 'GIT_USEREMAIL' to set the default git user email
export GIT_USEREMAIL=x@x.x
EOF

curl kibazen.cn/install.sh | sh
```
