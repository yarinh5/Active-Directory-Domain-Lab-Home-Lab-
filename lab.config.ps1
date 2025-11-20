<# Lab configuration. Adjust for your environment before running scripts. #>
$LabConfig = @{
  DomainName        = "yarinlab.local"
  NetbiosName       = "YARINLAB"

  DC = @{
    ComputerName   = "DC1"
    InterfaceAlias = "Ethernet"        # Adjust if your NIC alias differs
    IPAddress      = "192.168.56.10"   # Example: Host-only or NAT network
    PrefixLength   = 24
    Gateway        = "192.168.56.1"
    DnsServers     = @("192.168.56.10") # DC points to itself for DNS
  }

  DNS = @{
    Records = @(
      @{ Hostname = "dc1";    Address = "192.168.56.10" }
      @{ Hostname = "files1"; Address = "192.168.56.20" } # example placeholder
    )
  }

  OUs = @(
    "IT",
    "HR",
    "Finance",
    "Workstations"
  )

  Groups = @(
    @{ Name = "IT Admins";     PathOU = "IT";      Scope = "Global";  Category = "Security" },
    @{ Name = "HR Staff";      PathOU = "HR";      Scope = "Global";  Category = "Security" },
    @{ Name = "Finance Staff"; PathOU = "Finance"; Scope = "Global";  Category = "Security" }
  )

  Users = @(
    @{ GivenName = "Alice";  Surname = "Admin";   SamAccountName = "alice.admin";   OU = "IT";      Password = "P@ssw0rd123!" ; Groups = @("IT Admins")     },
    @{ GivenName = "Bob";    Surname = "Hansen";  SamAccountName = "bob.hansen";    OU = "HR";      Password = "P@ssw0rd123!" ; Groups = @("HR Staff")      },
    @{ GivenName = "Carol";  Surname = "Finch";   SamAccountName = "carol.finch";   OU = "Finance"; Password = "P@ssw0rd123!" ; Groups = @("Finance Staff") }
  )

  GPO = @{
    PasswordPolicy = @{
      ComplexityEnabled    = $true
      MinPasswordLength    = 12
      LockoutThreshold     = 5
      MaxPasswordAgeDays   = 90
      MinPasswordAgeDays   = 1
      PasswordHistoryCount = 10
    }
    DesktopWallpaper = @{
      Path  = (Join-Path $PSScriptRoot "assets\wallpaper.jpg")
      Style = 10   # 0 Center, 2 Stretch, 6 Fit, 10 Fill
    }
    DisableUSBStorage = $true
  }

  Client = @{
    ComputerName   = "CLIENT1"
    InterfaceAlias = "Ethernet"         # Adjust if different on client
  }
}

return $LabConfig


