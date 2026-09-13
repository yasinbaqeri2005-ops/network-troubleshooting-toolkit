# Network Troubleshooting Toolkit

A small collection of PowerShell and Bash scripts for diagnosing common
network connectivity issues — built around the same layered logic used
in real-world troubleshooting (physical → link → IP → DNS → application).

This started as a personal reference while studying for CCNA, and grew
into a set of scripts I actually use when troubleshooting networks.

## Why this exists

Most "network is down" problems can be narrowed down in under a minute
by checking things in the right order: adapter status → gateway →
DNS → the actual port/service. These scripts automate that sequence
instead of running the same five manual commands every time.

## Contents

| Script | Platform | Purpose |
|---|---|---|
| `windows/check-connectivity.ps1` | Windows | Gateway, DNS, internet, and common port checks |
| `windows/flush-dns.ps1` | Windows | Clears DNS cache, renews DHCP lease, optional adapter reset |
| `windows/network-info.ps1` | Windows | Consolidated IP/Gateway/DNS/MAC summary per adapter |
| `linux/check-connectivity.sh` | Linux | Same layered check as the Windows version |
| `linux/network-info.sh` | Linux | Consolidated network config summary |
| `docs/common-issues.md` | — | Troubleshooting checklist / decision logic |

## Usage

### Windows (PowerShell)

```powershell
# Run a full connectivity check
.\windows\check-connectivity.ps1

# Check against a specific host/domain
.\windows\check-connectivity.ps1 -TargetHost "1.1.1.1"

# Flush DNS and renew DHCP lease
.\windows\flush-dns.ps1

# Also reset network adapters (requires Administrator)
.\windows\flush-dns.ps1 -ResetAdapters

# Show a clean summary of current network config
.\windows\network-info.ps1
```

> If scripts are blocked from running, you may need to allow local
> scripts for the current session:
> `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`

### Linux (Bash)

```bash
chmod +x linux/*.sh

# Run a full connectivity check
./linux/check-connectivity.sh

# Check against a specific host/domain
./linux/check-connectivity.sh 1.1.1.1 cloudflare.com

# Show a clean summary of current network config
./linux/network-info.sh
```

## Example output

```
== Default Gateway ==
Gateway (192.168.1.1)              [OK]

== DNS Resolution ==
Resolve google.com                 [OK] 142.250.72.14

== Internet Reachability ==
Ping 8.8.8.8                       [OK]

== Common Ports ==
DNS (53)                           [OK]
HTTP (80)                          [OK]
HTTPS (443)                        [OK]
```

## Troubleshooting reference

See [`docs/common-issues.md`](docs/common-issues.md) for a checklist of
common issues (no internet, DNS-only failures, intermittent drops,
service-specific failures) and the reasoning behind each check.

## Roadmap

- [ ] Add a cross-platform Python version for portability
- [ ] Export results to JSON/CSV for logging
- [ ] Add a traceroute-based hop analysis script

## License

MIT — see [LICENSE](LICENSE).

## Author

**Mohammad Yasin Bagheri**
Computer Engineering Student | IT & Networking
