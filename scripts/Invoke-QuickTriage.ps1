<#
.SYNOPSIS
    Quick live triage using built-in Windows cmdlets only. Read-only on the host.
.DESCRIPTION
    Collects volatile and configuration data into a case folder, then hashes every
    output file into hashes.csv for chain of custody. Writes nothing to the host disk.
.PARAMETER CaseRoot
    Case folder on the evidence drive, for example G:\Cases\2026-11-22_P4IT-0001
.EXAMPLE
    .\Invoke-QuickTriage.ps1 -CaseRoot G:\Cases\2026-11-22_P4IT-0001
.NOTES
    Version 1.1 (2026-11-23): Run keys now cover every loaded user profile, plus Winlogon and a user profile coverage list.
    Run from an elevated PowerShell for full results. Tell the client's security contact before running on a client host.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$CaseRoot
)

$ErrorActionPreference = 'Continue'
$hostName = $env:COMPUTERNAME
$stamp    = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$outDir   = Join-Path $CaseRoot "Triage\$hostName`_$stamp"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$log = Join-Path $outDir '00_collection_log.txt'
function Write-Log([string]$msg) {
    $line = "{0}  {1}" -f (Get-Date).ToUniversalTime().ToString('o'), $msg
    Add-Content -Path $log -Value $line
    Write-Host $line
}

function Save-Csv([string]$name, [scriptblock]$block) {
    try {
        & $block | Export-Csv -Path (Join-Path $outDir "$name.csv") -NoTypeInformation -Encoding UTF8
        Write-Log "OK   $name"
    } catch {
        Write-Log "FAIL $name : $($_.Exception.Message)"
    }
}

Write-Log "Start triage. Host=$hostName User=$env:USERDOMAIN\$env:USERNAME Elevated=$(([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))"

# System
Save-Csv '01_system'        { Get-CimInstance Win32_OperatingSystem | Select-Object CSName, Caption, Version, BuildNumber, InstallDate, LastBootUpTime, LocalDateTime }
Save-Csv '02_timezone'      { Get-TimeZone | Select-Object Id, DisplayName, BaseUtcOffset }
Save-Csv '03_hotfixes'      { Get-HotFix | Select-Object HotFixID, Description, InstalledOn, InstalledBy }

# Users and sessions
Save-Csv '04_local_users'   { Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordLastSet, SID }
Save-Csv '05_local_admins'  { Get-LocalGroupMember -Group 'Administrators' | Select-Object Name, ObjectClass, PrincipalSource, SID }
Save-Csv '06_logon_sessions'{ Get-CimInstance Win32_LogonSession | Select-Object LogonId, LogonType, StartTime, AuthenticationPackage }

# Processes and network
Save-Csv '07_processes'     { Get-CimInstance Win32_Process | Select-Object ProcessId, ParentProcessId, Name, ExecutablePath, CommandLine, CreationDate }
Save-Csv '08_tcp'           { Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess, CreationTime }
Save-Csv '09_udp'           { Get-NetUDPEndpoint | Select-Object LocalAddress, LocalPort, OwningProcess, CreationTime }
Save-Csv '10_dns_cache'     { Get-DnsClientCache | Select-Object Entry, Name, Type, Data, TimeToLive }
Save-Csv '11_ip_config'     { Get-NetIPConfiguration | Select-Object InterfaceAlias, @{n='IPv4';e={$_.IPv4Address.IPAddress -join ';'}}, @{n='Gateway';e={$_.IPv4DefaultGateway.NextHop -join ';'}}, @{n='DNS';e={$_.DNSServer.ServerAddresses -join ';'}} }
Save-Csv '12_arp'           { Get-NetNeighbor | Select-Object IPAddress, LinkLayerAddress, State, InterfaceAlias }
Save-Csv '13_smb_shares'    { Get-SmbShare | Select-Object Name, Path, Description }

