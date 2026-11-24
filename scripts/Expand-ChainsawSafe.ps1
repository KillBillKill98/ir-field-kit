<#
.SYNOPSIS
    Extracts the Chainsaw all-platforms zip while skipping sigma/regression_data.
.DESCRIPTION
    regression_data holds recorded attack samples (Mimikatz, WinPwn, and others) used to test Sigma rules.
    Antivirus quarantines them, and Expand-Archive then rolls back the whole extraction.
    Chainsaw does not need these files to run. Verify the zip's SHA256 against the GitHub release first.
.EXAMPLE
    .\Expand-ChainsawSafe.ps1 -ZipPath C:\Staging\chainsaw_all_platforms+rules.zip -Destination F:\Tools\Chainsaw
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ZipPath,
    [Parameter(Mandatory)] [string]$Destination
)

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead($ZipPath)
$ok = 0; $skipped = 0; $fail = 0
try {
    foreach ($e in $zip.Entries) {
        if ($e.FullName -match 'regression_data') { $skipped++; continue }
        $target = Join-Path $Destination $e.FullName
        if ($e.FullName.EndsWith('/')) { New-Item -ItemType Directory -Path $target -Force | Out-Null; continue }
        try {
            New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
            [IO.Compression.ZipFileExtensions]::ExtractToFile($e, $target, $true)
            $ok++
        } catch {
            $fail++
            Write-Host "FAILED: $($e.FullName) -> $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} finally {
    $zip.Dispose()
}
Write-Host "Extracted: $ok  Skipped (regression_data): $skipped  Failed: $fail"
