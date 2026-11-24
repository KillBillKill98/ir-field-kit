# 02 VTOY-FIELD boot library

## Contents and sources

| Folder | ISO | Purpose | Official source |
|---|---|---|---|
| OS | Windows 11 26H2 (26300.9457) | Clean installs, in-place repair | https://www.microsoft.com/software-download/windows11 |
| OS | Windows Server 2022 Evaluation | Server rebuilds, lab | https://www.microsoft.com/en-us/evalcenter |
| Firewall | pfSense CE 2.7.2 (offline installer) | Firewall installs with no internet. Fallback for hardware where newer builds fail. | https://www.pfsense.org/download/ |
| Rescue | WinPE 2023CA and 2011CA (custom build) | Microsoft-only rescue environment with PowerShell and Sysinternals | Built with the Windows ADK, see below |
| Rescue | Hiren's BootCD PE v1.0.8 | Windows-based rescue desktop | https://www.hirensbootcd.org/download/ |
| Rescue | SystemRescue 13.03 | Linux rescue, disk repair | https://www.system-rescue.org/Download/ |
| Rescue | Rescuezilla 2.6.2 (Ubuntu 26.04 base) | Disk imaging and cloning | https://github.com/rescuezilla/rescuezilla/releases |
| Security | Kali Linux Live | Authorized testing. Use forensic mode for IR. | https://www.kali.org/get-kali/ |
| Hardware | Memtest86+ v9.00 | RAM testing | https://www.memtest.org |

Tool used for the stick itself: Ventoy, https://github.com/ventoy/Ventoy/releases

## Custom WinPE build

Install the Windows ADK and the WinPE add-on with matching versions (https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install), Deployment Tools feature only. Then, in Deployment and Imaging Tools Environment as administrator:

```cmd
copype amd64 C:\WinPE_amd64
Dism /Mount-Image /ImageFile:C:\WinPE_amd64\media\sources\boot.wim /Index:1 /MountDir:C:\WinPE_amd64\mount

set OCS=C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs
for %p in (WinPE-WMI WinPE-NetFx WinPE-Scripting WinPE-PowerShell WinPE-StorageWMI WinPE-DismCmdlets WinPE-SecureStartup) do (Dism /Add-Package /Image:C:\WinPE_amd64\mount /PackagePath:"%OCS%\%p.cab" & Dism /Add-Package /Image:C:\WinPE_amd64\mount /PackagePath:"%OCS%\en-us\%p_en-us.cab")

mkdir C:\WinPE_amd64\mount\Tools
for %f in (Autoruns64.exe autorunsc64.exe sigcheck64.exe procexp64.exe tcpview64.exe handle64.exe streams64.exe strings64.exe) do copy "%SYSINTERNALS%\%f" C:\WinPE_amd64\mount\Tools\

Dism /Unmount-Image /MountDir:C:\WinPE_amd64\mount /Commit
MakeWinPEMedia /ISO C:\WinPE_amd64 C:\WinPE_amd64\WinPE_amd64_2011CA.iso
MakeWinPEMedia /ISO C:\WinPE_amd64 C:\WinPE_amd64\WinPE_amd64_2023CA.iso /bootex
```

Two builds because Microsoft is moving Secure Boot from the Windows UEFI CA 2011 to the 2023 CA. The `/bootex` switch goes at the end of the command, not after `/ISO`.

Inside WinPE, the tools live in `X:\Tools`. Add `-accepteula` to each Sysinternals command.

## Boot test results

Tested on a Lenovo ThinkPad E14 (AMD Ryzen 5 5500U), UEFI, Secure Boot off.

| ISO | Result | Notes |
|---|---|---|
| Hiren's BootCD PE | Pass | Desktop loads. Clock offset from hardware time. |
| Kali Live | Pass | Normal live mode lists internal disks. Use forensic mode for IR. |
| Rescuezilla | Pass | Live session password prompt: leave blank |
| SystemRescue | Pass | Includes its own Memtest86+ entry |
| WinPE 2023CA | Pass | PowerShell 5.1, Get-Disk, Sysinternals, Ethernet driver all work |
| WinPE 2011CA | Pass | Same image, older boot files |
| Memtest86+ | Pass | v9.00 is signed, but not by Microsoft. Secure Boot machines need the CA enrolled or Secure Boot off. |
| pfSense CE 2.7.2 | Pass | Installer welcome screen |
| pfSense 2.9 online ISO | **Fail** | `Mounting from cd9660 failed with error 19` in normal and memdisk modes. Use the dedicated FW-PFSENSE stick. |
| Windows 11 26H2 | Pass | Setup language screen |
| Server 2022 Eval | Pass | Setup language screen |

Still to test: every ISO on a machine with Secure Boot on.

## Folder menu

Copy [`ventoy/ventoy.json`](../ventoy/ventoy.json) to `<stick>\ventoy\ventoy.json`. Validate before booting:

```powershell
Get-Content D:\ventoy\ventoy.json -Raw | ConvertFrom-Json | Out-Null; "JSON OK"
```

Write the file without a byte-order mark (see the command in the ventoy folder notes).

## Ventoy on a locked-down Windows machine

Ventoy2Disk.exe is unsigned. On machines with the UAC policy "Only elevate executables that are signed and validated" (`ValidateAdminCodeSignatures = 1`), elevation fails with error `0x8007202B`. Install from a machine you control, or from Linux with `Ventoy2Disk.sh -i -g -s -L VTOY-FIELD /dev/sdX`. On a managed device, get written approval before any policy change and restore the policy right after.
