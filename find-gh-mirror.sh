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
Usage: find-gh-mirror.sh [OPTIONS]

Probe GitHub mirror candidates and export the fastest one.

Options:
  -p N    Number of probes per mirror (default: $PROBES)
  -c N    Connect timeout in seconds (default: $TIMEOUT_CONNECT)
  -m N    Max time per probe in seconds (default: $TIMEOUT_MAX)
  -j N    Max concurrent probes (default: $MAX_JOBS)
  -t URL  Test path (default: $TEST_PATH)
  -x URL  Add an extra mirror to test (can be repeated, use "" for direct)
  -s SHA  Expected SHA256 of the test file (set to empty to skip verification)
  -q      Quiet mode: only print the final export line
  -h      Show this help
EOF
  exit 0
}

die() { echo "error: $*" >&2; exit 1; }
log()  { [[ "$QUIET" == 0 ]] && echo "# $*" >&2; true; }
req()  { command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"; }

human() {
  local v="${1:-0}" suffix="${2:-}" div
  for div in 1073741824:GB 1048576:MB 1024:KB; do
    if (( $(echo "$v >= ${div%%:*}" | bc -l) )); then
      printf '%.1f%s%s' "$(echo "$v / ${div%%:*}" | bc -l)" "${div##*:}" "$suffix"; return
    fi
  done
  printf '%sB%s' "$v" "$suffix"
}

slugify() { local s="${1:-direct}"; printf '%s' "${s//[^a-zA-Z0-9]/_}"; }
url_for() { [[ -z "$1" ]] && echo "$TEST_URL" || echo "$1/$TEST_URL"; }
median() {
  local f="$1" n count
  n=$(wc -l < "$f" 2>/dev/null) && ((n)) || { echo "99999 0 0"; return; }
  count=$(( (n + 1) / 2 ))
  sort -t' ' -k1 -n "$f" 2>/dev/null | sed -n "${count}p"
}

probe() {
  local -n _mirrors="$1"
  local tmp="$2"
  local -n _rank="$3"
  local -n _best="$4"
  local -n _best_lat="$5"
  local -n _pref_lat="$6"
  local pids=() m slug times dl url label sha
  local -A valid=()

  for m in "${_mirrors[@]}"; do
    slug="$(slugify "$m")"
    times="$tmp/${slug}.times"
    label="${m:-direct}"
    url="$(url_for "$m")"

    log "probing $label ($PROBES probes)..."

    for ((i = 0; i < PROBES; i++)); do
      curl -L --connect-timeout "$TIMEOUT_CONNECT" --max-time "$TIMEOUT_MAX" \
        --silent --output /dev/null \
        --write-out '%{time_total} %{size_download} %{speed_download}\n' "$url" >>"$times" 2>/dev/null &
      pids+=("$!")
    done

    if [[ -n "$TEST_SHA256" ]]; then
      log "verifying $label..."
      dl="$tmp/${slug}.dl"
      (
        sha=$(curl -L --connect-timeout "$TIMEOUT_CONNECT" --max-time "$TIMEOUT_MAX" \
          --silent -o "$dl" --write-out '' "$url" 2>/dev/null && sha256sum "$dl" | awk '{print $1}' || true)
        rm -f "$dl"
        [[ "$sha" == "$TEST_SHA256" ]] && echo "${slug}:1" || echo "${slug}:0"
      ) >>"$tmp/_verify" 2>/dev/null &
      pids+=("$!")
    fi

    while (( ${#pids[@]} >= MAX_JOBS )); do
      wait "${pids[0]}" || true; pids=("${pids[@]:1}")
    done
  done
  for pid in "${pids[@]}"; do wait "$pid" || true; done

  if [[ -n "$TEST_SHA256" ]]; then
    while IFS=: read -r vslug vval; do valid["$vslug"]="$vval"; done < "$tmp/_verify"
  fi

  local row lat size speed
  _best_lat=99999
  _pref_lat=99999

  for m in "${_mirrors[@]}"; do
    slug="$(slugify "$m")"
    label="${m:-direct}"
    row="$(median "$tmp/${slug}.times")"
    lat="$(echo "$row" | awk '{print $1}')"
    size="$(echo "$row" | awk '{print $2}')"
    speed="$(echo "$row" | awk '{print $3}')"

    if [[ -z "$lat" || "$lat" == 99999 ]]; then
      _rank+=("$lat $label ${valid["$slug"]:-1}")
    else
      _rank+=("$(printf '%s %s %s %s %s' "$lat" "$size" "$speed" "$label" "${valid["$slug"]:-1}")")
    fi

    if (( $(echo "$lat < $_best_lat" | bc -l) )) && [[ "${valid[$slug]:-1}" != 0 ]]; then
      _best_lat="$lat"; _best="$m"
    fi
    [[ "$m" == "$PREFERRED_MIRROR" ]] && _pref_lat="$lat" || true
  done
}

main() {
  req curl

  if [[ -n "$TEST_SHA256" ]] && ! command -v sha256sum >/dev/null 2>&1; then
    log "sha256sum not found — skipping verification"
    TEST_SHA256=""
  fi

  [[ "$MAX_JOBS" =~ ^[1-9][0-9]*$ ]] || die "-j must be a positive integer: $MAX_JOBS"

  local -A seen=()
  local -a mirrors=()
  local m key
  for m in "${CANDIDATES[@]}" "${EXTRA_MIRRORS[@]}"; do
    key="${m:-__direct__}"
    [[ -z "${seen[$key]+x}" ]] || continue
    mirrors+=("$m"); seen[$key]=1
  done

  local tmp
  tmp="$(mktemp -d --tmpdir find-gh-mirror.XXXXXX)"
  TEMP_DIR="$tmp"

  local -a rank=()
  local best best_lat pref_lat
  probe mirrors "$tmp" rank best best_lat pref_lat

  if [[ "$QUIET" == 0 ]]; then
    echo "# mirror latency ranking (fastest first):"
    printf '%s\n' "${rank[@]}" | sort -t' ' -k1 -n | while IFS=' ' read -r lat size speed name vf; do
      local tag=""
      [[ "${vf:-1}" == 0 ]] && tag=" [VERIFY FAILED]" || true
      if [[ "$lat" == 99999 ]]; then
        printf '#   %s  %-s%s\n' "$lat" "$name" "$tag"
      else
        printf '#   %s  %s  %s  %-s%s\n' "$lat" "$(human "${size:-0}")" "$(human "${speed:-0}" /s)" "$name" "$tag"
      fi
    done
  fi

  local result
  if (( $(echo "$best_lat == 99999" | bc -l) )); then
    result="$PREFERRED_MIRROR"
  elif (( $(echo "$best_lat == $pref_lat" | bc -l) )) && [[ "$best" != "$PREFERRED_MIRROR" ]]; then
    result="$PREFERRED_MIRROR"
  else
    result="$best"
  fi

  if [[ "$QUIET" == 0 ]]; then echo; echo "export DOTFILES_MIRROR=\"$result\""
  else echo "export DOTFILES_MIRROR=\"$result\""; fi
}

QUIET=0

PROBES=3
TIMEOUT_CONNECT=5
TIMEOUT_MAX=8
MAX_JOBS=8
TEST_PATH="github.com/kibaamor/ipstream/releases/download/v0.1.8/ipstream_0.1.8_linux_amd64.tar.gz"
TEST_SHA256="20de2924da58f839d6f6ca37f592bc262a10a9f6d108181b8777c300c98e319d"
EXTRA_MIRRORS=()

while getopts "p:c:m:j:t:x:s:qh" opt; do
  case "$opt" in
    p) PROBES="$OPTARG" ;;
    c) TIMEOUT_CONNECT="$OPTARG" ;;
    m) TIMEOUT_MAX="$OPTARG" ;;
    j) MAX_JOBS="$OPTARG" ;;
    t) TEST_PATH="$OPTARG" ;;
    x) EXTRA_MIRRORS+=("$OPTARG") ;;
    s) TEST_SHA256="$OPTARG" ;;
    q) QUIET=1 ;;
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
