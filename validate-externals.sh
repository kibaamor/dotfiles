#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
EXTERNALS_TEMPLATE="$ROOT_DIR/home/.chezmoiexternal.yaml.tmpl"
JOBS="${VALIDATE_EXTERNALS_JOBS:-8}"

TARGETS=(
  linux/amd64
  linux/arm64
  darwin/amd64
  darwin/arm64
  windows/amd64
)

usage() {
  cat <<'EOF'
Usage: ./validate-externals.sh [-j jobs] [target...]

Validate that URLs rendered from home/.chezmoiexternal.yaml.tmpl exist.

Targets default to:
  linux/amd64 linux/arm64 darwin/amd64 darwin/arm64 windows/amd64

Examples:
  ./validate-externals.sh
  ./validate-externals.sh -j 16
  ./validate-externals.sh darwin/arm64 windows/amd64
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required command not found: $1" >&2
    exit 1
  fi
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
    "fqdnHostname": "validate-externals"
  },
  "versions": $versions_json,
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

check_url() {
  local url="$1"

  curl --fail --silent --show-error --location --head --max-time 30 --retry 2 "$url" >/dev/null 2>&1 \
    || curl --fail --silent --show-error --location --range 0-0 --max-time 30 --retry 2 "$url" >/dev/null 2>&1
}

wait_for_one_check() {
  wait -n || true
}

validate_target() {
  local target="$1"
  local os="${target%/*}"
  local arch="${target#*/}"
  local active_checks=0
  local uname_arch
  local data_file
  local rendered_file
  local failures_file
  local urls_file
  local url
  local url_count

  if [[ "$target" != */* || -z "$os" || -z "$arch" ]]; then
    echo "error: invalid target '$target', expected os/arch" >&2
    return 1
  fi

  uname_arch="$(uname_arch_for "$target")"
  data_file="$(mktemp --suffix=.json)"
  rendered_file="$(mktemp)"
  urls_file="$(mktemp)"
  failures_file="$(mktemp)"

  render_data "$os" "$arch" "$uname_arch" "$VERSIONS_JSON" >"$data_file"
  chezmoi --source "$ROOT_DIR" execute-template --override-data-file "$data_file" --file "$EXTERNALS_TEMPLATE" >"$rendered_file"
  extract_urls "$rendered_file" >"$urls_file"

  url_count="$(wc -l <"$urls_file" | tr -d ' ')"
  printf 'Checking %-14s %s URLs with %s jobs\n' "$target" "$url_count" "$JOBS"

  while IFS= read -r url; do
    {
      if ! check_url "$url"; then
        printf '%s\n' "$url" >>"$failures_file"
      fi
    } &

    active_checks=$((active_checks + 1))
    if [[ "$active_checks" -ge "$JOBS" ]]; then
      wait_for_one_check
      active_checks=$((active_checks - 1))
    fi
  done <"$urls_file"

  while [[ "$active_checks" -gt 0 ]]; do
    wait_for_one_check
    active_checks=$((active_checks - 1))
  done

  rm -f "$data_file" "$rendered_file" "$urls_file"

  if [[ -s "$failures_file" ]]; then
    echo "Missing resources for $target:" >&2
    sed 's/^/  /' "$failures_file" >&2
    rm -f "$failures_file"
    return 1
  fi

  rm -f "$failures_file"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    -j | --jobs)
      if [[ -z "${2:-}" ]]; then
        echo "error: $1 requires a value" >&2
        exit 1
      fi
      JOBS="$2"
      shift 2
      ;;
    --jobs=*)
      JOBS="${1#*=}"
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "error: unknown option: $1" >&2
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

if [[ ! "$JOBS" =~ ^[1-9][0-9]*$ ]]; then
  echo "error: jobs must be a positive integer: $JOBS" >&2
  exit 1
fi

require_command chezmoi
require_command curl

if [[ $# -gt 0 ]]; then
  TARGETS=("$@")
fi

VERSIONS_JSON="$(chezmoi --source "$ROOT_DIR" execute-template '{{ .versions | toJson }}')"

failed=0
for target in "${TARGETS[@]}"; do
  if ! validate_target "$target"; then
    failed=1
  fi
done

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "All external resources exist."
