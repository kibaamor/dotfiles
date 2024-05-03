#!/bin/sh

# TMPDIR=~/.tmp
# CHEZMOI_GET_ALL_RESOURCES=1
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin init --apply kibaamor
