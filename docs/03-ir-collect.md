# 03 IR-COLLECT tools

All tools run portable from IR-TOOLS. Nothing gets installed on the host. Output always goes to IR-EVIDENCE.

## Order of operations on a live host

1. **Encrypted Disk Detector** first. If BitLocker or another full-disk encryption is active, a power-off loses access without the recovery key. Decide: live capture or shut down.
2. **Memory capture** next, most volatile data first: WinPmem, DumpIt, or Magnet Response.
3. **Triage collection**: `Invoke-QuickTriage.ps1`, Magnet Response, or a Velociraptor offline collector.
4. **Hash everything** you collected, then log it in the evidence log and chain of custody form.
5. **Analysis** happens later, on your own analysis machine, not the client host.

## Tool reference

### Memory acquisition

| Tool | Purpose | Notes | Source |
|---|---|---|---|
| WinPmem (go-winpmem 1.0 rc2) | Primary RAM capture, x64 | Outer .exe is unsigned despite the name. Trust comes from the GitHub digest. High EDR risk. | https://github.com/Velocidex/WinPmem/releases |
| Magnet DumpIt | RAM capture for x86, x64, **ARM64** | Covers Snapdragon laptops. Ignore the bundled Comae upload scripts on client systems. | https://www.magnetforensics.com/resources/magnet-dumpit-for-windows/ |
| FTK Imager 4.7 | GUI disk imaging and RAM capture | Copy the install folder for a portable copy. Test on a clean VM. | https://www.exterro.com/digital-forensics-software/ftk-imager |

### Triage and collection

| Tool | Purpose | Source |
|---|---|---|
| Magnet Response | One-click collection: RAM, event logs, registry hives, jump lists. Zip output with embedded hash. | https://www.magnetforensics.com/resources/magnet-response/ |
| Velociraptor | Offline collector for artifact collection at scale. Build the collector in a lab first. | https://github.com/Velocidex/velociraptor/releases |
| Invoke-QuickTriage.ps1 | Built-in cmdlets only, low EDR noise. 24 outputs. | This repo |
| Magnet Encrypted Disk Detector | Checks for BitLocker, VeraCrypt, PGP, and others before shutdown | https://www.magnetforensics.com/resources/encrypted-disk-detector/ |

### Live system analysis

| Tool | Purpose | Source |
|---|---|---|
| Sysinternals Suite | Autoruns (persistence), Process Explorer, TCPView, Sigcheck (unsigned binaries), Procmon, Handle, Streams, Strings | https://learn.microsoft.com/en-us/sysinternals/downloads/sysinternals-suite |
| ESET SysInspector | Second view of processes, drivers, startup items | https://www.eset.com/us/download/tools-and-utilities/ |
| ESET AV Remover | Removes legacy AV blocking an EDR rollout | https://www.eset.com/us/download/tools-and-utilities/ |

### Event log and artifact analysis

| Tool | Purpose | Source |
|---|---|---|
| Hayabusa | Fast event log timeline with Sigma rules. Use the live-response build on hosts. | https://github.com/Yamato-Security/hayabusa/releases |
| Chainsaw | Event log and MFT hunting with Sigma and its own rules | https://github.com/WithSecureLabs/chainsaw/releases |
| Eric Zimmerman's tools | Parsers for registry, prefetch, LNK, jump lists, MFT, SRUM, event logs. Use .NET 4 builds on hosts, .NET 10 builds on your analysis machine. | https://ericzimmerman.github.io |

## Tools considered and dropped

| Tool | Reason |
|---|---|
| ESET SysRescue Live | End of life since September 2023. Frozen signatures, no official download. |
| Magnet RAM Capture | Last release 2019, no Windows 11 support. Old drivers fail with Memory Integrity on. |
| Kaspersky Rescue Disk | US government ban on Kaspersky products. Unsuitable for regulated clients. |
| KAPE | Excellent tool, but paid client work needs a commercial license. |

## Download the Eric Zimmerman tools

```powershell
& .\Get-ZimmermanTools.ps1 -Dest F:\Tools\EZTools
& .\Get-ZimmermanTools.ps1 -Dest F:\Tools\EZTools -NetVersion 4
```
