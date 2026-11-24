# Ventoy configuration

`ventoy.json` opens the boot menu in folder view (F3 switches back to the flat list) and gives each folder a readable name. Aliases for folders not on the drive are ignored.

Install it on a Ventoy drive (replace D:):

```powershell
New-Item -ItemType Directory -Path D:\ventoy -Force | Out-Null
$json = Get-Content .\ventoy.json -Raw
[IO.File]::WriteAllText("D:\ventoy\ventoy.json", $json, (New-Object Text.UTF8Encoding($false)))
Get-Content D:\ventoy\ventoy.json -Raw | ConvertFrom-Json | Out-Null; "JSON OK"
```

The `WriteAllText` line saves without a byte-order mark. Windows PowerShell 5.1 `Set-Content -Encoding UTF8` adds one.

Hide a folder from the menu (for example an Archive of ISOs that fail to boot through Ventoy) with an empty `.ventoyignore` file inside it.
