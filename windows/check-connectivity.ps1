<#
.SYNOPSIS
    Checks basic network connectivity: default gateway, DNS resolution,
    and internet reachability, plus common service ports.

.DESCRIPTION
    Runs a layered connectivity test (similar to how a network engineer
    would troubleshoot manually):
      1. Local adapter status
      2. Default gateway reachability (Layer 3 - LAN)
      3. DNS resolution (is name resolution working?)
      4. Internet reachability (can we reach the outside world?)
      5. Common ports (HTTP/HTTPS/DNS) reachability test

.PARAMETER TargetHost
    Optional external host to test against. Defaults to 8.8.8.8 / google.com.

.EXAMPLE
    .\check-connectivity.ps1
    .\check-connectivity.ps1 -TargetHost "1.1.1.1"

.NOTES
    Author : Mohammad Yasin Bagheri
    Part of: network-troubleshooting-toolkit
#>

[CmdletBinding()]
param(
    [string]$TargetHost = "8.8.8.8",
    [string]$TargetDomain = "google.com"
)

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "== $Title ==" -ForegroundColor Cyan
}

function Write-Result {
    param([string]$Label, [bool]$Success, [string]$Detail = "")
    $status = if ($Success) { "OK" } else { "FAIL" }
    $color  = if ($Success) { "Green" } else { "Red" }
    Write-Host ("{0,-35} [{1}] {2}" -f $Label, $status, $Detail) -ForegroundColor $color
}

Write-Host "Network Connectivity Check" -ForegroundColor Yellow
Write-Host "Started: $(Get-Date)"

# 1. Adapter status
Write-Section "Network Adapters"
$adapters = Get-NetAdapter | Where-Object { $_.Status -ne "Disabled" }
if (-not $adapters) {
    Write-Result "Active adapters found" $false "No enabled adapters detected"
} else {
    foreach ($a in $adapters) {
        Write-Result $a.Name ($a.Status -eq "Up") $a.Status
    }
}

# 2. Default gateway
Write-Section "Default Gateway"
$gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue |
            Sort-Object -Property RouteMetric | Select-Object -First 1).NextHop

if (-not $gateway) {
    Write-Result "Gateway detected" $false "No default route found"
} else {
    $gwPing = Test-Connection -ComputerName $gateway -Count 2 -Quiet -ErrorAction SilentlyContinue
    Write-Result "Gateway ($gateway)" $gwPing
}

# 3. DNS resolution
Write-Section "DNS Resolution"
try {
    $dnsResult = Resolve-DnsName -Name $TargetDomain -ErrorAction Stop
    Write-Result "Resolve $TargetDomain" $true ($dnsResult[0].IPAddress)
} catch {
    Write-Result "Resolve $TargetDomain" $false $_.Exception.Message
}

# 4. Internet reachability (by IP, bypasses DNS)
Write-Section "Internet Reachability"
$internetPing = Test-Connection -ComputerName $TargetHost -Count 3 -Quiet -ErrorAction SilentlyContinue
Write-Result "Ping $TargetHost" $internetPing

# 5. Common service ports
Write-Section "Common Ports"
$portsToTest = @(
    @{ Name = "DNS (53)";    Target = $TargetHost;   Port = 53  }
    @{ Name = "HTTP (80)";   Target = $TargetDomain; Port = 80  }
    @{ Name = "HTTPS (443)"; Target = $TargetDomain; Port = 443 }
)

foreach ($p in $portsToTest) {
    try {
        $test = Test-NetConnection -ComputerName $p.Target -Port $p.Port -WarningAction SilentlyContinue
        Write-Result $p.Name $test.TcpTestSucceeded
    } catch {
        Write-Result $p.Name $false $_.Exception.Message
    }
}

Write-Host ""
Write-Host "Check complete." -ForegroundColor Yellow
