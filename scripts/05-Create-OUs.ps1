param()

$ErrorActionPreference = "Stop"

$configPath = Join-Path $PSScriptRoot "..\lab.config.ps1"
if (-not (Test-Path $configPath)) {
  throw "Config not found: $configPath"
}
$LabConfig = . $configPath

Import-Module ActiveDirectory -ErrorAction Stop

$domainDN = (Get-ADDomain).DistinguishedName

foreach ($ouName in $LabConfig.OUs) {
  $ouPath = "OU=$ouName,$domainDN"
  $exists = Get-ADOrganizationalUnit -LDAPFilter "(ou=$ouName)" -SearchBase $domainDN -SearchScope OneLevel -ErrorAction SilentlyContinue
  if (-not $exists) {
    Write-Host "Creating OU: $ouName" -ForegroundColor Cyan
    New-ADOrganizationalUnit -Name $ouName -Path $domainDN -ProtectedFromAccidentalDeletion $false | Out-Null
  } else {
    Write-Host "OU '$ouName' already exists. Skipping." -ForegroundColor Yellow
  }
}

Write-Host "OUs created." -ForegroundColor Green


