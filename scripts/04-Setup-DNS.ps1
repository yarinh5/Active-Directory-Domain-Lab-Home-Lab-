param()

$ErrorActionPreference = "Stop"

$configPath = Join-Path $PSScriptRoot "..\lab.config.ps1"
if (-not (Test-Path $configPath)) {
  throw "Config not found: $configPath"
}
$LabConfig = . $configPath

Import-Module DNSServer -ErrorAction Stop

$domain = $LabConfig.DomainName

function Get-ReverseZoneName([string]$ipv4) {
  $octets = $ipv4.Split(".")
  if ($octets.Count -lt 3) {
    throw "IP address not in expected format: $ipv4"
  }
  # Build a /24 reverse zone, e.g., 192.168.56 -> 56.168.192.in-addr.arpa
  return "$($octets[2]).$($octets[1]).$($octets[0]).in-addr.arpa"
}

function Ensure-ReverseZone([string]$reverseZone) {
  $exists = Get-DnsServerZone -ErrorAction SilentlyContinue | Where-Object { $_.ZoneName -ieq $reverseZone }
  if (-not $exists) {
    Write-Host "Creating reverse lookup zone: $reverseZone" -ForegroundColor Cyan
    New-DnsServerPrimaryZone -NetworkId ($reverseZone -replace "\.in-addr\.arpa$","") -ZoneFile "$reverseZone.dns" -ErrorAction Stop
  }
}

Write-Host "Creating forward and reverse DNS records..." -ForegroundColor Cyan

# Ensure reverse zone for each record
$LabConfig.DNS.Records | ForEach-Object {
  $revZone = Get-ReverseZoneName $_.Address
  Ensure-ReverseZone $revZone
}

$LabConfig.DNS.Records | ForEach-Object {
  $host = $_.Hostname
  $addr = $_.Address

  # Forward A record
  $existingA = Get-DnsServerResourceRecord -ZoneName $domain -RRType "A" -ErrorAction SilentlyContinue | `
    Where-Object { $_.HostName -ieq $host }
  if (-not $existingA) {
    Add-DnsServerResourceRecordA -Name $host -ZoneName $domain -IPv4Address $addr -AllowUpdateAny -CreatePtr
    Write-Host "A/PTR created: $host.$domain -> $addr" -ForegroundColor Green
  } else {
    Write-Host "A record exists for $host.$domain. Skipping." -ForegroundColor Yellow
  }
}

Write-Host "DNS setup complete." -ForegroundColor Green


