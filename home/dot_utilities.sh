#!/bin/bash

command_exists() {
  type -p "$1" | grep -v "not found" >/dev/null 2>&1
}

enable_proxy() {
  export no_proxy=$default_no_proxy
  export https_proxy=$default_proxy
  export http_proxy=$default_proxy
  export ftp_proxy=$default_proxy

  export NO_PROXY=$no_proxy
  export HTTPS_PROXY=$https_proxy
  export HTTP_PROXY=$http_proxy
  export FTP_PROXY=$ftp_proxy
}

disable_proxy() {
  export no_proxy=
  export https_proxy=
  export http_proxy=
  export ftp_proxy=

  export NO_PROXY=$no_proxy
  export HTTPS_PROXY=$https_proxy
  export HTTP_PROXY=$http_proxy
  export FTP_PROXY=$ftp_proxy
}

flush_iptables() {
  cat <<- 'EOF' | sudo bash
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
  cat <<- 'EOF' | sudo bash
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
  if [[ $# -eq 0 ]] ; then
    echo "must provide target port"
    return 1
  fi

  for port in "$@"; do
    echo "log port $port"
  cat <<- EOF | sudo bash
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
