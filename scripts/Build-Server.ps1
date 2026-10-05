# Builds the server for Windows and Linux into .\dist\<rid> (self-contained; launchers and test certificates included).
#   powershell -ExecutionPolicy Bypass -File .\scripts\Build-Server.ps1 [-Dotnet <path to dotnet>] [-Rids win-x64,linux-x64]
param(
    [string]$Dotnet = 'dotnet',
    [string[]]$Rids = @('win-x64', 'linux-x64'),
    [string]$OutputDirectory
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $repo 'dist' }
$project = Join-Path $repo 'server\Servers\MultiSocks\MultiSocks.csproj'

foreach ($rid in $Rids) {
    $out = Join-Path $OutputDirectory $rid
    Write-Host "Publishing $rid -> $out"
    & $Dotnet publish $project -c Release -r $rid --self-contained true -o $out --nologo -v quiet
    if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed for $rid" }

    $launchers = if ($rid -like 'win*') { 'win' } else { 'linux' }
    Copy-Item (Join-Path $PSScriptRoot "$launchers\*") $out -Force
    $certDir = Join-Path $out 'certs'
    New-Item -ItemType Directory -Path $certDir -Force | Out-Null
    Copy-Item (Join-Path $PSScriptRoot 'certs\*') $certDir -Force
}
Write-Host "Done. Run the launcher in each dist\<rid> folder (see docs\SETUP.md)."
