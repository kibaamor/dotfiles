# https://github.com/neersighted/dotfiles/blob/master/home/.chezmoiscripts/run_onchange_after_windows_preferences.ps1

# Re-execute as admin if we're not already elevated.
if (!(new-object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $elevated = new-object System.Diagnostics.ProcessStartInfo 'powershell.exe'
    $elevated.Arguments = $myInvocation.MyCommand.Definition + @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'hidden')
    $elevated.Verb = 'runas'
    $child = [System.Diagnostics.Process]::Start($elevated)
    $child.WaitForExit()
    return
}

# Set my shell preferences.
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name Hidden -Value 1
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name HideFileExt -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name ShowSuperHidden -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name HideDrivesWithNoMedia -Value 1
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name NavPaneExpandToCurrentFolder -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name NavPaneShowAllFolders -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name LaunchTo -Value 1
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name MMTaskbarMode -Value 2

# Add %USERPROFILE%\.local\bin to the PATH.
$bin = "$env:USERPROFILE\.local\bin"
$path = [Environment]::GetEnvironmentVariable('PATH', 'User').Split(';')
if (!$path.Contains($bin)) {
    Write-Host "Adding $bin to PATH"
    $path = [String]::Join(';', $path + $PSScriptRoot)
    [Environment]::SetEnvironmentVariable('PATH', $path, 'User')
}

{{ range $feature := .windows.features }}
    Write-Host 'Enable {{ $feature }}...'
    Enable-WindowsOptionalFeature -Online -FeatureName '{{ $feature }}'
{{ end }}

{{ range $package := .windows.packages }}
    Write-Host 'Install {{ $package }}...'
    winget install --id '{{ $package }}'
{{ end }}
