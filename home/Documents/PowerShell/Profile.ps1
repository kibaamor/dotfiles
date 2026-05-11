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

$script:SkipModuleInstall = $false

function Invoke-ModuleInstall {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [Parameter(Mandatory = $true)]
    [string]$CommandName,
    [string[]]$SwitchNames = @(),
    [int]$TimeoutSeconds = 30
  )

  $job = Start-Job -ScriptBlock {
    param($ModuleName, $InstallCommandName, $InstallSwitchNames)

    $ProgressPreference = "SilentlyContinue"
    $params = @{
      Name = $ModuleName
      Scope = "CurrentUser"
      ErrorAction = "Stop"
    }

    foreach ($switchName in $InstallSwitchNames) {
      $params[$switchName] = $true
    }

    & $InstallCommandName @params
  } -ArgumentList $Name, $CommandName, $SwitchNames

  try {
    if (-not (Wait-Job -Job $job -Timeout $TimeoutSeconds)) {
      Stop-Job -Job $job -ErrorAction SilentlyContinue
      $script:SkipModuleInstall = $true
      throw "Timed out after $TimeoutSeconds seconds installing module $Name with $CommandName."
    }

    Receive-Job -Job $job -ErrorAction Stop | Out-Null
  } finally {
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
  }
}

function Ensure-Module {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  try {
    Import-Module $Name -ErrorAction Stop
    return
  } catch {
    if ($_.FullyQualifiedErrorId -notlike "Modules_ModuleNotFound*") {
      throw
    }

    Write-Host "Install module $Name..."
    if ($script:SkipModuleInstall) {
      Write-Warning "Skipping automatic install for $Name because a previous module install timed out."
      return
    }

    $installed = $false
    if (Get-Command Install-Module -ErrorAction SilentlyContinue) {
      try {
        Invoke-ModuleInstall -Name $Name -CommandName "Install-Module" -SwitchNames @("Force", "AllowClobber")
        $installed = $true
      } catch {
        Write-Warning "Install-Module failed for $Name`: $($_.Exception.Message)"
        if ($script:SkipModuleInstall) {
          return
        }
      }
    } else {
      Write-Warning "Install-Module is not available."
    }

    if (-not $installed) {
      $installPSResource = Get-Command Install-PSResource -ErrorAction SilentlyContinue
      if (-not $installPSResource) {
        Write-Warning "Install-PSResource is not available; cannot install $Name with the fallback installer."
        return
      }

      $switchNames = @()
      if ($installPSResource.Parameters.ContainsKey("TrustRepository")) {
        $switchNames += "TrustRepository"
      }

      try {
        Write-Warning "Trying Install-PSResource for $Name..."
        Invoke-ModuleInstall -Name $Name -CommandName "Install-PSResource" -SwitchNames $switchNames
        $installed = $true
      } catch {
        Write-Warning "Install-PSResource failed for $Name`: $($_.Exception.Message)"
        return
      }
    }
  }

  Import-Module $Name -ErrorAction Stop
}

Ensure-Module "Microsoft.PowerShell.PSResourceGet"

Ensure-Module "PSReadLine"
if (Get-Module -Name "PSReadLine") {
  Set-PSReadLineOption -BellStyle None
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -PredictionViewStyle ListView
  Set-PSReadLineOption -EditMode Windows
  Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

Ensure-Module "PSFzf"
if (Get-Module -Name "PSFzf") {
  $env:FZF_DEFAULT_COMMAND='--strip-cwd-prefix --follow --hidden --exclude .git --exclude node_modules'
  $env:FZF_CTRL_T_COMMAND="fd --type f $env:FZF_DEFAULT_COMMAND"
  $env:FZF_ALT_C_COMMAND="fd --type d $env:FZF_DEFAULT_COMMAND"
  # CTRL-T Paste the selected files and directories onto the command-line
  $env:FZF_CTRL_T_OPTS="`
    --height 100%`
    --preview 'bat -n --color=always --theme Dracula -r :1000 {}'`
    --bind 'ctrl-\:change-preview-window(down|hidden|)'`
    --color header:italic`
    --header 'Press ALT-/ to toggle line wrap, CTRL-\ to toggle preview (first 1000 lines only)'"
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
  Set-PSFzfOption -PSReadLineChordProvider 'ctrl+t' -PSReadLineChordReverseHistory 'ctrl+r' -EnableFd -EnableFzf -FzfCommand 'fzf --height 40% --reverse --inline-info --info=inline --ansi --preview "bat --style=numbers --color=always {}"'
}

Ensure-Module "Terminal-Icons"
Ensure-Module "z"
Ensure-Module "cd-extras"

try {
  $env:CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
  Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
  #Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
  carapace _carapace | Out-String | Invoke-Expression
} catch {
}
