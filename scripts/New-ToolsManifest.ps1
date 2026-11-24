<#
.SYNOPSIS
    Hashes every file under <Drive>\Tools into <Drive>\Hashes\tools_manifest.csv.
.DESCRIPTION
    Paths are stored relative to the drive root, so Test-ToolsManifest.ps1 works under any drive letter.
    Prints the manifest's own SHA256. Store that value in your password vault.
.EXAMPLE
    .\New-ToolsManifest.ps1 -Drive F:
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z]:$')]
    [string]$Drive
)

$root     = "$Drive\"
$toolsDir = Join-Path $root 'Tools'
$outDir   = Join-Path $root 'Hashes'
$manifest = Join-Path $outDir 'tools_manifest.csv'

if (-not (Test-Path $toolsDir)) { throw "Not found: $toolsDir" }
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

Get-ChildItem $toolsDir -Recurse -File |
    Get-FileHash -Algorithm SHA256 |
    Select-Object Hash, @{n='RelativePath';e={ $_.Path.Substring($root.Length) }} |
    Export-Csv $manifest -NoTypeInformation -Encoding UTF8

$count = (Import-Csv $manifest).Count
$self  = (Get-FileHash $manifest -Algorithm SHA256).Hash
Write-Host "Files hashed : $count"
Write-Host "Manifest hash: $self  (store in your vault)"
