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
    && apt-get -y autoremove --purge \
    && rm -fr -- /var/lib/apt/lists/* \
    \
    LATEST_VERSION=$(wget -qO- https://api.github.com/repos/upx/upx/releases/latest | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4); \
    URL="https://github.com/upx/upx/releases/download/${LATEST_VERSION}/upx-${LATEST_VERSION#v}-amd64_linux.tar.xz"; \
    echo "Downloading $URL"; \
    wget -qO /tmp/upx.tar.xz "$URL"; \
    tar -xJf /tmp/upx.tar.xz -C /tmp; \
    mv /tmp/upx-${LATEST_VERSION#v}-amd64_linux/upx /tmp/upx; \
    chmod +x /tmp/upx; \
    find /root/.local/bin -type f -exec /tmp/upx --best --ultra-brute -q {} +; \
    rm -fr -- /tmp/*

WORKDIR /root
ENTRYPOINT [ "/usr/bin/zsh" ]
