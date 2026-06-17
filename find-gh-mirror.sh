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
  -s SHA  Expected SHA256 of the test file (empty to skip verification)
  -q      Quiet mode: only print the final export line
  -h      Show this help
EOF
  exit 0
}

die() { echo "error: $*" >&2; exit 1; }
log() { [[ "$QUIET" == 0 ]] && echo "# $*" >&2 || true; }

human() {
  local v="${1:-0}" suffix="${2:-}" div n d
  for div in 1073741824:GB 1048576:MB 1024:KB; do
    n="${div%%:*}" d="${div##*:}"
    if (( v >= n )); then
      printf '%.1f%s%s' "$(echo "$v / $n" | bc -l)" "$d" "$suffix"; return
    fi
  done
  printf '%sB%s' "$v" "$suffix"
}

slugify() { printf '%s' "${1//[^a-zA-Z0-9]/_}"; }
url_for()  { [[ -z "$1" ]] && echo "$TEST_URL" || echo "$1/$TEST_URL"; }

median() {
  local f="$1" n count
  n=$(wc -l < "$f" 2>/dev/null) || true
  if [[ -z "$n" || "$n" -eq 0 ]]; then
    echo "99999 0 0 0 0"
    return
  fi
  count=$(( (n + 1) / 2 ))
  sort -t' ' -k1 -n "$f" 2>/dev/null | sed -n "${count}p"
}

# Probe all mirrors, writing one line per mirror to $out:
#   lat|size|speed|mirror_label|pass_count|total_count|raw_mirror
probe() {
  local -n _mirrors="$1"
  local tmp="$2"
  local out="$3"
  local pids=() m

  for m in "${_mirrors[@]}"; do
    local slug label url
    slug="$(slugify "${m:-direct}")"
    label="${m:-direct}"
    url="$(url_for "$m")"

    log "probing $label ($PROBES probes)..."

    for ((i = 0; i < PROBES; i++)); do
      (
        local dl="$tmp/${slug}_${i}.dl"
        local lat=99999 size=0 speed=0 vf=0

        local info
        info=$(curl -L --connect-timeout "$TIMEOUT_CONNECT" --max-time "$TIMEOUT_MAX" \
          --silent -o "$dl" \
          --write-out '%{time_total} %{size_download} %{speed_download}' "$url" 2>/dev/null || true) || true

        if [[ -n "$info" ]]; then
          IFS=' ' read -r lat size speed <<<"$info"
          if [[ -n "$TEST_SHA256" ]]; then
            local sha
            sha=$(sha256sum "$dl" 2>/dev/null | awk '{print $1}' || true)
            [[ "$sha" == "$TEST_SHA256" ]] && vf=1
          fi
        fi
        rm -f "$dl"
        printf '%s %s %s %s\n' "$lat" "$size" "$speed" "$vf" >>"$tmp/${slug}.times"
      ) &
      pids+=("$!")
    done

    while (( ${#pids[@]} >= MAX_JOBS )); do
      wait "${pids[0]}" || true; pids=("${pids[@]:1}")
    done
  done
  for pid in "${pids[@]}"; do wait "$pid" || true; done

  for m in "${_mirrors[@]}"; do
    local slug label row lat size speed pass tot
    slug="$(slugify "${m:-direct}")"
    label="${m:-direct}"
    row="$(median "$tmp/${slug}.times")"
    lat="$(echo "$row" | awk '{print $1}')"
    size="$(echo "$row" | awk '{print $2}')"
    speed="$(echo "$row" | awk '{print $3}')"

    pass=0 tot=0
    if [[ -n "$TEST_SHA256" ]] && [[ -f "$tmp/${slug}.times" ]]; then
      while read -r _ _ _ vf || [[ -n "$vf" ]]; do
        [[ -z "$vf" ]] && continue
        tot=$(( tot + 1 ))
        [[ "$vf" == 1 ]] && pass=$(( pass + 1 )) || true
      done < "$tmp/${slug}.times"
    fi

    printf '%s|%s|%s|%s|%s|%s|%s\n' "$lat" "$size" "$speed" "$label" "$pass" "$tot" "$m" >>"$out"
  done
}

main() {
  command -v curl >/dev/null 2>&1 || die "required command not found: curl"

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

  local tmp rankfile
  tmp="$(mktemp -d --tmpdir find-gh-mirror.XXXXXX)"
  TEMP_DIR="$tmp"
  rankfile="$tmp/rank.txt"
  probe mirrors "$tmp" "$rankfile"

  local best=""
  local best_lat=99999
  local pref_lat=99999

  if [[ "$QUIET" == 0 ]]; then
    echo "# mirror latency ranking (fastest first):"
  fi

  local sorted
  sorted=$(sort -t'|' -k1 -n "$rankfile")

  while IFS='|' read -r lat size speed name vpas vtot raw; do
    [[ -z "$lat" ]] && continue

    if [[ "$QUIET" == 0 ]]; then
      local tag=""
      if [[ -n "$TEST_SHA256" ]] && [[ "${vtot:-0}" -gt 0 ]]; then
        if [[ "$vpas" == "$vtot" ]]; then tag=" [verify: ${vpas}/${vtot} OK]"
        else tag=" [verify: ${vpas}/${vtot}]"; fi
      fi
      if [[ "$lat" == 99999 ]]; then
        printf '#   %s  %-s%s\n' "$lat" "$name" "$tag"
      else
        printf '#   %s  %s  %s  %-s%s\n' "$lat" "$(human "${size:-0}")" "$(human "${speed:-0}" /s)" "$name" "$tag"
      fi
    fi

    if [[ -z "$best" ]] || { [[ "${vpas:-0}" == "${vtot:-0}" ]] && (( $(echo "$lat < $best_lat" | bc -l) )); }; then
      if [[ "${vpas:-0}" == "${vtot:-0}" && "$vtot" -gt 0 ]] || [[ -z "$TEST_SHA256" ]]; then
        best="$raw"
        best_lat="$lat"
        break  # rows sorted by latency; first eligible is always fastest
      fi
    fi

    [[ "$raw" == "$PREFERRED_MIRROR" ]] && pref_lat="$lat" || true
  done <<<"$sorted"

  local result
  if [[ "$best_lat" == 99999 ]]; then
    result="$PREFERRED_MIRROR"
  elif [[ "$best_lat" == "$pref_lat" ]] && [[ "$best" != "$PREFERRED_MIRROR" ]]; then
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
  if [[ -n "${TEMP_DIR:-}" ]]; then
    rm -rf "$TEMP_DIR"
  fi
}

trap cleanup EXIT

main
