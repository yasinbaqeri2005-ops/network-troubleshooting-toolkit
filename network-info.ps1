<#
.SYNOPSIS
    Displays a clean, consolidated summary of the current network
    configuration for all active adapters.

.DESCRIPTION
    Pulls together IP address, subnet mask, default gateway, DNS servers,
    and MAC address per active adapter into a single readable table -
    instead of digging through multiple `ipconfig /all` sections manually.

.EXAMPLE
    .\network-info.ps1

.NOTES
    Author : Mohammad Yasin Bagheri
    Part of: network-troubleshooting-toolkit
#>

[CmdletBinding()]
param()

Write-Host "Network Configuration Summary" -ForegroundColor Yellow
Write-Host "Generated: $(Get-Date)"
Write-Host ""

$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

if (-not $adapters) {
    Write-Host "No active network adapters found." -ForegroundColor Red
    return
}

$summary = foreach ($adapter in $adapters) {
    $ipConfig = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
    $ipv4     = ($ipConfig.IPv4Address).IPAddress -join ", "
    $gateway  = ($ipConfig.IPv4DefaultGateway).NextHop -join ", "
    $dns      = ($ipConfig.DNSServer | Where-Object { $_.AddressFamily -eq 2 }).ServerAddresses -join ", "

    [PSCustomObject]@{
        Adapter    = $adapter.Name
        Status     = $adapter.Status
        MACAddress = $adapter.MacAddress
        IPv4       = $ipv4
        Gateway    = $gateway
        DNSServers = $dns
        LinkSpeed  = $adapter.LinkSpeed
    }
}

$summary | Format-List

Write-Host "Public IP lookup skipped (requires internet call)." -ForegroundColor DarkGray
Write-Host "Tip: run 'Invoke-RestMethod https://api.ipify.org' manually if needed." -ForegroundColor DarkGray
