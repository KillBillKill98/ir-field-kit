# 06 Lessons learned

Real problems hit during this build, and the fix for each.

## pfSense 2.9 fails under Ventoy

**Symptom:** `Mounting from cd9660:/dev/iso9660/PFSENSE failed with error 19`, drop to `mountroot>`. Same result in memdisk mode (Ctrl+D).
**Cause:** The newer FreeBSD kernel does not find the ISO the way Ventoy presents it. pfSense 2.7.2 on the same stick boots fine.
**Fix:** Keep a dedicated pfSense installer stick flashed with Rufus. Archive the 2.9 ISO on the vault for VMs and retest after Ventoy updates.

## A used external hard drive failed mid-build

**Symptom:** RAW partition right after the Ventoy install. Copies failed with "The file or directory is corrupted and unreadable". The next day, a file that hashed fine failed with a CRC error. Event log showed dozens of disk event 7 (bad block).
**Cause:** Failing drive. Windows still reported it "Healthy" because the USB enclosure hides SMART data.
**Fix:** Retire it. A full format (`Format-Volume -Full`) maps out bad sectors and is a useful test, but a degrading drive gets worse. Use an SSD for the master library.

## Chainsaw extraction disappeared

**Symptom:** Defender quarantined files during `Expand-Archive`, then the whole Chainsaw folder was empty.
**Cause:** The Sigma repo bundles `regression_data`: recorded attack samples (Mimikatz, WinPwn) used to test rules. Defender caught them, and `Expand-Archive` treated that as a failure and rolled back everything it had extracted.
**Fix:** Extract while skipping `regression_data`. See [`Expand-ChainsawSafe.ps1`](../scripts/Expand-ChainsawSafe.ps1). Chainsaw does not need those files to run.

## Triage script missed the logged-in user's persistence

**Symptom:** Run keys collected from HKCU showed the admin account, not the daily-use account.
**Cause:** In an elevated session, HKCU belongs to the account running the script.
**Fix:** Version 1.1 reads Run keys from every loaded profile under HKEY_USERS, and lists all profiles with their loaded state. On the first run it found an orphaned startup entry pointing to a deleted app in a user-writable folder, a path any process running as that user could hijack.

## Recovery key captured in a screenshot

**Fix:** Add a new recovery protector, store it, then remove the exposed one:

```powershell
Add-BitLockerKeyProtector -MountPoint "E:" -RecoveryPasswordProtector
Remove-BitLockerKeyProtector -MountPoint "E:" -KeyProtectorId "{exposed-id}"
```

Then delete the screenshot and clear clipboard history.

## End-of-life tools hide in "best of" lists

ESET SysRescue Live still appears in many rescue-kit guides and in Ventoy's tested ISO list. It reached end of life in September 2023. Always check the vendor's lifecycle page before adding a tool.

## Small things

- File Explorer hides extensions. Renaming to `name.iso` created `name.iso.iso`. Turn on File name extensions.
- PowerShell in an admin session runs as a different account, so `$env:USERPROFILE\Downloads` points somewhere else. Use full paths.
- `MakeWinPEMedia /bootex` goes at the end of the command.
- exFAT volume labels allow 11 characters.
- Boot environments often read the hardware clock as UTC. Note real time from your phone next to on-screen time when collecting.
