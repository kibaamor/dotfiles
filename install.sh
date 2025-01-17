#!/bin/sh

sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME"/.local/bin init --apply kibaamor
