# 01 Drive architecture

## FW-PFSENSE (4 GB USB stick)

| Item | Value |
|---|---|
| Content | Netgate Installer v1.2 memstick image (online installer for current pfSense CE and Plus) |
| Written with | Rufus, DD image mode |
| Why separate | FreeBSD installers boot unreliably through Ventoy. pfSense 2.9 failed under Ventoy in testing (see lessons learned). |
| Windows view | Shows a tiny FAT partition. Normal. Never format it when Windows asks. |

## VTOY-FIELD (32 GB USB stick)

| Item | Value |
|---|---|
| Boot loader | Ventoy 1.1.18, GPT, Secure Boot support on |
| Data partition | exFAT, label VTOY-FIELD |
| Folders | OS, Firewall, Rescue, Security, Hardware |
| Menu | `ventoy/ventoy.json` sets folder view and folder names |
| Manifest | `iso_manifest.csv` at the root, SHA256 of every ISO |
| Free space target | Keep 3 to 4 GB free for version updates |

## IR-COLLECT (128 GB USB 3.2 stick)

| Partition | Size | File system | Encryption | Content |
|---|---|---|---|---|
| IR-TOOLS | 16 GB | NTFS | None | Tools, scripts, forms, manifest, README |
| IR-EVIDENCE | ~99 GB | NTFS | BitLocker To Go, AES-256, password + recovery key | Case folders only |

```
IR-TOOLS
├── 00_README.txt          "If found, contact" business email only
├── Tools
│   ├── Sysinternals
│   ├── EZTools            .NET 10 and .NET 4 builds
│   ├── ESET               AV Remover, SysInspector
│   ├── FTKImager
│   ├── Memory             WinPmem
│   ├── Magnet             DumpIt, Response, EDD
│   ├── Velociraptor
│   ├── Hayabusa           full + live-response builds
│   ├── Chainsaw           without sigma/regression_data
│   └── Scripts            Invoke-QuickTriage.ps1
├── Hashes
│   └── tools_manifest.csv
└── Forms
    ├── evidence_log.csv
    ├── chain_of_custody.csv
    └── ir_notes_template.txt

IR-EVIDENCE
└── Cases
    └── 2026-11-22_P4IT-0001
        ├── Memory
        ├── Triage
        ├── Logs
        ├── Notes
        └── hashes.csv
```

Why two partitions: tools stay readable on any machine with no unlock step. Collected data, often regulated (CUI, ePHI), stays encrypted at rest. This lines up with NIST SP 800-171 controls 3.8.6 and 3.8.7 for portable media.

Create the partitions (admin PowerShell, confirm the disk number first):

```powershell
Get-Disk | Where-Object BusType -eq USB | Format-Table Number, FriendlyName, Size
Clear-Disk -Number N -RemoveData
New-Partition -DiskNumber N -Size 16GB -DriveLetter F | Format-Volume -FileSystem NTFS -NewFileSystemLabel IR-TOOLS
New-Partition -DiskNumber N -UseMaximumSize -DriveLetter G | Format-Volume -FileSystem NTFS -NewFileSystemLabel IR-EVIDENCE

$pw = Read-Host "BitLocker passphrase" -AsSecureString
Enable-BitLocker -MountPoint "G:" -EncryptionMethod Aes256 -UsedSpaceOnly -PasswordProtector -Password $pw
Add-BitLockerKeyProtector -MountPoint "G:" -RecoveryPasswordProtector
Remove-Variable pw
```

Store the recovery password in a password vault. Never on the drive, never in a screenshot.

## VTOY-VAULT (1 to 2 TB external SSD)

| Partition | Size | Content |
|---|---|---|
| Ventoy data (exFAT) | ~230 GB | Full ISO library, Archive folder hidden with `.ventoyignore` |
| VTOYEFI | 32 MB | Ventoy boot files. Never touch. |
| VAULT-SECURE (NTFS, BitLocker) | Rest | Tool backups, installer archives, notes |

Use an SSD, not a spinning hard drive. A used external HDD failed during this build with bad blocks and CRC errors (see lessons learned).

Reserve the encrypted space during the Ventoy install: Option > Partition Configuration > Preserve some space at the end of the disk.

## Physical labels

| Drive | Tag color |
|---|---|
| VTOY-FIELD, VTOY-VAULT | Blue (boot media) |
| IR-COLLECT | Red (evidence, handle with care) |
| FW-PFSENSE | Yellow (single purpose) |

Add an asset tag (USB-01, USB-02, ...) and log tag, serial number, size, and purpose in a removable media inventory.
