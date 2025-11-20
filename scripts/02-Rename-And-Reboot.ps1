param()

$ErrorActionPreference = "Stop"

$configPath = Join-Path $PSScriptRoot "..\lab.config.ps1"
if (-not (Test-Path $configPath)) {
  throw "Config not found: $configPath"
}
$LabConfig = . $configPath
$dc = $LabConfig.DC

if ((hostname) -ieq $dc.ComputerName) {
  Write-Host "Computer already named '$($dc.ComputerName)'. Skipping rename." -ForegroundColor Yellow
} else {
  Write-Host "Renaming computer to '$($dc.ComputerName)'" -ForegroundColor Cyan
  Rename-Computer -NewName $dc.ComputerName -Force
  Write-Host "Rebooting..." -ForegroundColor Cyan
  Restart-Computer
}


