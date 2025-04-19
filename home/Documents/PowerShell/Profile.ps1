# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles
# $PROFILE | gm | ? membertype -eq noteproperty

oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\markbull.omp.json" | Invoke-Expression

# WinGet (https://github.com/microsoft/winget-cli)
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
  param($wordToComplete, $commandAst, $cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
    $Local:word = $wordToComplete.Replace('"', '""')
    $Local:ast = $commandAst.ToString().Replace('"', '""')
    winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
      [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

$installedModules = Get-Module -ListAvailable | Select-Object -ExpandProperty Name -Unique

if (-not $installedModules.Contains("Microsoft.PowerShell.PSResourceGet")) {
  Write-Host "Install module Microsoft.PowerShell.PSResourceGet..."
  Install-Module -Name "Microsoft.PowerShell.PSResourceGet" -Force -AllowClobber -Scope CurrentUser
}

if (-not $installedModules.Contains("PSReadLine")) {
  Write-Host "Install module PSReadLine..."
  Install-Module -Name "PSReadLine" -Force -AllowClobber -Scope CurrentUser
}
if ($installedModules.Contains("PSReadLine")) {
  Import-Module PSReadLine
  Set-PSReadLineOption -BellStyle None
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -PredictionViewStyle ListView
  Set-PSReadLineOption -EditMode Windows
  Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

if (-not $installedModules.Contains("PSFzf")) {
  Write-Host "Install module PSFzf..."
  Install-Module -Name "PSFzf" -Force -AllowClobber -Scope CurrentUser
}
if ($installedModules.Contains("PSFzf")) {
  $env:FZF_DEFAULT_COMMAND='--strip-cwd-prefix --follow --hidden --exclude .git --exclude node_modules'
  $env:FZF_CTRL_T_COMMAND="fd --type f $env:FZF_DEFAULT_COMMAND"
  $env:FZF_ALT_C_COMMAND="fd --type d $env:FZF_DEFAULT_COMMAND"
  # CTRL-T Paste the selected files and directories onto the command-line
  $env:FZF_CTRL_T_OPTS="`
    --height 100%`
    --preview 'bat -n --color=always --theme Dracula -r :1000 {}'`
    --bind 'ctrl-\:change-preview-window(down|hidden|)'`
    --color header:italic`
    --header 'Press ALT-/ to toggle line wrap, CTRL-\ to toggle preview(Only first 1000 lines are showed)'"
  # CTRL-R Paste the selected command from history onto the command-line
  $env:FZF_CTRL_R_OPTS="`
    --height 100%`
    --preview 'bat -pl ps1 --color=always {f2..}'`
    --preview-window up:3:wrap`
    --bind 'ctrl-\:toggle-preview'`
    --color header:italic`
    --header 'Press ALT-/ to toggle line wrap, CTRL-\ to toggle preview'"
  # cd into the selected directory
  $env:FZF_ALT_C_OPTS="--height 100% --preview 'lsd --tree {}'"
  Import-Module PSFzf
  Set-PSFzfOption -PSReadLineChordProvider 'ctrl+t' -PSReadLineChordReverseHistory 'ctrl+r' -EnableFd -EnableFzf -FzfCommand 'fzf --height 40% --reverse --inline-info --info=inline --ansi --preview "bat --style=numbers --color=always {}"'
}

if (-not $installedModules.Contains("Terminal-Icons")) {
  Write-Host "Install module Terminal-Icons..."
  Install-Module -Name "Terminal-Icons" -Force -AllowClobber -Scope CurrentUser
}
if ($installedModules.Contains("Terminal-Icons")) {
  Import-Module Terminal-Icons
}

if (-not $installedModules.Contains("z")) {
  Write-Host "Install module z..."
  Install-Module -Name "z" -Force -AllowClobber -Scope CurrentUser
}
if ($installedModules.Contains("z")) {
  Import-Module z
}

if (-not $installedModules.Contains("cd-extras")) {
  Write-Host "Install module cd-extras..."
  Install-Module -Name "cd-extras" -Force -AllowClobber -Scope CurrentUser
}
if ($installedModules.Contains("cd-extras")) {
  Import-Module cd-extras
}

Remove-Variable -Name installedModules -ErrorAction SilentlyContinue

try {
  $env:CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
  Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
  #Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
  carapace _carapace | Out-String | Invoke-Expression
} catch {
}
