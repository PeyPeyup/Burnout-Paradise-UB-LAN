# Starts the private Burnout Paradise server on Windows.
#   .\Start-Server.ps1 -ServerAddress 192.168.1.50 [-MaxUsers 2]
# ServerAddress is the IPv4 address the GAME CLIENTS will connect to (this PC's LAN/public IP).
param(
    [Parameter(Mandatory = $true)][string]$ServerAddress,
    [int]$MaxUsers = 2
)
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$static = Join-Path $here 'static'
New-Item -ItemType Directory -Path $static -Force | Out-Null
foreach ($n in 'otg3.cer', 'otg3.key', 'fesl.key') {
    Copy-Item (Join-Path $here "certs\$n") (Join-Path $static "private-$n") -Force
}
$config = [ordered]@{
    config_version = 4
    server_bind_address = $ServerAddress
    rpcs3_workarounds = $false
    private_pair_mode = $true
    private_max_users = $MaxUsers
    enable_blaze_encryption = $false
    dirtysocks_database_path = (Join-Path $static 'local-accounts.json')
    servers = @(
        [ordered]@{ type = 'Aries'; subtype = 'Redirector'; port = 21841; target_ip = $ServerAddress; target_port = 21842
                    project = 'BURNOUT5'; sku = 'PC'; secure = $true; cn = 'pcburnout08.ea.com' },
        [ordered]@{ type = 'Aries'; subtype = 'Matchmaker'; port = 21842; listen_ip = '0.0.0.0'; project = 'BURNOUT5'; sku = 'PC' }
    )
}
$config | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $static 'MultiSocks.json') -Encoding UTF8
Write-Host "Burnout private server on $ServerAddress  (TCP 21841/21842).  Max players: $MaxUsers.  Ctrl+C to stop."
Push-Location $here
try { & (Join-Path $here 'MultiSocks.exe') } finally { Pop-Location }
