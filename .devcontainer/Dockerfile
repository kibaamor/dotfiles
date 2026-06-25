FROM ubuntu:24.04

RUN set -eux \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl openssh-client wget sudo tar xz-utils \
    && usermod -aG sudo ubuntu \
    && echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99_ubuntu_nopasswd \
    && chmod 0440 /etc/sudoers.d/99_ubuntu_nopasswd \
    && apt-get autoremove -y --purge \
    && rm -fr -- /var/lib/apt/lists/* /tmp/*

USER ubuntu
WORKDIR /home/ubuntu

RUN set -eux \
    && export DOTFILES_EXTRA_BINS=1 \
    && export DOTFILES_ARKADE_BINS=1 \
    && export DOTFILES_CAN_SUDO=1 \
    && sh -c "$(curl -fsLS https://get.chezmoi.io/lb)" -- init --apply kibaamor \
    && echo exit 0 | script -qec zsh \
    && rm -fr -- ~/typescript ~/.zsh_history ~/.cache/chezmoi \
    && find ~/.local/bin -type f ! -name 'upx' ! -name 'rfv' -exec sh -c '~/.local/bin/upx --best --lzma -q "$@"  || true' sh {} + \
    && sudo apt-get -y autoremove --purge \
    && sudo rm -fr -- /var/lib/apt/lists/* /tmp/*

CMD [ "/usr/bin/zsh" ]