# Persistence
Save-Csv '14_services'      { Get-CimInstance Win32_Service | Select-Object Name, DisplayName, State, StartMode, StartName, PathName }
Save-Csv '15_sched_tasks'   { Get-ScheduledTask | Select-Object TaskPath, TaskName, State, Author, @{n='Actions';e={($_.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)" }) -join ' | '}} }
Save-Csv '16_run_keys'      {
    # Machine-wide Run keys (64-bit and 32-bit views)
    $keys = @()
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce' | ForEach-Object {
        $keys += [pscustomobject]@{ Scope = 'Machine'; User = '(all users)'; Key = $_ }
    }
    # Per-user Run keys for every loaded user profile (HKCU only covers the account running the script)
    if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
        New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
    }
    Get-ChildItem 'HKU:\' | Where-Object { $_.PSChildName -match '^S-1-5-21-[\d-]+$' } | ForEach-Object {
        $sid  = $_.PSChildName
        $user = try { (New-Object System.Security.Principal.SecurityIdentifier($sid)).Translate([System.Security.Principal.NTAccount]).Value } catch { $sid }
        foreach ($sub in 'Software\Microsoft\Windows\CurrentVersion\Run', 'Software\Microsoft\Windows\CurrentVersion\RunOnce') {
            $keys += [pscustomobject]@{ Scope = 'User'; User = $user; Key = "HKU:\$sid\$sub" }
        }
    }
    foreach ($k in $keys) {
        if (Test-Path $k.Key) {
            $props = Get-ItemProperty -Path $k.Key
            foreach ($p in ($props.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' })) {
                [pscustomobject]@{ Scope = $k.Scope; User = $k.User; Key = $k.Key; Name = $p.Name; Value = $p.Value }
            }
        }
    }
}
Save-Csv '17_startup_folder'{ Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location, User }

# Security posture
Save-Csv '18_defender'      { Get-MpComputerStatus | Select-Object AMServiceEnabled, AntivirusEnabled, RealTimeProtectionEnabled, AntivirusSignatureLastUpdated, IsTamperProtected }
Save-Csv '19_firewall'      { Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction }
Save-Csv '20_installed_apps'{
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' | ForEach-Object {
        Get-ItemProperty -Path $_ -ErrorAction SilentlyContinue
    } | Where-Object DisplayName | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
}

# Recent security events (last 24 hours): logons, new services, new tasks, log clearing
Save-Csv '21_key_events_24h'{
    Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=4624,4625,4672,4720,4732,1102; StartTime=(Get-Date).AddHours(-24) } -MaxEvents 5000 -ErrorAction SilentlyContinue |
        Select-Object TimeCreated, Id, ProviderName, @{n='Message';e={($_.Message -split "`n")[0]}}
}
Save-Csv '22_system_events_24h'{
    Get-WinEvent -FilterHashtable @{ LogName='System'; Id=7045,104; StartTime=(Get-Date).AddHours(-24) } -ErrorAction SilentlyContinue |
        Select-Object TimeCreated, Id, ProviderName, @{n='Message';e={($_.Message -split "`n")[0]}}
}

# Persistence and coverage extras
Save-Csv '23_winlogon'      { Get-ItemProperty 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' | Select-Object Shell, Userinit, AutoAdminLogon, DefaultUserName }
# Lists every user profile and whether it was loaded. Unloaded profiles were NOT covered by 16_run_keys.
Save-Csv '24_user_profiles' { Get-CimInstance Win32_UserProfile | Where-Object { -not $_.Special } | Select-Object LocalPath, SID, Loaded, LastUseTime }

Write-Log "Collection finished. Hashing output files."

# Chain of custody hashes
Get-ChildItem -Path $outDir -File |
    Where-Object Name -ne 'hashes.csv' |
    Get-FileHash -Algorithm SHA256 |
    Select-Object @{n='File';e={Split-Path $_.Path -Leaf}}, Hash, @{n='HashedUtc';e={(Get-Date).ToUniversalTime().ToString('o')}} |
    Export-Csv -Path (Join-Path $outDir 'hashes.csv') -NoTypeInformation -Encoding UTF8

Write-Host "Done. Output: $outDir"
