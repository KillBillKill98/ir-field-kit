# 05 EDR and engagements

Expect the client's EDR to react to this kit. Plan for it instead of trying to avoid it.

## What happens when IR-COLLECT plugs into a managed machine

1. **The drive might not mount.** Device control (Intune, Defender, CrowdStrike, SentinelOne) often blocks USB storage, especially on CMMC environments.
2. **The EDR scans what it touches.** Some scan the whole drive on connect.
3. **Quarantine deletes files from your stick.** You leave with a damaged kit, and the client's SOC sees a hacktool alert tied to your visit.
4. **Evidence is at risk.** A memory dump from an infected host contains malware. An EDR scan of IR-EVIDENCE can quarantine your evidence and break chain of custody.

## Detection risk by tool

| Risk | Tools |
|---|---|
| High | Velociraptor, WinPmem, DumpIt, Magnet Response, ProcDump against lsass, PsExec |
| Medium | Chainsaw and Hayabusa (rule files contain attack strings), some Sysinternals |
| Low | Eric Zimmerman tools, EDD, FTK Imager, most Sysinternals, Invoke-QuickTriage.ps1 |

Velociraptor deserves special mention: ransomware operators have used the legitimate signed binary in real attacks since 2025, so many SOCs treat any unexpected Velociraptor execution as a ransomware precursor.

## Before the engagement

- Signed rules of engagement naming the hosts in scope and the client's security contact.
- Ask which EDR they run and whether USB storage is blocked.
- Send `tools_manifest.csv` hashes for allow-listing.
- Request a time-limited exception for your specific USB device:

```powershell
Get-Disk | Where-Object BusType -eq USB | Format-List FriendlyName, SerialNumber
Get-PnpDevice -Class DiskDrive -PresentOnly | Where-Object InstanceId -like 'USBSTOR*' | Format-List FriendlyName, InstanceId
```

- Ask for a scan exclusion on the evidence path for the engagement window.

## During the engagement

- Prefer the client's own EDR live response (Defender XDR live response, CrowdStrike RTR, SentinelOne Remote Ops) where available. Full logging on their side, no USB needed.
- Never disable or bypass the client's EDR yourself. That decision belongs to the client, in writing.
- A detection is a good sign. If your tool ran with no alert, an attacker's copy would too. Report that gap.
- Never upload client memory or files to third-party clouds (Comae, VirusTotal) without written permission.

## After the engagement

- Run `Test-ToolsManifest.ps1`. Restore anything changed or missing from the encrypted backup.
- Hand off or archive evidence per the contract, then wipe the case folder.

## Notes for MSP employees with a side practice

Keep employer and personal-business work fully separate: separate laptops, separate drives, separate case folders. Building or encrypting personal-business media on an employer-managed laptop can escrow your recovery keys to the employer's directory and mix data ownership.
