# IR Field Kit

A portable boot and incident response toolkit for security engineers, built on four USB drives. Every file in the kit is verified by hash or code signature before use, tracked in a manifest, and re-checked before each engagement.

This repo documents the full build: drive layout, every tool and its purpose, official download sources, verification steps, scripts, and lessons learned from real failures during the build.

> Use these tools only on systems you own or have written authorization to assess. Several tools here are also used by attackers. Expect EDR alerts, and coordinate with the system owner's security team before use.

## Architecture

```
+---------------------+   +---------------------+   +----------------------+   +----------------------+
| FW-PFSENSE  (4 GB)  |   | VTOY-FIELD (32 GB)  |   | IR-COLLECT (128 GB)  |   | VTOY-VAULT (1-2 TB)  |
| Single-purpose      |   | Ventoy multiboot    |   | Incident response    |   | Master library (SSD) |
| pfSense installer   |   | 10 field ISOs       |   |                      |   |                      |
| flashed with Rufus  |   | carried to sites    |   | IR-TOOLS   16 GB     |   | Ventoy ISO partition |
|                     |   |                     |   |  NTFS, tools, forms  |   | full ISO archive     |
|                     |   |                     |   | IR-EVIDENCE ~99 GB   |   | VAULT-SECURE         |
|                     |   |                     |   |  NTFS, BitLocker     |   |  BitLocker, backups  |
+---------------------+   +---------------------+   +----------------------+   +----------------------+
```

| Drive | Role | Goes on site? |
|---|---|---|
| FW-PFSENSE | Dedicated pfSense installer. Some firewall hardware refuses to boot Ventoy. | Yes |
| VTOY-FIELD | Working copy of the boot library. Cheap, replaceable, holds no secrets. | Yes |
| IR-COLLECT | Live response tools on one partition, encrypted evidence on the other. | Yes |
| VTOY-VAULT | Master library and encrypted backups. Rebuilds the field drives. | No |

Design rules:
- Tools flow from IR-TOOLS. Evidence flows to IR-EVIDENCE. Nothing gets written to the suspect host.
- The field stick takes the risk of untrusted machines, so the master copy never does.
- Every file has a recorded SHA256. A manifest check runs before each engagement.
- No client names on labels, folders, or drives. Case folders use date plus case ID.

## Documentation

| Doc | Contents |
|---|---|
| [01 Drive architecture](docs/01-drive-architecture.md) | Partition layout, file systems, encryption, labels |
| [02 VTOY-FIELD](docs/02-vtoy-field.md) | Boot ISOs, sources, boot test results |
| [03 IR-COLLECT](docs/03-ir-collect.md) | Every IR tool, its purpose, and its source |
| [04 Verification](docs/04-verification.md) | Hashes, signatures, VirusTotal, manifests |
| [05 EDR and engagements](docs/05-edr-and-engagements.md) | Working alongside client EDR, rules of engagement |
| [06 Lessons learned](docs/06-lessons-learned.md) | What broke during the build and the fix |

## Scripts

| Script | Purpose |
|---|---|
| [Invoke-QuickTriage.ps1](scripts/Invoke-QuickTriage.ps1) | Live triage with built-in cmdlets only. 24 outputs, hashed for chain of custody. |
| [New-ToolsManifest.ps1](scripts/New-ToolsManifest.ps1) | Hashes every tool into a manifest with drive-independent paths. |
| [Test-ToolsManifest.ps1](scripts/Test-ToolsManifest.ps1) | Detects changed, missing, or added tool files. |
| [Expand-ChainsawSafe.ps1](scripts/Expand-ChainsawSafe.ps1) | Extracts Chainsaw without the Sigma regression samples that trip EDR. |
| [New-EncryptedBackupVhdx.ps1](scripts/New-EncryptedBackupVhdx.ps1) | Creates a BitLocker-protected VHDX for tool backups. |

## Other files

- [ventoy/ventoy.json](ventoy/ventoy.json): opens the Ventoy menu in folder view with friendly folder names
- [templates/](templates/): evidence log, chain of custody, IR notes

## License

MIT. Third-party tools listed here keep their own licenses. Check each vendor's terms before paid client work.
