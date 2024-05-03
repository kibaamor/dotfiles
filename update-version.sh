#!/bin/bash

cd "$(dirname -- "${BASH_SOURCE[0]}")"

filename="./home/.chezmoidata/versions.yaml"

repos=(
    "romkatv/powerlevel10k"
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

    "txn2/kubefwd"
    "kubeshark/kubeshark"
    "kubernetes/minikube"
    "helm/helm"
    "derailed/k9s"
)

echo "versions:" > $filename

for repo in "${repos[@]}";
do
    echo "processing repo: $repo"

    echo "  # https://github.com/$repo" >> $filename
    name=$(echo $repo | cut -d '/' -f 2)
    version=$(curl -s -L https://api.github.com/repos/$repo/releases/latest | jq '.tag_name' -r | tr -d '[a-z][A-Z] -')
    echo "  $name: $version" >> $filename

    sleep 1s
done
