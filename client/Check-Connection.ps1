# Verifies this PC resolves the game's login host to the private server and can reach both TCP ports.
param([Parameter(Mandatory = $true)][string]$ServerAddress)
$resolved = try { ([System.Net.Dns]::GetHostAddresses('pcburnout08.ea.com') | Select-Object -First 1).IPAddressToString } catch { 'unresolved' }
"pcburnout08.ea.com resolves to: $resolved (expected $ServerAddress)"
foreach ($p in 21841, 21842) {
    $r = Test-NetConnection -ComputerName $ServerAddress -Port $p -WarningAction SilentlyContinue
    "TCP $p -> $(if ($r.TcpTestSucceeded) {'OPEN'} else {'BLOCKED or not listening'})"
}
