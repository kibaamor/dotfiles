#!/bin/bash

command_exists() {
  # type -p "$1" | grep -v "not found" >/dev/null 2>&1
  command -v "$1" >/dev/null 2>&1
}

function update_git_config() {
  local config_file="$1"
  local key="$2"
  local value="$3"

  if [[ -n "$value" ]]; then
    local current_value
    current_value=$(git config --includes --global "$key")
    if [[ "$current_value" != "$value" ]]; then
      echo "Updating git config ('$config_file') $key from '$current_value' to '$value'"
      git config --file "$config_file" "$key" "$value"
    fi
  fi
}

enable_proxy() {
  export no_proxy=${default_no_proxy:-}
  export https_proxy=${default_proxy:-}
  export http_proxy=$https_proxy
  export ftp_proxy=$https_proxy

  export NO_PROXY=$no_proxy
  export HTTPS_PROXY=$https_proxy
  export HTTP_PROXY=$http_proxy
  export FTP_PROXY=$ftp_proxy
}

disable_proxy() {
  unset no_proxy
  unset https_proxy
  unset http_proxy
  unset ftp_proxy

  unset NO_PROXY
  unset HTTPS_PROXY
  unset HTTP_PROXY
  unset FTP_PROXY
}

flush_iptables() {
  cat <<-'EOF' | sudo bash
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -t raw -F
    iptables -t raw -X
    iptables -t raw -Z
    iptables -t mangle -F
    iptables -t mangle -X
    iptables -t mangle -Z
    iptables -t nat -F
    iptables -t nat -X
    iptables -t nat -Z
    iptables -t filter -F
    iptables -t filter -X
    iptables -t filter -Z
    iptables -t security -F
    iptables -t security -X
    iptables -t security -Z
EOF
}

flush_ip6tables() {
  cat <<-'EOF' | sudo bash
    ip6tables -P INPUT ACCEPT
    ip6tables -P FORWARD ACCEPT
    ip6tables -P OUTPUT ACCEPT
    ip6tables -t raw -F
    ip6tables -t raw -X
    ip6tables -t raw -Z
    ip6tables -t mangle -F
    ip6tables -t mangle -X
    ip6tables -t mangle -Z
    ip6tables -t nat -F
    ip6tables -t nat -X
    ip6tables -t nat -Z
    ip6tables -t filter -F
    ip6tables -t filter -X
    ip6tables -t filter -Z
    ip6tables -t security -F
    ip6tables -t security -X
    ip6tables -t security -Z
EOF
}

