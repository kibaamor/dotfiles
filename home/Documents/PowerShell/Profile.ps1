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

Import-Module PSReadLine
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows

if(Get-Module -ListAvailable -Name "PSFzf" -ErrorAction Stop) {
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

Import-Module Terminal-Icons
Import-Module z
Import-Module cd-extras
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

$env:CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
carapace _carapace | Out-String | Invoke-Expression
