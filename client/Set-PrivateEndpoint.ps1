#Requires -RunAsAdministrator
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Install', 'Remove')]
    [string]$Action,

    [string]$ServerAddress
)

$ErrorActionPreference = 'Stop'
$domain = 'pcburnout08.ea.com'
$tag = '# burnout-private-pair'
$hostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
$backupDir = Join-Path $PSScriptRoot 'backups'

if ($Action -eq 'Install') {
    $parsed = [System.Net.IPAddress]::None
    if (-not [System.Net.IPAddress]::TryParse($ServerAddress, [ref]$parsed) -or
        $parsed.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
        throw 'Install requires -ServerAddress with the private server IPv4 address.'
    }
}

$lines = @(Get-Content -LiteralPath $hostsPath)
$owned = @($lines | Where-Object { $_ -match [regex]::Escape($tag) })
$conflicts = @($lines | Where-Object {
    $_ -notmatch '^\s*#' -and $_ -notmatch [regex]::Escape($tag) -and
    $_ -match "(?i)(^|\s)$([regex]::Escape($domain))(\s|$)"
})
if ($Action -eq 'Install' -and $conflicts.Count) {
    throw "An existing untagged hosts entry for $domain was found. Review it manually before installing this redirect."
}

$newLines = @($lines | Where-Object { $_ -notmatch [regex]::Escape($tag) })
if ($Action -eq 'Install') {
    $newLines += "$ServerAddress`t$domain`t$tag"
}

if (($newLines -join "`n") -eq ($lines -join "`n")) {
    Write-Host 'No change needed.'
    return
}

New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
$backupPath = Join-Path $backupDir ("hosts-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.bak')
Copy-Item -LiteralPath $hostsPath -Destination $backupPath -ErrorAction Stop

try {
    [System.IO.File]::WriteAllLines($hostsPath, $newLines, [System.Text.UTF8Encoding]::new($false))
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    Write-Host "$Action complete for $domain. Backup: $backupPath"
} catch {
    Copy-Item -LiteralPath $backupPath -Destination $hostsPath -Force
    throw
}

