#!/bin/bash

cd "$(dirname -- "${BASH_SOURCE[0]}")" || exit

filename="./home/.chezmoidata/versions.yaml"

repos=(
    "romkatv/powerlevel10k"
    "zsh-users/zsh-autosuggestions"
    "zsh-users/zsh-syntax-highlighting"
    "MichaelAquilina/zsh-you-should-use"

    "junegunn/vim-plug"

    "dandavison/delta"
    "sharkdp/bat"
    "sharkdp/fd"
    "junegunn/fzf"
    "direnv/direnv"
    "BurntSushi/ripgrep"
    "lsd-rs/lsd"
    "muesli/duf"
    "FiloSottile/age"
    "tldr-pages/tlrc"
    "fatedier/frp"
    "bcicen/ctop"
    "kubecolor/kubecolor"
    "ahmetb/kubectx"
    "wagoodman/dive"
    "jesseduffield/lazydocker"
    "jqlang/jq"
    "mikefarah/yq"
    "dundee/gdu"
    "zu1k/nali"
    "alexellis/arkade"
    "FiloSottile/mkcert"
    "kubernetes-sigs/kind"

    "kubernetes/minikube"
    "derailed/k9s"
    "kubeshark/kubeshark"
    "helm/helm"
    "txn2/kubefwd"
)

echo "versions:" >$filename

for repo in "${repos[@]}"; do
    echo "processing repo: $repo"

    echo "  # https://github.com/$repo" >>$filename

    name=$(echo "$repo" | cut -d '/' -f 2 | tr -d '-')
    #version=$(curl -s -L https://api.github.com/repos/$repo/releases/latest | jq '.tag_name' -r | tr -d '[a-z][A-Z] -')
    version=$(
        gh api \
            --method GET \
            --header 'Accept: application/vnd.github+json' \
            --jq '.tag_name' \
            "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null | grep -v 'Not Found' | tr -d '[a-z][A-Z] -'
    )
    if [[ -z "${version}" ]]; then
        version=$(
            gh api \
                --method GET \
                --header 'Accept: application/vnd.github+json' \
                --jq '.[0].name' \
                "https://api.github.com/repos/$repo/tags" | tr -d '[a-z][A-Z] -'
        )
    fi

    echo "  $name: $version" >>$filename

    sleep 1s
done
