#!/bin/sh

# TMPDIR=~/.tmp
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin init --apply kibaamor
