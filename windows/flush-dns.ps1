<#
.SYNOPSIS
    Flushes the DNS resolver cache and optionally resets network adapters.

.DESCRIPTION
    Common first step in troubleshooting "internet works but a site won't
    load" style issues. Clears the local DNS cache and, if -ResetAdapters
    is specified, disables/re-enables active adapters to force a fresh
    DHCP lease and ARP table.

.PARAMETER ResetAdapters
    If specified, also disables and re-enables active network adapters.
    Requires an elevated (Administrator) PowerShell session.

.EXAMPLE
    .\flush-dns.ps1
    .\flush-dns.ps1 -ResetAdapters

.NOTES
    Author : Mohammad Yasin Bagheri
    Part of: network-troubleshooting-toolkit
    Requires: Run as Administrator for -ResetAdapters
#>

[CmdletBinding()]
param(
    [switch]$ResetAdapters
)

function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal   = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Write-Host "DNS Flush / Adapter Reset Utility" -ForegroundColor Yellow
Write-Host "Started: $(Get-Date)"
Write-Host ""

# 1. Flush DNS cache
try {
    Clear-DnsClientCache -ErrorAction Stop
    Write-Host "[OK] DNS resolver cache cleared." -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Could not clear DNS cache: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Release / renew DHCP lease
try {
    ipconfig /release  | Out-Null
    ipconfig /renew    | Out-Null
    Write-Host "[OK] DHCP lease released and renewed." -ForegroundColor Green
} catch {
    Write-Host "[FAIL] DHCP release/renew failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Re-register DNS
try {
    ipconfig /registerdns | Out-Null
    Write-Host "[OK] DNS registration requested." -ForegroundColor Green
} catch {
    Write-Host "[FAIL] DNS re-registration failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Optional adapter reset (requires admin)
if ($ResetAdapters) {
    if (-not (Test-IsAdmin)) {
        Write-Host "[SKIP] Adapter reset requires an elevated (Administrator) session." -ForegroundColor Yellow
    } else {
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        foreach ($a in $adapters) {
            try {
                Write-Host "Resetting adapter: $($a.Name) ..."
                Disable-NetAdapter -Name $a.Name -Confirm:$false -ErrorAction Stop
                Start-Sleep -Seconds 2
                Enable-NetAdapter -Name $a.Name -Confirm:$false -ErrorAction Stop
                Write-Host "[OK] $($a.Name) reset." -ForegroundColor Green
            } catch {
                Write-Host "[FAIL] Could not reset $($a.Name): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

Write-Host ""
Write-Host "Done." -ForegroundColor Yellow
