# winget install --id Microsoft.Powershell -s winget
# winget install JanDeDobbeleer.OhMyPosh -s winget

oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\markbull.omp.json" | Invoke-Expression
