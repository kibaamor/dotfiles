#!/bin/sh

# -e: exit on error
# -u: exit on unset variables
set -eu

# POSIX way to get script's dir: https://stackoverflow.com/a/29834779/12156188
script_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"

if ! chezmoi="$(command -v chezmoi)"; then
  bin_dir="$HOME/.local/bin"
  chezmoi="${bin_dir}/chezmoi"

  echo "Installing chezmoi to '${chezmoi}'" >&2
  if command -v curl >/dev/null; then
    sh -c "$(curl -fsSL https://git.io/chezmoi)" -- -b "$bin_dir"
  elif command -v wget >/dev/null; then
    sh -c "$(wget -qO- https://git.io/chezmoi)" -- -b "$bin_dir"
  else
    echo "To install chezmoi, you must have curl or wget installed." >&2
    exit 1
  fi
fi

if [ -z "${ACT:+false}${CODESPACES:+false}${DEBIAN_FRONTEND:+false}" ]; then
  echo "Running interactive"
  "${chezmoi}" init "--source=${script_dir}"
  "${chezmoi}" diff --verbose
  read -p 'Apply modifications? (y/n) ' r
  case "${r}" in
    y|Y|s|S)
      set -- apply --verbose --source="${script_dir}"
      ;;
    *)
      set -- diff
      ;;
  esac
else
  set -- init --apply --verbose --source="${script_dir}"
fi

echo "Running 'chezmoi $*'" >&2
# exec: replace current process with chezmoi
exec "$chezmoi" "$@"
