param()

$ErrorActionPreference = "Stop"

$configPath = Join-Path $PSScriptRoot "..\lab.config.ps1"
if (-not (Test-Path $configPath)) {
  throw "Config not found: $configPath"
}
$LabConfig = . $configPath
$dc = $LabConfig.DC

Write-Host "Setting static IP on interface '$($dc.InterfaceAlias)'" -ForegroundColor Cyan

# Ensure adapter exists
$adapter = Get-NetAdapter -Name $dc.InterfaceAlias -ErrorAction Stop

# Remove existing IPs on the interface (IPv4 only)
Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias $dc.InterfaceAlias -ErrorAction SilentlyContinue | `
  Where-Object { $_.IPAddress -ne $dc.IPAddress } | `
  ForEach-Object { Remove-NetIPAddress -InputObject $_ -Confirm:$false }

# Configure static IPv4
if (-not (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias $dc.InterfaceAlias | Where-Object { $_.IPAddress -eq $dc.IPAddress })) {
  New-NetIPAddress -InterfaceAlias $dc.InterfaceAlias `
                   -IPAddress $dc.IPAddress `
                   -PrefixLength $dc.PrefixLength `
                   -DefaultGateway $dc.Gateway
}

# Configure DNS servers
if ($dc.DnsServers -and $dc.DnsServers.Count -gt 0) {
  Set-DnsClientServerAddress -InterfaceAlias $dc.InterfaceAlias -ServerAddresses $dc.DnsServers
}

Write-Host "Static IP and DNS configured." -ForegroundColor Green


