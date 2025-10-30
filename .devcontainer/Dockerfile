FROM ubuntu:24.04

RUN set -eux \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt update \
    && apt dist-upgrade -y \
    && apt install -y --no-install-recommends openssh-client curl wget ca-certificates tar xz-utils \
    && apt autoremove -y --purge \
    && rm -fr -- /var/lib/apt/lists/* /tmp/*

RUN set -eux \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt update \
    && sh -c "$(curl kibazen.cn/dotfiles.sh)"\
    && echo exit 0 | script -qec zsh \
    && rm -f -- typescript \
    && rm -fr -- /root/.cache/chezmoi \
    && find /root/.local/bin -type f ! -name 'upx' -exec /root/.local/bin/upx --best --lzma -q {} + \
    && apt-get -y autoremove --purge \
    && rm -fr -- /var/lib/apt/lists/* /tmp/*

WORKDIR /root
ENTRYPOINT [ "/usr/bin/zsh" ]
