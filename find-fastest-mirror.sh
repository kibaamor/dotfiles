#!/usr/bin/env bash

set -euo pipefail


PREFERRED_MIRROR="https://cdn.gh-proxy.org"

CANDIDATES=(
  "https://gh-proxy.org"
  "https://cdn.gh-proxy.org"
  "https://v4.gh-proxy.org"
  "https://v6.gh-proxy.org"
  "https://gh-proxy.com"
  "https://ghproxy.net"
  ""
)

usage() {
  cat <<EOF
Usage: find-fastest-mirror.sh [OPTIONS]

Probe GitHub mirror candidates and export the fastest one.

Options:
  -p N    Number of probes per mirror (default: $PROBES)
  -c N    Connect timeout in seconds (default: $TIMEOUT_CONNECT)
  -m N    Max time per probe in seconds (default: $TIMEOUT_MAX)
  -j N    Max concurrent probes (default: $MAX_JOBS)
  -t URL  Test path (default: $TEST_PATH)
  -x URL  Add an extra mirror to test (can be repeated, use "" for direct)
  -s SHA  Expected SHA256 of the test file (set to empty to skip verification)
  -h      Show this help
EOF
  exit 0
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required command not found: $1" >&2
    exit 1
  fi
}

median_line() {
  local file="$1"
  local -a vals=()

  while IFS= read -r line; do
    vals+=("$line")
  done < <(cat "$file" 2>/dev/null)

  ((${#vals[@]})) || { echo "99999 0 0"; return; }
  printf '%s\n' "${vals[@]}" | sort -t' ' -k1 -n | sed -n "$(( (${#vals[@]} + 1) / 2 ))p"
}

bytes_to_human() {
  local b="$1"
  if (( $(echo "$b >= 1073741824" | bc -l) )); then
    printf '%.1fG' "$(echo "$b / 1073741824" | bc -l)"
  elif (( $(echo "$b >= 1048576" | bc -l) )); then
    printf '%.1fM' "$(echo "$b / 1048576" | bc -l)"
  elif (( $(echo "$b >= 1024" | bc -l) )); then
    printf '%.1fK' "$(echo "$b / 1024" | bc -l)"
  else
    printf '%sB' "$b"
  fi
}

speed_human() {
  local bps="$1"
  if (( $(echo "${bps:-0} >= 1073741824" | bc -l) )); then
    printf '%.1fGB/s' "$(echo "$bps / 1073741824" | bc -l)"
  elif (( $(echo "${bps:-0} >= 1048576" | bc -l) )); then
    printf '%.1fMB/s' "$(echo "$bps / 1048576" | bc -l)"
  elif (( $(echo "${bps:-0} >= 1024" | bc -l) )); then
    printf '%.1fKB/s' "$(echo "$bps / 1024" | bc -l)"
  else
    printf '%sB/s' "$bps"
  fi
}

slugify() { local s="${1:-direct}"; printf '%s' "${s//[^a-zA-Z0-9]/_}"; }
mirror_url() { [[ -z "$1" ]] && echo "$TEST_URL" || echo "$1/$TEST_URL"; }

probe() {
  local -n _mirrors="$1"
  local tmp="$2"
  local -n _rank="$3"
  local -n _best="$4"
  local -n _best_lat="$5"
  local -n _pref_lat="$6"
  local -n _valid="$7"
  local pids=()
  local vres="$tmp/_verify_results"

  [[ -n "$TEST_SHA256" ]] && true >"$vres"

  for m in "${_mirrors[@]}"; do
    local slug
    slug="$(slugify "$m")"
    local times="$tmp/${slug}.times"
    local label="${m:-direct}"
    local url
    url="$(mirror_url "$m")"

    echo "# probing $label ($PROBES probes)..." >&2

    for ((i = 0; i < PROBES; i++)); do
      (
        curl -L --connect-timeout "$TIMEOUT_CONNECT" --max-time "$TIMEOUT_MAX" \
          --silent --output /dev/null \
          --write-out '%{time_total} %{size_download} %{speed_download}\n' "$url" >>"$times" 2>/dev/null || true
      ) &
      pids+=("$!")
    done

    if [[ -n "$TEST_SHA256" ]]; then
      echo "# verifying $label..." >&2
      (
        local dl="$tmp/${slug}.dl"
        local sha
        sha=$(curl -L --connect-timeout "$TIMEOUT_CONNECT" --max-time "$TIMEOUT_MAX" \
          --silent -o "$dl" --write-out '' "$url" 2>/dev/null && sha256sum "$dl" | awk '{print $1}' || true)
        rm -f "$dl"
        [[ "$sha" == "$TEST_SHA256" ]] && echo "${slug}:1" || echo "${slug}:0"
      ) >> "$vres" 2>/dev/null &
      pids+=("$!")
    fi

    while (( ${#pids[@]} >= MAX_JOBS )); do
      wait "${pids[0]}" || true
      pids=("${pids[@]:1}")
    done
  done

  for pid in "${pids[@]}"; do wait "$pid" || true; done

  if [[ -n "$TEST_SHA256" ]]; then
    while IFS=: read -r vslug vval; do
      _valid["$vslug"]="$vval"
    done < "$vres"
    rm -f "$vres"
  fi

  local pick=
  local pick_lat=99999
  local pref_val=99999

  for m in "${_mirrors[@]}"; do
    local slug label lat size speed verified
    slug="$(slugify "$m")"
    label="${m:-direct}"

    local row
    row="$(median_line "$tmp/${slug}.times")"
    lat="$(echo "$row" | awk '{print $1}')"
    size="$(echo "$row" | awk '{print $2}')"
    speed="$(echo "$row" | awk '{print $3}')"
    verified="${_valid["$slug"]:-1}"

    if [[ -z "$lat" || "$lat" == 99999 ]]; then
      _rank+=("$lat $label $verified")
    else
      _rank+=("$(printf '%s %s %s %s %s' "$lat" "$size" "$speed" "$label" "$verified")")
    fi

    if (( $(echo "$lat < $pick_lat" | bc -l) )) && [[ "${_valid[$slug]:-1}" != 0 ]]; then
      pick_lat="$lat"
      pick="$m"
    fi
    [[ "$m" == "$PREFERRED_MIRROR" ]] && pref_val="$lat"
  done

  _best="$pick"
  _best_lat="$pick_lat"
  _pref_lat="$pref_val"
}

main() {
  require_command curl

  if [[ -n "$TEST_SHA256" ]] && ! command -v sha256sum >/dev/null 2>&1; then
    echo "# sha256sum not found — skipping verification" >&2
    TEST_SHA256=""
  fi

  [[ "$MAX_JOBS" =~ ^[1-9][0-9]*$ ]] || {
    echo "error: -j must be a positive integer: $MAX_JOBS" >&2
    exit 1
  }

  local -A seen=()
  local -a mirrors=()
  local m
  local key

  for m in "${CANDIDATES[@]}" "${EXTRA_MIRRORS[@]}"; do
    key="${m:-__direct__}"
    [[ -z "${seen[$key]+x}" ]] || continue
    mirrors+=("$m")
    seen[$key]=1
  done

  local tmp
  tmp="$(mktemp -d --tmpdir find-fastest-mirror.XXXXXX)"
  TEMP_DIR="$tmp"

  local -a rank=()
  local chosen
  local chosen_lat
  local pref_lat
  local result
  # shellcheck disable=SC2034
  local -A valid=()

  probe mirrors "$tmp" rank chosen chosen_lat pref_lat valid

  echo "# mirror latency ranking (fastest first):"
  printf '%s\n' "${rank[@]}" | sort -t' ' -k1 -n | while IFS=' ' read -r lat size speed name valid_flag; do
    local tag=""
    [[ "${valid_flag:-1}" == 0 ]] && tag=" [VERIFY FAILED]"
    if [[ "$lat" == 99999 ]]; then
      printf '#   %s  %-s%s\n' "$lat" "$name" "$tag"
    else
      printf '#   %s  %s  %s  %-s%s\n' "$lat" "$(bytes_to_human "${size:-0}")" "$(speed_human "${speed:-0}")" "$name" "$tag"
    fi
  done

  if (( $(echo "$chosen_lat == 99999" | bc -l) )) ; then
    if [[ -n "$TEST_SHA256" ]]; then
      echo "#   all mirrors failed verification of $TEST_URL"
    else
      echo "#   all mirrors failed"
    fi
    result="$PREFERRED_MIRROR"
  elif (( $(echo "$chosen_lat == $pref_lat" | bc -l) )) && [[ "$chosen" != "$PREFERRED_MIRROR" ]]; then
    result="$PREFERRED_MIRROR"
  else
    result="$chosen"
  fi

  echo
  echo "export DOTFILES_MIRROR=\"$result\""
}

PROBES=3
TIMEOUT_CONNECT=5
TIMEOUT_MAX=8
MAX_JOBS=8
TEST_PATH="github.com/kibaamor/ipstream/releases/download/v0.1.8/ipstream_0.1.8_linux_amd64.tar.gz"
TEST_SHA256="20de2924da58f839d6f6ca37f592bc262a10a9f6d108181b8777c300c98e319d"
EXTRA_MIRRORS=()

while getopts "p:c:m:j:t:x:s:h" opt; do
  case "$opt" in
    p) PROBES="$OPTARG" ;;
    c) TIMEOUT_CONNECT="$OPTARG" ;;
    m) TIMEOUT_MAX="$OPTARG" ;;
    j) MAX_JOBS="$OPTARG" ;;
    t) TEST_PATH="$OPTARG" ;;
    x) EXTRA_MIRRORS+=("$OPTARG") ;;
    s) TEST_SHA256="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

TEST_URL="https://${TEST_PATH}"
TEMP_DIR=""

cleanup() {
  if [[ -n "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
  fi
}

trap cleanup EXIT

main
