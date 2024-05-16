# winget install --id Microsoft.Powershell -s winget
# winget install JanDeDobbeleer.OhMyPosh -s winget

oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\markbull.omp.json" | Invoke-Expression

if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    kubectl completion powershell | Out-String | Invoke-Expression

    if (Get-Command kubecolor -ErrorAction SilentlyContinue) {
        Set-Alias -Name kubectl -Value kubecolor
        Register-ArgumentCompleter -CommandName 'kubecolor' -ScriptBlock $__kubectlCompleterBlock
    }

    Set-Alias -Name k -Value kubectl
    Register-ArgumentCompleter -CommandName 'k' -ScriptBlock $__kubectlCompleterBlock
}

if (Get-Command minikube -ErrorAction SilentlyContinue) {
    minikube completion powershell | Out-String | Invoke-Expression

    Set-Alias -Name mk -Value minikube
    Register-ArgumentCompleter -CommandName 'mk' -ScriptBlock ${__minikubeCompleterBlock}
}

# if (Get-Command kind -ErrorAction SilentlyContinue) {
#     kind completion powershell | Out-String | Invoke-Expression
# }

if (Get-Command helm -ErrorAction SilentlyContinue) {
    helm completion powershell | Out-String | Invoke-Expression
}

# if (Get-Command lsd -ErrorAction SilentlyContinue) {
#     Set-Alias -Name ls -Value lsd
# }

if (Get-Command frpc -ErrorAction SilentlyContinue) {
    frpc completion powershell | Out-String | Invoke-Expression
}
if (Get-Command frps -ErrorAction SilentlyContinue) {
    frps completion powershell | Out-String | Invoke-Expression
}

if (Get-Command k9s -ErrorAction SilentlyContinue) {
    k9s completion powershell | Out-String | Invoke-Expression
}

if (Get-Command yq -ErrorAction SilentlyContinue) {
    yq shell-completion powershell | Out-String | Invoke-Expression
}

if (Get-Command nali -ErrorAction SilentlyContinue) {
    nali completion powershell | Out-String | Invoke-Expression
}

if (Get-Command kubefwd -ErrorAction SilentlyContinue) {
    kubefwd completion powershell | Out-String | Invoke-Expression
}

if (Get-Command arkade -ErrorAction SilentlyContinue) {
    # arkade completion powershell | Out-String | Invoke-Expression
}

if (Get-Command kubeshark -ErrorAction SilentlyContinue) {
    $env:KUBESHARK_DISABLE_VERSION_CHECK = "true"
    kubeshark completion powershell | Out-String | Invoke-Expression
}

if (Get-Command chezmoi -ErrorAction SilentlyContinue) {
    chezmoi completion powershell | Out-String | Invoke-Expression
}
