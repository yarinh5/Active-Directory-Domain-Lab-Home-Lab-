param()

$ErrorActionPreference = "Stop"

$configPath = Join-Path $PSScriptRoot "..\lab.config.ps1"
if (-not (Test-Path $configPath)) {
  throw "Config not found: $configPath"
}
$LabConfig = . $configPath

Import-Module GroupPolicy -ErrorAction Stop
Import-Module ActiveDirectory -ErrorAction Stop

$root = Join-Path $PSScriptRoot ".."
$exportRoot = Join-Path $root "exports"
$gpoPath = Join-Path $exportRoot "gpo"
$evPath  = Join-Path $exportRoot "event-logs"
$adPath  = Join-Path $exportRoot "ad"

New-Item -ItemType Directory -Force -Path $gpoPath, $evPath, $adPath | Out-Null

Write-Host "Exporting GPO backups and reports..." -ForegroundColor Cyan
Backup-GPO -All -Path $gpoPath | Out-Null
Get-GPO -All | ForEach-Object {
  $name = $_.DisplayName -replace '[\\/:*?"<>|]', "_"
  Get-GPOReport -Guid $_.Id -ReportType Html -Path (Join-Path $gpoPath "$name.html")
}

Write-Host "Exporting Windows Event Logs (EVTX)..." -ForegroundColor Cyan
wevtutil epl System      (Join-Path $evPath "System.evtx")
wevtutil epl Application (Join-Path $evPath "Application.evtx")
wevtutil epl Security    (Join-Path $evPath "Security.evtx")

Write-Host "Exporting AD Users and LastLogonDate (CSV)..." -ForegroundColor Cyan
Get-ADUser -Filter * -Properties DisplayName,Mail,GivenName,Surname,Enabled,LastLogonDate,WhenCreated | `
  Select-Object SamAccountName,DisplayName,GivenName,Surname,Enabled,LastLogonDate,WhenCreated | `
  Sort-Object SamAccountName | `
  Export-Csv -Path (Join-Path $adPath "users.csv") -NoTypeInformation -Encoding UTF8

Write-Host "Exporting logon events (4624) to CSV..." -ForegroundColor Cyan
$logonCsv = Join-Path $adPath "logons-4624.csv"
Get-WinEvent -FilterHashtable @{LogName="Security"; Id=4624; StartTime=(Get-Date).AddDays(-7)} -ErrorAction SilentlyContinue | `
  ForEach-Object {
    $xml = [xml]$_.ToXml()
    [pscustomobject]@{
      TimeCreated = $_.TimeCreated
      TargetUser  = $xml.Event.EventData.Data | Where-Object { $_.Name -eq "TargetUserName" } | Select-Object -ExpandProperty "#text"
      TargetDomain= $xml.Event.EventData.Data | Where-Object { $_.Name -eq "TargetDomainName" } | Select-Object -ExpandProperty "#text"
      IpAddress   = $xml.Event.EventData.Data | Where-Object { $_.Name -eq "IpAddress" } | Select-Object -ExpandProperty "#text"
      LogonType   = $xml.Event.EventData.Data | Where-Object { $_.Name -eq "LogonType" } | Select-Object -ExpandProperty "#text"
      Workstation = $xml.Event.EventData.Data | Where-Object { $_.Name -eq "WorkstationName" } | Select-Object -ExpandProperty "#text"
    }
  } | Export-Csv -Path $logonCsv -NoTypeInformation -Encoding UTF8

Write-Host "Exports completed under '$exportRoot'." -ForegroundColor Green


