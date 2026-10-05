#Requires -RunAsAdministrator
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Install', 'Remove')]
    [string]$Action,

    [switch]$Server
)

$ErrorActionPreference = 'Stop'
$peerRule = 'BurnoutPrivatePair-Peer-UDP'
$serverRule = 'BurnoutPrivatePair-Server-TCP'

if ($Action -eq 'Remove') {
    Remove-NetFirewallRule -Name $peerRule -ErrorAction SilentlyContinue
    if ($Server) { Remove-NetFirewallRule -Name $serverRule -ErrorAction SilentlyContinue }
    Write-Host 'Private Burnout firewall rules removed.'
    return
}

if (-not (Get-NetFirewallRule -Name $peerRule -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name $peerRule -DisplayName 'Burnout Private Pair peer traffic' `
        -Direction Inbound -Action Allow -Protocol UDP -LocalPort 1000,9615,9640 `
        -Profile Private -RemoteAddress LocalSubnet | Out-Null
}

if ($Server -and -not (Get-NetFirewallRule -Name $serverRule -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name $serverRule -DisplayName 'Burnout Private Pair server' `
        -Direction Inbound -Action Allow -Protocol TCP -LocalPort 21841,21842 `
        -Profile Private -RemoteAddress LocalSubnet | Out-Null
}

Write-Host 'Private Burnout firewall rules installed for local-subnet traffic.'
