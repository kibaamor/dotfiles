FROM ubuntu:24.04

RUN set -ex \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt update \
    && apt dist-upgrade -y \
    && apt install -y curl openssh-client \
    && apt autoremove -y --purge \
    && rm -fr -- /var/lib/apt/lists/*

RUN set -ex \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt update \
    && sh -c "$(curl kibazen.cn/dotfiles.sh)"\
    && echo exit 0 | script -qec zsh \
    && rm -f -- typescript \
    && rm -fr -- /root/.cache/chezmoi \
    && apt-get -y autoremove --purge \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root
ENTRYPOINT [ "/usr/bin/zsh" ]
