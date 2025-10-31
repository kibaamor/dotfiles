FROM ubuntu:24.04

RUN set -eux \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt update \
    && apt dist-upgrade -y \
    && apt install -y --no-install-recommends openssh-client curl wget ca-certificates sudo tar xz-utils \
    && usermod -aG sudo ubuntu \
    && echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99_ubuntu_nopasswd \
    && chmod 440 /etc/sudoers.d/99_ubuntu_nopasswd \
    && apt autoremove -y --purge \
    && rm -fr -- /var/lib/apt/lists/* /tmp/*

# Some linux distros use 998 for docker group, whereas WSL will use group 999
# Ensure both are created and user is added to both
RUN set -eux; \
    export DOCKER_GID="$(getent group docker | cut -d: -f3 || true)"; \
    case "${DOCKER_GID}" in \
    "")  addgroup --gid 999 docker; addgroup --gid 998 docker2 ;; \
    999) addgroup --gid 998 docker2 ;; \
    998) addgroup --gid 999 docker2 ;; \
    *)   groupmod --gid 999 docker; addgroup --gid 998 docker2 ;; \
    esac; \
    usermod -aG docker ubuntu; \
    usermod -aG docker2 ubuntu;

USER ubuntu
WORKDIR /home/ubuntu

RUN set -eux \
    && export DEBIAN_FRONTEND=noninteractive \
    && export DOTFILES_INSTALL_EXTRA_BINS=1 \
    && export DOTFILES_INSTALL_ARKADE_BINS=1 \
    && export DOTFILES_CAN_SUDO=1 \
    && sh -c "$(curl kibazen.cn/dotfiles.sh)" \
    && echo exit 0 | script -qec zsh \
    && rm -fr -- typescript ~/.zsh_history ~/.cache/chezmoi \
    && find ~/.local/bin -type f ! -name 'upx' ! -name 'rfv' -exec ~/.local/bin/upx --best --lzma -q {} + \
    && sudo apt -y autoremove --purge \
    && sudo rm -fr -- /var/lib/apt/lists/* /tmp/*

CMD [ "/usr/bin/zsh" ]
