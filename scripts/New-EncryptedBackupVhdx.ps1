<#
.SYNOPSIS
    Creates an expandable VHDX, formats it NTFS, and encrypts it with BitLocker To Go.
.DESCRIPTION
    Use for tool backups on a machine whose system drive is not encrypted.
    Run elevated. Store the recovery password in a password vault, never on disk.
.EXAMPLE
    .\New-EncryptedBackupVhdx.ps1 -Path C:\IRBackup.vhdx -SizeMB 5120 -Letter V -Label IR-BACKUP
.NOTES
    Open later:  Mount-DiskImage C:\IRBackup.vhdx; Unlock-BitLocker -MountPoint V: -Password (Read-Host -AsSecureString)
    Close:       Lock-BitLocker -MountPoint V: -ForceDismount; Dismount-DiskImage C:\IRBackup.vhdx
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$Path,
    [int]$SizeMB = 5120,
    [ValidatePattern('^[A-Za-z]$')] [string]$Letter = 'V',
    [string]$Label = 'IR-BACKUP'
)

if (Test-Path $Path) { throw "File exists: $Path" }

$script = @"
create vdisk file="$Path" maximum=$SizeMB type=expandable
attach vdisk
create partition primary
format fs=ntfs label="$Label" quick
assign letter=$Letter
"@
$tmp = Join-Path $env:TEMP 'vd.txt'
$script | Out-File $tmp -Encoding ascii
diskpart /s $tmp | Out-Null
Remove-Item $tmp

$pw = Read-Host "BitLocker passphrase for $Label" -AsSecureString
Enable-BitLocker -MountPoint "$($Letter):" -EncryptionMethod Aes256 -UsedSpaceOnly -PasswordProtector -Password $pw | Out-Null
Add-BitLockerKeyProtector -MountPoint "$($Letter):" -RecoveryPasswordProtector | Out-Null
Remove-Variable pw

Write-Host "Save this recovery password in your vault, then clear the screen:" -ForegroundColor Yellow
(Get-BitLockerVolume -MountPoint "$($Letter):").KeyProtector |
    Where-Object KeyProtectorType -eq RecoveryPassword |
    Format-List KeyProtectorId, RecoveryPassword
