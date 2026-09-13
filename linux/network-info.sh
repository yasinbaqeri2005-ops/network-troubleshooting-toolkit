#!/usr/bin/env bash
#
# network-info.sh
# Displays a clean, consolidated summary of the current network
# configuration for all active interfaces.
#
# Usage:
#   ./network-info.sh
#
# Author : Mohammad Yasin Bagheri
# Part of: network-troubleshooting-toolkit

set -uo pipefail

YELLOW="\033[1;33m"
GRAY="\033[0;90m"
NC="\033[0m"

echo -e "${YELLOW}Network Configuration Summary${NC}"
echo "Generated: $(date)"
echo ""

if ! command -v ip >/dev/null 2>&1; then
    echo "This script requires the 'ip' command (iproute2 package)."
    exit 1
fi

INTERFACES=$(ip -brief link show | awk '{print $1}' | grep -v "^lo$")

for iface in $INTERFACES; do
    STATE=$(ip -brief link show "$iface" | awk '{print $2}')
    [ "$STATE" != "UP" ] && continue

    MAC=$(ip link show "$iface" | awk '/link\/ether/ {print $2}')
    IPV4=$(ip -4 addr show "$iface" | awk '/inet/ {print $2}' | paste -sd, -)
    GATEWAY=$(ip route show default dev "$iface" 2>/dev/null | awk '{print $3; exit}')

    echo "Interface  : $iface"
    echo "Status     : $STATE"
    echo "MAC Address: ${MAC:-N/A}"
    echo "IPv4       : ${IPV4:-N/A}"
    echo "Gateway    : ${GATEWAY:-N/A}"

    if [ -f /etc/resolv.conf ]; then
        DNS=$(awk '/^nameserver/ {print $2}' /etc/resolv.conf | paste -sd, -)
        echo "DNS Servers: ${DNS:-N/A}"
    fi

    echo "------------------------------------"
done

echo -e "${GRAY}Public IP lookup skipped (requires internet call).${NC}"
echo -e "${GRAY}Tip: run 'curl -s https://api.ipify.org' manually if needed.${NC}"
