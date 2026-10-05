# Creates a separate local-test copy of the exact Steam Ultimate Box build.
# The public key constants are from eaEmu's GPL-3.0 replaceKey.py:
# https://github.com/teknogods/eaEmu/blob/master/misc/replaceKey/replaceKey.py
param(
    [Parameter(Mandatory = $true)]
    [string]$GameDirectory,

    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$gameDir = (Resolve-Path -LiteralPath $GameDirectory).Path
$source = Join-Path $gameDir 'BurnoutParadise.exe'
$output = if ($OutputPath) { [System.IO.Path]::GetFullPath($OutputPath) }
    else { Join-Path $gameDir 'BurnoutParadise.private.exe' }
$outputDir = Split-Path -Parent $output
$expectedOriginal = 'FA55FF4D5B0F0F1E7A3DD861EC765D1D81C51554B588AE9872A3F923686F41BE'
$expectedPrivate = 'D50B3DDA9A773EA98146735917B42B8C4B44F2A5844ACB901E74013254BF323C'
$oldKeyHex = '9275A15B080240B89B402FD59C71C4515871D8F02D937FD30C8B1C7DF92A0486F190D1310ACBD8D41412903B356A0651494CC575EE0A462980F0D53A51BA5D6A1937334368252DFEDF9526367C4364F156170EF167D5695420FB3A55935DD497BC3AD58FD244C59AFFCD0C31DB9D947CA66666FB4BA75EF8644E28B1A6B87395'
$newKeyHex = 'DA02D380D0AB67886D2B11177EFF4F1FBA80A3070E8F036DEE9DC0F30BF8B80516164DC0D4827F47A48A3BCA129DD29D1961D8566147A588DC248F90C9A41CBFF857E02F47782EAE5A70E555BADD36E16C179331E4F92203816998C82EDFBE0E339DC3E0C0208552CD3F05F5CB412F6710916AD159DAC1233E71089F20D43D6D'

if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw "Steam game executable not found: $source"
}
if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $expectedOriginal) {
    throw 'This Steam executable differs from the tested build; refusing to patch it.'
}
if (Test-Path -LiteralPath $output) {
    if ((Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash -ne $expectedPrivate) {
        throw "A different private executable already exists: $output"
    }
    Write-Host "Verified existing private game copy: $output"
    return
}

New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

function ConvertFrom-Hex([string]$hex) {
    if ($hex.Length % 2 -ne 0) { throw 'Invalid public key hex length.' }
    $bytes = New-Object byte[] ($hex.Length / 2)
    for ($i = 0; $i -lt $bytes.Length; $i++) {
        $bytes[$i] = [Convert]::ToByte($hex.Substring($i * 2, 2), 16)
    }
    return ,$bytes
}

$oldKey = ConvertFrom-Hex $oldKeyHex
$newKey = ConvertFrom-Hex $newKeyHex
$data = [System.IO.File]::ReadAllBytes($source)
$found = -1
for ($i = 0; $i -le $data.Length - $oldKey.Length; $i++) {
    if ($data[$i] -ne $oldKey[0]) { continue }
    $matches = $true
    for ($j = 1; $j -lt $oldKey.Length; $j++) {
        if ($data[$i + $j] -ne $oldKey[$j]) { $matches = $false; break }
    }
    if (-not $matches) { continue }
    if ($found -ne -1) { throw 'The original public key is ambiguous in this game build.' }
    $found = $i
}
if ($found -eq -1) { throw 'The original public key was not found.' }
[Array]::Copy($newKey, 0, $data, $found, $newKey.Length)

# The exact-build-only diagnostic skips the game's certificate name error -24
# and resumes immediately before its embedded-CA check. The signature-check
# code remains in place. This is a local experiment, not a production patch.
$nameFailureOffset = 0x46854e
$expectedBytes = [byte[]](0x5d, 0x5f, 0x5e, 0xb8, 0xe8)
for ($i = 0; $i -lt $expectedBytes.Length; $i++) {
    if ($data[$nameFailureOffset + $i] -ne $expectedBytes[$i]) {
        throw 'The certificate-name instructions differ from the tested build.'
    }
}
if ($data[0x46855e] -ne 0xa1 -or $data[0x46855f] -ne 0xf8) {
    throw 'The certificate-check continuation differs from the tested build.'
}
$data[$nameFailureOffset] = 0xe9
[Array]::Copy([BitConverter]::GetBytes([int](0x46855e - (0x46854e + 5))), 0, $data, $nameFailureOffset + 1, 4)

$temp = Join-Path $outputDir ('.burnout-private-' + [guid]::NewGuid().ToString('N') + '.exe')
try {
    [System.IO.File]::WriteAllBytes($temp, $data)
    if ((Get-FileHash -LiteralPath $temp -Algorithm SHA256).Hash -ne $expectedPrivate) {
        throw 'The private game copy did not match the verified test build.'
    }
    [System.IO.File]::Move($temp, $output)
} finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force }
}
if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $expectedOriginal) {
    throw 'The original game executable changed unexpectedly.'
}
Write-Host "Created private game copy: $output"
