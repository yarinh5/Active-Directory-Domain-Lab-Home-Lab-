param()

$ErrorActionPreference = "Stop"

$configPath = Join-Path $PSScriptRoot "..\lab.config.ps1"
if (-not (Test-Path $configPath)) {
  throw "Config not found: $configPath"
}
$LabConfig = . $configPath

Import-Module GroupPolicy -ErrorAction Stop
Import-Module ActiveDirectory -ErrorAction Stop

$domain = (Get-ADDomain).DNSRoot

# 1) Set Default Domain Password Policy
$pwd = $LabConfig.GPO.PasswordPolicy
Write-Host "Setting default domain password policy..." -ForegroundColor Cyan
Set-ADDefaultDomainPasswordPolicy `
  -Identity $domain `
  -MinPasswordLength $pwd.MinPasswordLength `
  -ComplexityEnabled:$pwd.ComplexityEnabled `
  -LockoutThreshold $pwd.LockoutThreshold `
  -MaxPasswordAge (New-TimeSpan -Days $pwd.MaxPasswordAgeDays) `
  -MinPasswordAge (New-TimeSpan -Days $pwd.MinPasswordAgeDays) `
  -PasswordHistoryCount $pwd.PasswordHistoryCount

# 2) Desktop Wallpaper GPO (User Configuration)
$wall = $LabConfig.GPO.DesktopWallpaper
$gpoNameWallpaper = "Desktop Wallpaper Policy"
$gpoWallpaper = Get-GPO -Name $gpoNameWallpaper -ErrorAction SilentlyContinue
if (-not $gpoWallpaper) {
  $gpoWallpaper = New-GPO -Name $gpoNameWallpaper
}
if (-not (Get-GPLink -Target "dc=$($domain -replace '\.',',dc=')" -ErrorAction SilentlyContinue | Where-Object { $_.GPOName -eq $gpoNameWallpaper })) {
  New-GPLink -Name $gpoNameWallpaper -Target $domain | Out-Null
}

Write-Host "Configuring Desktop Wallpaper policy..." -ForegroundColor Cyan
Set-GPRegistryValue -Name $gpoNameWallpaper `
  -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
  -ValueName "Wallpaper" -Type String -Value $wall.Path
Set-GPRegistryValue -Name $gpoNameWallpaper `
  -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
  -ValueName "WallpaperStyle" -Type String -Value ([string]$wall.Style)

# 3) Disable USB Storage (Computer Configuration via registry)
if ($LabConfig.GPO.DisableUSBStorage) {
  $gpoNameUSB = "Disable USB Storage"
  $gpoUSB = Get-GPO -Name $gpoNameUSB -ErrorAction SilentlyContinue
  if (-not $gpoUSB) {
    $gpoUSB = New-GPO -Name $gpoNameUSB
  }
  if (-not (Get-GPLink -Target $domain -ErrorAction SilentlyContinue | Where-Object { $_.GPOName -eq $gpoNameUSB })) {
    New-GPLink -Name $gpoNameUSB -Target $domain | Out-Null
  }

  Write-Host "Configuring USB mass storage block (USBSTOR service disabled)..." -ForegroundColor Cyan
  # Set USBSTOR service Start=4 (Disabled)
  Set-GPRegistryValue -Name $gpoNameUSB `
    -Key "HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR" `
    -ValueName "Start" -Type DWord -Value 4
}

Write-Host "GPOs configured." -ForegroundColor Green


