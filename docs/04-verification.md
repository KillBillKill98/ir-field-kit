# 04 Verification

No file goes on a drive until it passes one of these checks, in order of strength.

| Strength | Check | Used for |
|---|---|---|
| Strongest | SHA256 matches the vendor's published value (or GPG-signed hash list) | SystemRescue, Hiren's, Kali, Memtest86+, Ventoy, all GitHub releases |
| Strong | Valid Authenticode signature from the expected publisher | Microsoft, Magnet, Rapid7 (Velociraptor), AccessData, ESET, Eric Zimmerman |
| Supporting | VirusTotal lookup by hash (never upload client files) | Second opinion. Zero detections proves nothing alone. |
| Weak | Trusted internal copy, no published hash | Log it as such. Replace with a verified download when possible. |

## Hash a download

```powershell
Get-FileHash .\file.iso -Algorithm SHA256
```

GitHub shows a `sha256:` digest next to every release asset. Third-party mirrors are acceptable only when the hash matches the official list. The hash is what you trust, not the website.

## Check signatures

```powershell
Get-AuthenticodeSignature .\tool.exe | Format-List Status, @{n='Signer';e={$_.SignerCertificate.Subject}}

# Every exe in a folder, show only failures
Get-ChildItem .\Sysinternals -Filter *.exe | Get-AuthenticodeSignature | Where-Object Status -ne 'Valid'
```

An expired certificate still shows `Valid` when the vendor timestamped the signature.

For Microsoft evaluation ISOs with no published hash, mount the ISO and check `setup.exe` and `sources\setup.exe` signatures.

## Reading a lone VirusTotal hit

One heuristic detection (names with `Heur`, `AI`, `Generic`) out of 60+ engines on a vendor-signed forensic tool is almost always a false positive. Forensic tools read raw disk and memory, which looks like attacker behavior. Named malware detections from several engines are a different story.

## Manifests

| Drive | Manifest | Scope |
|---|---|---|
| VTOY-FIELD, VTOY-VAULT | `iso_manifest.csv` at root | Every ISO |
| IR-TOOLS | `Hashes\tools_manifest.csv` | Every file under `Tools` |

Build and test the tools manifest with [`New-ToolsManifest.ps1`](../scripts/New-ToolsManifest.ps1) and [`Test-ToolsManifest.ps1`](../scripts/Test-ToolsManifest.ps1). Paths are stored relative to the drive, so the check works under any drive letter.

Store the manifest's own SHA256 in your password vault. If someone changes both a tool and the manifest, the vault hash still exposes it.

Run the test before every engagement and after every engagement. Anything changed or missing after a client visit usually means the client's EDR quarantined it. Restore from backup.

## Drive health

After large copies to a spinning or aging drive:

```powershell
Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='disk'; Id=7; StartTime=(Get-Date).AddHours(-2)} -ErrorAction SilentlyContinue | Measure-Object
```

Any count above zero means bad blocks. A CRC error on a file that hashed fine the day before means the drive is degrading. Retire it.
