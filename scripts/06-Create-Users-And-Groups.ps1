param()

$ErrorActionPreference = "Stop"

$configPath = Join-Path $PSScriptRoot "..\lab.config.ps1"
if (-not (Test-Path $configPath)) {
  throw "Config not found: $configPath"
}
$LabConfig = . $configPath

Import-Module ActiveDirectory -ErrorAction Stop

$domainDN = (Get-ADDomain).DistinguishedName

function Get-OUPath([string]$ouName) {
  return "OU=$ouName,$domainDN"
}

# Create groups
foreach ($g in $LabConfig.Groups) {
  $path = Get-OUPath $g.PathOU
  $existing = Get-ADGroup -Filter "Name -eq '$($g.Name)'" -SearchBase $path -ErrorAction SilentlyContinue
  if (-not $existing) {
    Write-Host "Creating group: $($g.Name) in OU=$($g.PathOU)" -ForegroundColor Cyan
    New-ADGroup -Name $g.Name `
                -GroupScope $g.Scope `
                -GroupCategory $g.Category `
                -Path $path `
                -SamAccountName ($g.Name -replace "\s","") | Out-Null
  } else {
    Write-Host "Group '$($g.Name)' already exists. Skipping." -ForegroundColor Yellow
  }
}

# Create users and add to groups
foreach ($u in $LabConfig.Users) {
  $userPath = Get-OUPath $u.OU
  $sam = $u.SamAccountName
  $existingUser = Get-ADUser -Filter "SamAccountName -eq '$sam'" -SearchBase $userPath -ErrorAction SilentlyContinue
  if (-not $existingUser) {
    Write-Host "Creating user: $($u.GivenName) $($u.Surname) ($sam) in OU=$($u.OU)" -ForegroundColor Cyan
    $securePass = (ConvertTo-SecureString $u.Password -AsPlainText -Force)
    New-ADUser `
      -GivenName $u.GivenName `
      -Surname $u.Surname `
      -Name "$($u.GivenName) $($u.Surname)" `
      -SamAccountName $sam `
      -UserPrincipalName "$sam@$($LabConfig.DomainName)" `
      -Path $userPath `
      -AccountPassword $securePass `
      -ChangePasswordAtLogon $false `
      -Enabled $true | Out-Null
  } else {
    Write-Host "User '$sam' already exists. Skipping create." -ForegroundColor Yellow
  }

  # Ensure group memberships
  if ($u.Groups) {
    foreach ($gn in $u.Groups) {
      $group = Get-ADGroup -LDAPFilter "(cn=$gn)" -SearchBase $domainDN -ErrorAction SilentlyContinue
      if ($group) {
        try {
          Add-ADGroupMember -Identity $group -Members $sam -ErrorAction Stop
          Write-Host "Added '$sam' to group '$gn'." -ForegroundColor Green
        } catch {
          if (-not $_.Exception.Message.Contains("is already a member")) {
            throw
          } else {
            Write-Host "'$sam' already member of '$gn'." -ForegroundColor Yellow
          }
        }
      } else {
        Write-Host "Group '$gn' not found. Skipping membership." -ForegroundColor Yellow
      }
    }
  }
}

Write-Host "Users and groups created/updated." -ForegroundColor Green


