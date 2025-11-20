param(
  [securestring]$SafeModeAdminPassword
)

$ErrorActionPreference = "Stop"

$configPath = Join-Path $PSScriptRoot "..\lab.config.ps1"
if (-not (Test-Path $configPath)) {
  throw "Config not found: $configPath"
}
$LabConfig = . $configPath

if (-not $SafeModeAdminPassword) {
  Write-Host "Enter DSRM (Safe Mode) Administrator password..." -ForegroundColor Yellow
  $SafeModeAdminPassword = Read-Host -AsSecureString "Safe Mode Admin Password"
}

Write-Host "Installing AD DS role..." -ForegroundColor Cyan
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

Write-Host "Promoting to new forest '$($LabConfig.DomainName)' (DNS included)..." -ForegroundColor Cyan
Install-ADDSForest `
  -DomainName $LabConfig.DomainName `
  -DomainNetbiosName $LabConfig.NetbiosName `
  -SafeModeAdministratorPassword $SafeModeAdminPassword `
  -InstallDNS:$true `
  -Force

# Note: Server will reboot automatically after successful promotion.