log_iptables_port() {
  if [[ $# -eq 0 ]]; then
    echo "must provide target port"
    return 1
  fi

  for port in "$@"; do
    echo "log port $port"
    cat <<-EOF | sudo bash
    iptables -A PREROUTING -t raw -p tcp --dport $port -j LOG --log-prefix "[PREROUTING:raw:$port] "
    iptables -A PREROUTING -t mangle -p tcp --dport $port -j LOG --log-prefix "[PREROUTING:mangle:$port] "
    iptables -A PREROUTING -t nat -p tcp --dport $port -j LOG --log-prefix "[PREROUTING:nat:$port] "
    iptables -A INPUT -t mangle -p tcp --dport $port -j LOG --log-prefix "[INPUT:mangle:$port] "
    iptables -A INPUT -t filter -p tcp --dport $port -j LOG --log-prefix "[INPUT:filter:$port] "
    iptables -A INPUT -t security -p tcp --dport $port -j LOG --log-prefix "[INPUT:security:$port] "
    iptables -A INPUT -t nat -p tcp --dport $port -j LOG --log-prefix "[INPUT:nat:$port] "
    iptables -A FORWARD -t mangle -p tcp --dport $port -j LOG --log-prefix "[FORWARD:mangle:$port] "
    iptables -A FORWARD -t filter -p tcp --dport $port -j LOG --log-prefix "[FORWARD:filter:$port] "
    iptables -A FORWARD -t security -p tcp --dport $port -j LOG --log-prefix "[FORWARD:security:$port] "
    iptables -A OUTPUT -t raw -p tcp --dport $port -j LOG --log-prefix "[OUTPUT:raw:$port] "
    iptables -A OUTPUT -t mangle -p tcp --dport $port -j LOG --log-prefix "[OUTPUT:mangle:$port] "
    iptables -A OUTPUT -t nat -p tcp --dport $port -j LOG --log-prefix "[OUTPUT:nat:$port] "
    iptables -A OUTPUT -t filter -p tcp --dport $port -j LOG --log-prefix "[OUTPUT:filter:$port] "
    iptables -A OUTPUT -t security -p tcp --dport $port -j LOG --log-prefix "[OUTPUT:security:$port] "
    iptables -A POSTROUTING -t mangle -p tcp --dport $port -j LOG --log-prefix "[POSTROUTING:mangle:$port] "
    iptables -A POSTROUTING -t nat -p tcp --dport $port -j LOG --log-prefix "[POSTROUTING:nat:$port] "
EOF
  done

  echo "If you can not find the log in 'dmesg' command, try execute command 'echo 1 > /proc/sys/net/netfilter/nf_log_all_netns'"
}

# https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/2254-cgroup-v2#phase-1-convert-from-cgroups-v1-settings-to-v2
cpu_shares_to_weight() {
  awk "BEGIN {printf \"%.3f\n\", 1 + (($1 - 2) * 9999) / 262142}"
}

cpu_weight_to_shares() {
  awk "BEGIN {printf \"%.3f\n\", (($1 - 1) * 262142) / 9999 + 2}"
}

# https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v1/index.html
# https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html
dump_docker_resources() {
  local container_id
  local cgroup_path

  container_id=$(docker inspect -f '{{ .Id }}' "$1")
  cgroup_path=$(find /sys/fs/cgroup -type d -name "*$container_id*")
  echo "cgroup_path: $cgroup_path"
  for file in cpu.max cpu.max.burst cpu.weight cpu.weight.nice \
    cpuset.cpus cpuset.cpus.effective cpuset.cpus.partition cpuset.mems cpuset.mems.effective \
    memory.current memory.low memory.high memory.min memory.max \
    memory.swap.current memory.swap.high memory.swap.max \
    memory.low memory.high memory.max memory.swap.current memory.swap.high memory.swap.max \
    cpu.stat cgroup.controllers cgroup.events memory.events pids.events \
    cpu.shares cpu.cfs_quota_us cpu.cfs_period_us memory.limit_in_bytes; do
    [[ -f "$cgroup_path/$file" ]] && echo "$file: $(tr '\n' ',' <"$cgroup_path/$file" | sed 's/,$/\n/')"
  done
}

setup_ssh_agent() {
  local env_file="$1"
  local socket_file="$2"
  shift 2
  local ssh_keys=("$@")

  mkdir -p -- "$(dirname "$env_file")"

  # shellcheck source=/dev/null
  [[ -f "$env_file" ]] && \. "$env_file" >/dev/null

  if ! kill -0 "$SSH_AGENT_PID" 2>/dev/null || [[ "$SSH_AUTH_SOCK" != "$socket_file" ]]; then
    rm -f -- "$env_file" "$socket_file"
    eval "$(ssh-agent -a "$socket_file" -s)" >/dev/null
    echo "export SSH_AUTH_SOCK=$socket_file" >"$env_file"
    echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >>"$env_file"
  fi

  local loaded_fingerprints
  loaded_fingerprints=$(ssh-add -l 2>/dev/null | awk '{print $2}' | tr '\n' ' ')

  for key in "${ssh_keys[@]}"; do
    [[ -f "$key" ]] || continue
    local fingerprint
    fingerprint=$(ssh-keygen -lf "$key" | awk '{print $2}')
    if [[ " $loaded_fingerprints " != *" $fingerprint "* ]]; then
      ssh-add "$key"
    fi
  done
}
