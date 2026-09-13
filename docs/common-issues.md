# Common Network Issues & Troubleshooting Logic

A quick-reference checklist for diagnosing everyday network problems,
following a layered approach (physical → link → IP → DNS → application).
This mirrors the logic the scripts in this repo automate.

---

## 1. "No internet access at all"

**Check in this order:**
1. Is the network adapter enabled and showing "Up"?
   → `windows/network-info.ps1` or `linux/network-info.sh`
2. Do you have a valid IP address (not `169.254.x.x` / APIPA)?
   → A `169.254.x.x` address means DHCP failed — check the router/switch port or cable.
3. Can you reach the default gateway?
   → `windows/check-connectivity.ps1` or `linux/check-connectivity.sh`
4. If the gateway responds but nothing beyond it does, the issue is
   upstream (ISP, router WAN link, or routing on the gateway itself).

---

## 2. "Internet works, but a specific site won't load"

This is almost always a **DNS** issue, not a connectivity issue.

1. Try pinging the site's IP address directly (bypasses DNS).
   - Works by IP, fails by name → DNS problem.
2. Flush the local DNS cache.
   → `windows/flush-dns.ps1`
3. Try an alternate DNS resolver (e.g. `8.8.8.8` or `1.1.1.1`) to rule out
   a bad/blocked upstream DNS server.
4. Check if the domain is reachable from another network (phone on
   mobile data) — if not, the issue may be on the site's end.

---

## 3. "Intermittent drops / slow connection"

1. Run a continuous ping to the gateway and to an external IP at the
   same time. If the gateway also drops, the problem is local
   (Wi-Fi interference, bad cable, switch port).
2. If only the external ping drops while the gateway stays stable,
   the issue is upstream (ISP or routing beyond your network).
3. Check `LinkSpeed` (Windows) — a duplex/speed mismatch often shows up
   as a much lower negotiated speed than expected.
4. On Wi-Fi, check for channel congestion or move closer to the AP to
   rule out a signal-strength issue before assuming a config problem.

---

## 4. "Can't reach a specific service (e.g. a web app or API)"

1. Confirm basic connectivity works first (see section 1).
2. Test the *specific port* the service uses, not just ICMP ping —
   many servers block ICMP but still serve traffic on their real port.
   → the "Common Ports" check in `check-connectivity.ps1` / `.sh`
3. If the port test fails but the host responds to ping, suspect:
   - A firewall rule blocking that specific port
   - The service not actually running on the target host
4. If the port test succeeds but the application still fails, the
   issue is likely application-layer (auth, TLS certificate, etc.),
   not networking.

---

## 5. "Adapter shows connected, but nothing works"

1. Release and renew the DHCP lease.
   → included in `windows/flush-dns.ps1`
2. If that doesn't help, disable/re-enable the adapter to force a full
   re-negotiation (link, DHCP, ARP table).
   → `windows/flush-dns.ps1 -ResetAdapters` (requires Administrator)
3. Check for a duplicate IP address on the network — this often
   presents as "connected" but completely non-functional.

---

## General principle behind these scripts

Every script here follows the same layered logic a network engineer
uses manually:

```
Physical/Link  →  IP/Gateway  →  DNS  →  Port/Service  →  Application
```

Testing in this order narrows down *where* the failure is before
jumping to conclusions — which is the actual point of this toolkit.
