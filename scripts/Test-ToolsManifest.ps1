<#
.SYNOPSIS
    Checks every tool file against tools_manifest.csv. Reports changed, missing, and added files.
.DESCRIPTION
    Run before and after every engagement. Optionally pass the manifest hash from your vault
    to detect tampering with the manifest itself.
.EXAMPLE
    .\Test-ToolsManifest.ps1 -Drive F: -ExpectedManifestHash 00F336...
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z]:$')]
    [string]$Drive,
    [string]$ExpectedManifestHash
)

$root     = "$Drive\"
$manifest = Join-Path $root 'Hashes\tools_manifest.csv'
if (-not (Test-Path $manifest)) { throw "Manifest not found: $manifest" }

if ($ExpectedManifestHash) {
    $actual = (Get-FileHash $manifest -Algorithm SHA256).Hash
    if ($actual -ne $ExpectedManifestHash.ToUpper()) {
        Write-Host "MANIFEST HASH MISMATCH. Do not trust this drive." -ForegroundColor Red
        Write-Host "Expected $ExpectedManifestHash"
        Write-Host "Actual   $actual"
        exit 2
    }
    Write-Host "Manifest hash OK" -ForegroundColor Green
}

$entries = Import-Csv $manifest
$known   = @{}
$changed = @(); $missing = @()

foreach ($e in $entries) {
    $full = Join-Path $root $e.RelativePath
    $known[$e.RelativePath.ToLower()] = $true
    if (-not (Test-Path -LiteralPath $full)) { $missing += $e.RelativePath; continue }
    if ((Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash -ne $e.Hash) { $changed += $e.RelativePath }
}

$added = Get-ChildItem (Join-Path $root 'Tools') -Recurse -File |
    ForEach-Object { $_.FullName.Substring($root.Length) } |
    Where-Object { -not $known.ContainsKey($_.ToLower()) }

Write-Host "Checked: $($entries.Count)  Changed: $($changed.Count)  Missing: $($missing.Count)  Added: $(@($added).Count)"
$changed | ForEach-Object { Write-Host "CHANGED  $_" -ForegroundColor Red }
$missing | ForEach-Object { Write-Host "MISSING  $_" -ForegroundColor Yellow }
$added   | ForEach-Object { Write-Host "ADDED    $_" -ForegroundColor Yellow }

if ($changed.Count + $missing.Count + @($added).Count -gt 0) { exit 1 } else { Write-Host "Toolkit intact" -ForegroundColor Green }
