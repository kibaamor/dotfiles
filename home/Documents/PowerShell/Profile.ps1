# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles
# $PROFILE | gm | ? membertype -eq noteproperty

$commandLine = [Environment]::CommandLine
$launchedForCommand = $commandLine -match "(?i)(^|\s)-(?:Command|c|File|f)(\s|$)"
$keepsShellOpen = $commandLine -match "(?i)(^|\s)-NoExit(\s|$)"
$isInteractiveSession = [Environment]::UserInteractive -and $Host.Name -eq "ConsoleHost" -and (-not $launchedForCommand -or $keepsShellOpen)

if (-not $isInteractiveSession) {
  return
}

function Get-ProfileCacheKey {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Parts
  )

  $bytes = [Text.Encoding]::UTF8.GetBytes(($Parts -join "`n"))
  $hash = [Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
  -join ($hash | ForEach-Object { $_.ToString("x2") })
}

function Invoke-CachedNativeExpression {
  param(
    [Parameter(Mandatory = $true)]
    [string]$CacheName,
    [Parameter(Mandatory = $true)]
    [string]$CommandName,
    [string[]]$Arguments = @(),
    [string[]]$DependencyPaths = @()
  )

  $command = Get-Command $CommandName -ErrorAction Stop
  $parts = @($command.Source, ($Arguments -join " "))
  $commandItem = Get-Item $command.Source -ErrorAction SilentlyContinue
  if ($commandItem) {
    $parts += "$($commandItem.FullName):$($commandItem.LastWriteTimeUtc.Ticks)"
  }

  foreach ($path in $DependencyPaths) {
    $item = Get-Item $path -ErrorAction SilentlyContinue
    if ($item) {
      $parts += "$($item.FullName):$($item.LastWriteTimeUtc.Ticks)"
    }
  }

  $key = Get-ProfileCacheKey -Parts $parts
  $cacheRoot = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "PowerShell\profile-cache"
  $cacheDir = Join-Path $cacheRoot $CacheName
  $cacheFile = Join-Path $cacheDir "$key.ps1"

  if (-not (Test-Path $cacheFile)) {
    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    & $command.Source @Arguments | Out-String | Set-Content -Path $cacheFile -Encoding UTF8
  }

  . $cacheFile
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

    $installPSResource = Get-Command Install-PSResource -ErrorAction SilentlyContinue
    if ($installPSResource) {
      $params = @{
        Name = $Name
        Scope = "CurrentUser"
        ErrorAction = "Stop"
      }
      if ($installPSResource.Parameters.ContainsKey("TrustRepository")) {
        $params.TrustRepository = $true
      }

      try {
        Install-PSResource @params
        Import-Module $Name -ErrorAction Stop
        return
      } catch {
        Write-Warning "Install-PSResource failed for $Name`: $($_.Exception.Message)"
      }
    } else {
      Write-Warning "Install-PSResource is not available."
    }

    if (Get-Command Install-Module -ErrorAction SilentlyContinue) {
      try {
        Install-Module -Name $Name -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        Import-Module $Name -ErrorAction Stop
        return
      } catch {
        Write-Warning "Install-Module failed for $Name`: $($_.Exception.Message)"
      }
    } else {
      Write-Warning "Install-Module is not available."
    }
  }

  Write-Warning "Could not install module $Name."
}

Invoke-CachedNativeExpression -CacheName "oh-my-posh" -CommandName "oh-my-posh" -Arguments @("init", "pwsh", "--config", "$env:POSH_THEMES_PATH\markbull.omp.json") -DependencyPaths @("$env:POSH_THEMES_PATH\markbull.omp.json")

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

Ensure-Module "PSReadLine"
if (Get-Module -Name "PSReadLine") {
  Set-PSReadLineOption -BellStyle None
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -PredictionViewStyle ListView
  Set-PSReadLineOption -EditMode Windows
  Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
  Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
}

Ensure-Module "PSFzf"
if (Get-Module -Name "PSFzf") {
  $env:FZF_DEFAULT_COMMAND = "--strip-cwd-prefix --follow --hidden --exclude .git --exclude node_modules"
  $env:FZF_CTRL_T_COMMAND = "fd --type f $env:FZF_DEFAULT_COMMAND"
  $env:FZF_ALT_C_COMMAND = "fd --type d $env:FZF_DEFAULT_COMMAND"
  # CTRL-T Paste the selected files and directories onto the command-line
  $env:FZF_CTRL_T_OPTS = "`
    --height 100%`
    --preview 'bat -n --color=always --theme Dracula -r :1000 {}'`
    --bind 'ctrl-\:change-preview-window(down|hidden|)'`
    --color header:italic`
    --header 'Press ALT-/ to toggle line wrap, CTRL-\ to toggle preview (first 1000 lines only)'"
  # CTRL-R Paste the selected command from history onto the command-line
  $env:FZF_CTRL_R_OPTS = "`
    --height 100%`
    --preview 'bat -pl ps1 --color=always {f2..}'`
    --preview-window up:3:wrap`
    --bind 'ctrl-\:toggle-preview'`
    --color header:italic`
    --header 'Press ALT-/ to toggle line wrap, CTRL-\ to toggle preview'"
  # cd into the selected directory
  $env:FZF_ALT_C_OPTS = "--height 100% --preview 'lsd --tree {}'"
  Set-PSFzfOption -PSReadLineChordProvider "ctrl+t" -PSReadLineChordReverseHistory "ctrl+r" -EnableFd -EnableFzf -FzfCommand 'fzf --height 40% --reverse --inline-info --info=inline --ansi --preview "bat --style=numbers --color=always {}"'
}

try {
  $env:CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense"
  Invoke-CachedNativeExpression -CacheName "carapace" -CommandName "carapace" -Arguments @("_carapace")
} catch {
  Write-Warning "carapace initialization failed: $($_.Exception.Message)"
}
