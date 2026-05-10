#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VERSIONS_FILE="$ROOT_DIR/home/.chezmoidata/versions.yaml"
CHECKSUMS_FILE="$ROOT_DIR/home/.chezmoidata/checksums.yaml"
CONFIG_TEMPLATE="$ROOT_DIR/home/.chezmoi.yaml.tmpl"
EXTERNALS_TEMPLATE="$ROOT_DIR/home/.chezmoiexternal.yaml.tmpl"
JOBS="${UPDATE_VERSION_JOBS:-8}"
UPDATE_VERSION_TEMP_DIR=""

export GH_PAGER=cat

repos=(
  "romkatv/powerlevel10k"
  "zsh-users/zsh-autosuggestions"
  "zsh-users/zsh-syntax-highlighting"
  "MichaelAquilina/zsh-you-should-use"

  "junegunn/vim-plug"

  ##############################################################
  # Default Installed Binaries
  "dandavison/delta"
  "sharkdp/bat"
  "sharkdp/fd"
  "junegunn/fzf"
  "direnv/direnv"
  "BurntSushi/ripgrep"
  "lsd-rs/lsd"
  "muesli/duf"
  "FiloSottile/age"
  "tldr-pages/tlrc"
  "fatedier/frp"
  "jqlang/jq"
  "mikefarah/yq"
  "dundee/gdu"
  "zu1k/nali"
  "kevwan/tproxy"
  "orf/gping"
  "mr-karan/doggo"
  "nxtrace/NTrace-core"
  "bcicen/ctop"
  "kubecolor/kubecolor"
  "alexellis/arkade"
  "upx/upx"
  "koalaman/shellcheck"
  "kibaamor/ipstream"

  ##############################################################
  # Extra Binaries
  "kubeshark/kubeshark"
  "txn2/kubefwd"

  ##############################################################
  # Arkade Binaries
  "FiloSottile/mkcert"
  "wagoodman/dive"
  "jesseduffield/lazydocker"
  "kubernetes/minikube"
  "kubernetes-sigs/kind"
  "ahmetb/kubectx"
  "derailed/k9s"
  "helm/helm"
)

commit_repos=(
  "ohmyzsh/ohmyzsh master ohmyzsh"
  "fdellwing/zsh-bat master zshbat"
  "kibaamor/vimconf main vimconf"
  "hugsy/gef main gef"
  "junegunn/fzf-git.sh main fzfgitsh"
)

targets=(
  linux/amd64
  linux/arm64
  darwin/amd64
  darwin/arm64
  windows/amd64
)

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required command not found: $1" >&2
    exit 1
  fi
}

cleanup_temp_dir() {
  if [[ -n "$UPDATE_VERSION_TEMP_DIR" ]]; then
    rm -rf "$UPDATE_VERSION_TEMP_DIR"
  fi
}

version_key_for() {
  echo "$1" | cut -d '/' -f 2 | tr -d '-'
}

normalize_version() {
  sed -nE 's/^[^0-9]*([0-9]+([.][0-9]+)*)$/\1/p'
}

latest_version_for() {
  local repo="$1"
  local version

  if ! version="$(
    gh release view \
      --repo "$repo" \
      --json tagName \
      --jq '.tagName' 2>/dev/null | normalize_version
  )"; then
    version=""
  fi

  if [[ -z "$version" ]]; then
    if ! version="$(
      gh api \
        --method GET \
        --header 'Accept: application/vnd.github+json' \
        --jq 'if type == "array" then .[0].name // empty else empty end' \
        "https://api.github.com/repos/$repo/tags" | normalize_version
    )"; then
      version=""
    fi
  fi

  if [[ ! "$version" =~ ^[0-9]+([.][0-9]+)*$ ]]; then
    version=""
  fi

  echo "$version"
}

latest_commit_for() {
  local repo="$1"
  local ref="$2"

  gh api \
    --method GET \
    --header 'Accept: application/vnd.github+json' \
    --jq '.sha' \
    "https://api.github.com/repos/$repo/commits/$ref"
}

render_target_data() {
  local os="$1"
  local arch="$2"

  cat <<EOF
{
  "chezmoi": {
    "os": "$os",
    "arch": "$arch",
    "fqdnHostname": "update-version"
  }
}
EOF
}

extract_urls() {
  sed -n 's/^[[:space:]]*url:[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "$1" | sort -u
}

canonical_key_for_url() {
  local url="$1"

  url="${url#https://}"
  url="${url#cdn.gh-proxy.org/https://}"
  echo "$url"
}

checksum_url() {
  local url="$1"
  local results_dir="$2"
  local key
  local result_file
  local sha256

  key="$(canonical_key_for_url "$url")"
  result_file="$results_dir/$(printf '%s' "$key" | sha256sum | awk '{print $1}')"

  echo "checksumming: $url"
  sha256="$(curl --fail --silent --show-error --location --retry 3 "$url" | sha256sum | awk '{print $1}')"
  printf '  "%s": "%s"\n' "$key" "$sha256" >"$result_file"
}

