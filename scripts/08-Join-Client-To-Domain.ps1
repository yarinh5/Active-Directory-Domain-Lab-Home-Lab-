param(
  [string]$DomainJoinUser # e.g., "YARINLAB\Administrator" or "Administrator@yarinlab.local"
)

$ErrorActionPreference = "Stop"

$configPath = Join-Path $PSScriptRoot "..\lab.config.ps1"
if (-not (Test-Path $configPath)) {
  throw "Config not found: $configPath"
}
$LabConfig = . $configPath

$domain = $LabConfig.DomainName
$dcDns = $LabConfig.DC.IPAddress
$client = $LabConfig.Client

Write-Host "Setting client DNS to Domain Controller IP: $dcDns" -ForegroundColor Cyan
Set-DnsClientServerAddress -InterfaceAlias $client.InterfaceAlias -ServerAddresses $dcDns

if ($env:COMPUTERNAME -ne $client.ComputerName) {
  Write-Host "Renaming client to '$($client.ComputerName)'" -ForegroundColor Cyan
  Rename-Computer -NewName $client.ComputerName -Force
}

if (-not $DomainJoinUser) {
  $DomainJoinUser = Read-Host "Enter domain user (e.g., $($LabConfig.NetbiosName)\Administrator or Administrator@$domain)"
}
$cred = Get-Credential -UserName $DomainJoinUser -Message "Enter domain credentials for join:"

Write-Host "Joining domain '$domain'..." -ForegroundColor Cyan
Add-Computer -DomainName $domain -Credential $cred -Force

Write-Host "Restarting to complete domain join..." -ForegroundColor Cyan
Restart-Computer


