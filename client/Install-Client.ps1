# Per-PC client setup. Run in an ELEVATED PowerShell:
#   powershell -ExecutionPolicy Bypass -File .\Install-Client.ps1 -GameDirectory "<folder with BurnoutParadise.exe>" -ServerAddress 192.168.1.50
#
# 1. Verifies YOUR installed BurnoutParadise.exe (tested Steam build 1.0.0.1) and writes a separate
#    BurnoutParadise.private.exe beside it. The original executable is never modified.
# 2. Writes steam_appid.txt (24740) so Steam recognises the copy as the owned game. Steam must be running.
# 3. Adds the pcburnout08.ea.com hosts entry and a LAN firewall rule for the game's peer UDP ports.
# Undo:  .\Install-Client.ps1 -Remove [-GameDirectory "<folder>"]
#Requires -RunAsAdministrator
param(
    [string]$GameDirectory,
    [string]$ServerAddress,
    [switch]$Remove
)
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot

if ($Remove) {
    & (Join-Path $here 'Set-PrivateEndpoint.ps1') -Action Remove
    & (Join-Path $here 'Set-PrivateFirewall.ps1') -Action Remove
    if ($GameDirectory) {
        $gameDir = (Resolve-Path -LiteralPath $GameDirectory).Path
        $private = Join-Path $gameDir 'BurnoutParadise.private.exe'
        if (Test-Path -LiteralPath $private) { Remove-Item -LiteralPath $private -Force }
        $appId = Join-Path $gameDir 'steam_appid.txt'
        if ((Test-Path -LiteralPath $appId) -and ((Get-Content -LiteralPath $appId -Raw).Trim() -eq '24740')) {
            Remove-Item -LiteralPath $appId -Force
        }
    }
    Write-Host 'Removed the hosts redirect and firewall rule (and the private copy, if -GameDirectory was given).'
    return
}

if (-not $GameDirectory -or -not $ServerAddress) {
    throw 'Both -GameDirectory and -ServerAddress are required.'
}
$gameDir = (Resolve-Path -LiteralPath $GameDirectory).Path
& (Join-Path $here 'Build-PrivateGameCopy.ps1') -GameDirectory $gameDir
$appId = Join-Path $gameDir 'steam_appid.txt'
if (-not (Test-Path -LiteralPath $appId)) {
    [System.IO.File]::WriteAllText($appId, '24740')
}
& (Join-Path $here 'Set-PrivateEndpoint.ps1') -Action Install -ServerAddress $ServerAddress
& (Join-Path $here 'Set-PrivateFirewall.ps1') -Action Install
Write-Host ''
Write-Host "Done. Start Steam, then launch BurnoutParadise.private.exe from inside: $gameDir"
Write-Host "Server address: $ServerAddress. Run .\Check-Connection.ps1 -ServerAddress $ServerAddress to test the network path."