wait_for_one_checksum() {
  wait -n
}

write_versions() {
  local output_file="$1"
  local repo
  local ref
  local key
  local version
  local commit
  local spec

  echo "versions:" >"$output_file"

  for repo in "${repos[@]}"; do
    echo "processing repo: $repo"

    key="$(version_key_for "$repo")"
    version="$(latest_version_for "$repo")"

    if [[ -z "$version" ]]; then
      echo "error: failed to resolve version for $repo" >&2
      exit 1
    fi

    {
      echo "  # https://github.com/$repo"
      echo "  $key: $version"
    } >>"$output_file"
  done

  echo >>"$output_file"
  echo "commits:" >>"$output_file"

  for spec in "${commit_repos[@]}"; do
    read -r repo ref key <<<"$spec"
    echo "processing repo commit: $repo"

    commit="$(latest_commit_for "$repo" "$ref")"

    if [[ ! "$commit" =~ ^[0-9a-f]{40}$ ]]; then
      echo "error: failed to resolve commit for $repo" >&2
      exit 1
    fi

    {
      echo "  # https://github.com/$repo"
      echo "  $key: $commit"
    } >>"$output_file"
  done
}

write_checksums() {
  local versions_file="$1"
  local output_file="$2"
  local work_dir="$3"
  local active_checksums=0
  local arch
  local failed=0
  local os
  local rendered_file
  local results_dir
  local target
  local target_config_file
  local target_data_file
  local url
  local urls_file

  rendered_file="$(mktemp "$work_dir/rendered.XXXXXX")"
  results_dir="$(mktemp -d "$work_dir/checksums.XXXXXX")"
  target_config_file="$(mktemp "$work_dir/config.XXXXXX.yaml")"
  target_data_file="$(mktemp "$work_dir/target.XXXXXX.json")"
  urls_file="$(mktemp "$work_dir/urls.XXXXXX")"

  : >"$urls_file"

  for target in "${targets[@]}"; do
    os="${target%/*}"
    arch="${target#*/}"

    render_target_data "$os" "$arch" >"$target_data_file"
    env \
      -u DOTFILES_USE_CDN \
      DOTFILES_INSTALL_EXTRA_BINS=1 \
      DOTFILES_INSTALL_ARKADE_BINS=1 \
      chezmoi --source "$ROOT_DIR" execute-template \
      --override-data-file "$target_data_file" \
      --file "$CONFIG_TEMPLATE" >"$target_config_file"
    chezmoi --source "$ROOT_DIR" --config "$target_config_file" execute-template \
      --override-data-file "$versions_file" \
      --override-data-file "$target_data_file" \
      --file "$EXTERNALS_TEMPLATE" >"$rendered_file"
    extract_urls "$rendered_file" >>"$urls_file"
  done

  while IFS= read -r url; do
    checksum_url "$url" "$results_dir" &

    active_checksums=$((active_checksums + 1))
    if [[ "$active_checksums" -ge "$JOBS" ]]; then
      if ! wait_for_one_checksum; then
        failed=1
      fi
      active_checksums=$((active_checksums - 1))
    fi
  done < <(sort -u "$urls_file")

  while [[ "$active_checksums" -gt 0 ]]; do
    if ! wait_for_one_checksum; then
      failed=1
    fi
    active_checksums=$((active_checksums - 1))
  done

  if [[ "$failed" -ne 0 ]]; then
    echo "error: failed to checksum one or more URLs" >&2
    return 1
  fi

  echo "checksums:" >"$output_file"
  find "$results_dir" -type f -exec cat {} + | sort >>"$output_file"
}

main() {
  local temp_checksums_file
  local temp_versions_file

  if [[ ! "$JOBS" =~ ^[1-9][0-9]*$ ]]; then
    echo "error: UPDATE_VERSION_JOBS must be a positive integer: $JOBS" >&2
    exit 1
  fi

  require_command chezmoi
  require_command curl
  require_command gh
  require_command sha256sum

  UPDATE_VERSION_TEMP_DIR="$(mktemp -d "$ROOT_DIR/.update-version.XXXXXX")"
  trap cleanup_temp_dir EXIT

  temp_versions_file="$UPDATE_VERSION_TEMP_DIR/versions.yaml"
  temp_checksums_file="$UPDATE_VERSION_TEMP_DIR/checksums.yaml"

  write_versions "$temp_versions_file"
  write_checksums "$temp_versions_file" "$temp_checksums_file" "$UPDATE_VERSION_TEMP_DIR"

  mv "$temp_versions_file" "$VERSIONS_FILE"
  mv "$temp_checksums_file" "$CHECKSUMS_FILE"

  cleanup_temp_dir
  UPDATE_VERSION_TEMP_DIR=""
  trap - EXIT
}

main
