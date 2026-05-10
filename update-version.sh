#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VERSIONS_FILE="$ROOT_DIR/home/.chezmoidata/versions.yaml"
CHECKSUMS_FILE="$ROOT_DIR/home/.chezmoidata/checksums.yaml"
EXTERNALS_TEMPLATE="$ROOT_DIR/home/.chezmoiexternal.yaml.tmpl"

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

version_key_for() {
  echo "$1" | cut -d '/' -f 2 | tr -d '-'
}

latest_version_for() {
  local repo="$1"
  local version

  version="$(
    gh release view \
      --repo "$repo" \
      --json tagName \
      --jq '.tagName' 2>/dev/null | tr -d '[a-z][A-Z] -'
  )"

  if [[ -z "$version" ]]; then
    version="$(
      gh api \
        --method GET \
        --header 'Accept: application/vnd.github+json' \
        --jq 'if type == "array" then .[0].name // empty else empty end' \
        "https://api.github.com/repos/$repo/tags" | tr -d '[a-z][A-Z] -'
    )"
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

uname_arch_for() {
  case "$1" in
    linux/amd64 | darwin/amd64 | windows/amd64) echo x86_64 ;;
    linux/arm64) echo aarch64 ;;
    darwin/arm64) echo arm64 ;;
    *)
      echo "error: unsupported target: $1" >&2
      exit 1
      ;;
  esac
}

render_data() {
  local os="$1"
  local arch="$2"
  local uname_arch="$3"
  local versions_json="$4"
  local commits_json="$5"
  local exe_ext=""
  local github_url_prefix="https://"
  local go_arch="$uname_arch"
  local pkg_postfix=".tar.gz"
  local pkg_runtime=""
  local platform="unknown"
  local rust_arch="$uname_arch"

  case "$os" in
    windows)
      exe_ext=".exe"
      pkg_postfix=".zip"
      pkg_runtime="-msvc"
      platform="pc"
      ;;
    darwin)
      platform="apple"
      if [[ "$arch" == arm64 ]]; then
        rust_arch="aarch64"
      fi
      ;;
    linux)
      pkg_runtime="-musl"
      ;;
    *)
      echo "error: unsupported OS: $os" >&2
      exit 1
      ;;
  esac

  if [[ "$uname_arch" == aarch64 ]]; then
    go_arch="arm64"
  fi

  cat <<EOF
{
  "chezmoi": {
    "os": "$os",
    "arch": "$arch",
    "fqdnHostname": "update-version"
  },
  "versions": $versions_json,
  "commits": $commits_json,
  "checksums": {},
  "extra_bins": true,
  "arkade_bins": true,
  "use_cdn": false,
  "github_url_prefix": "$github_url_prefix",
  "personal": false,
  "uname_arch": "$uname_arch",
  "go_arch": "$go_arch",
  "pkg_postfix": "$pkg_postfix",
  "exe_ext": "$exe_ext",
  "rust_arch": "$rust_arch",
  "platform": "$platform",
  "pkg_runtime": "$pkg_runtime"
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

should_checksum_url() {
  local _key="$1"

  return 0
}

write_versions() {
  local repo
  local ref
  local key
  local version
  local commit
  local spec

  echo "versions:" >"$VERSIONS_FILE"

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
    } >>"$VERSIONS_FILE"
  done

  echo >>"$VERSIONS_FILE"
  echo "commits:" >>"$VERSIONS_FILE"

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
    } >>"$VERSIONS_FILE"
  done
}

write_checksums() {
  local arch
  local data_file
  local key
  local os
  local rendered_file
  local sha256
  local target
  local uname_arch
  local url
  local urls_file
  local commits_json
  local versions_json

  data_file="$(mktemp --suffix=.json)"
  rendered_file="$(mktemp)"
  urls_file="$(mktemp)"
  trap 'rm -f "$data_file" "$rendered_file" "$urls_file"' RETURN

  versions_json="$(chezmoi --source "$ROOT_DIR" execute-template '{{ .versions | toJson }}')"
  commits_json="$(chezmoi --source "$ROOT_DIR" execute-template '{{ .commits | toJson }}')"
  : >"$urls_file"

  for target in "${targets[@]}"; do
    os="${target%/*}"
    arch="${target#*/}"
    uname_arch="$(uname_arch_for "$target")"

    render_data "$os" "$arch" "$uname_arch" "$versions_json" "$commits_json" >"$data_file"
    chezmoi --source "$ROOT_DIR" execute-template --override-data-file "$data_file" --file "$EXTERNALS_TEMPLATE" >"$rendered_file"
    extract_urls "$rendered_file" >>"$urls_file"
  done

  echo "checksums:" >"$CHECKSUMS_FILE"

  while IFS= read -r url; do
    key="$(canonical_key_for_url "$url")"
    if ! should_checksum_url "$key"; then
      continue
    fi

    echo "checksumming: $url"
    sha256="$(curl --fail --silent --show-error --location --retry 3 "$url" | sha256sum | awk '{print $1}')"
    echo "  \"$key\": \"$sha256\"" >>"$CHECKSUMS_FILE"
  done < <(sort -u "$urls_file")
}

require_command chezmoi
require_command curl
require_command gh
require_command sha256sum

write_versions
write_checksums
