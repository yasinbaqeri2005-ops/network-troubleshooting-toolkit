#!/usr/bin/env bash
#
# check-connectivity.sh
# Layered network connectivity check: gateway, DNS, internet, common ports.
#
# Usage:
#   ./check-connectivity.sh
#   ./check-connectivity.sh 1.1.1.1 cloudflare.com
#
# Author : Mohammad Yasin Bagheri
# Part of: network-troubleshooting-toolkit

set -uo pipefail

TARGET_IP="${1:-8.8.8.8}"
TARGET_DOMAIN="${2:-google.com}"

GREEN="\033[0;32m"
RED="\033[0;31m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
NC="\033[0m"

print_section() {
    echo -e "\n${CYAN}== $1 ==${NC}"
}

print_result() {
    local label="$1"
    local success="$2"
    local detail="${3:-}"
    if [ "$success" -eq 0 ]; then
        printf "%-35s [${GREEN}OK${NC}] %s\n" "$label" "$detail"
    else
        printf "%-35s [${RED}FAIL${NC}] %s\n" "$label" "$detail"
    fi
}

echo -e "${YELLOW}Network Connectivity Check${NC}"
echo "Started: $(date)"

# 1. Interface status
print_section "Network Interfaces"
if command -v ip >/dev/null 2>&1; then
    ip -brief link show | grep -v "^lo" | while read -r line; do
        iface=$(echo "$line" | awk '{print $1}')
        state=$(echo "$line" | awk '{print $2}')
        if [ "$state" = "UP" ]; then
            print_result "$iface" 0 "$state"
        else
            print_result "$iface" 1 "$state"
        fi
    done
else
    print_result "ip command available" 1 "iproute2 not installed"
fi

# 2. Default gateway
print_section "Default Gateway"
GATEWAY=$(ip route show default 2>/dev/null | awk '/default/ {print $3; exit}')
if [ -z "$GATEWAY" ]; then
    print_result "Gateway detected" 1 "No default route found"
else
    if ping -c 2 -W 2 "$GATEWAY" >/dev/null 2>&1; then
        print_result "Gateway ($GATEWAY)" 0
    else
        print_result "Gateway ($GATEWAY)" 1 "No reply"
    fi
fi

# 3. DNS resolution
print_section "DNS Resolution"
if command -v getent >/dev/null 2>&1 && getent hosts "$TARGET_DOMAIN" >/dev/null 2>&1; then
    RESOLVED_IP=$(getent hosts "$TARGET_DOMAIN" | awk '{print $1; exit}')
    print_result "Resolve $TARGET_DOMAIN" 0 "$RESOLVED_IP"
else
    print_result "Resolve $TARGET_DOMAIN" 1 "Resolution failed"
fi

# 4. Internet reachability (by IP, bypasses DNS)
print_section "Internet Reachability"
if ping -c 3 -W 2 "$TARGET_IP" >/dev/null 2>&1; then
    print_result "Ping $TARGET_IP" 0
else
    print_result "Ping $TARGET_IP" 1 "No reply"
fi

# 5. Common ports
print_section "Common Ports"
check_port() {
    local host="$1" port="$2" label="$3"
    if command -v nc >/dev/null 2>&1; then
        if nc -z -w 2 "$host" "$port" >/dev/null 2>&1; then
            print_result "$label" 0
        else
            print_result "$label" 1
        fi
    elif command -v timeout >/dev/null 2>&1; then
        if timeout 2 bash -c "cat < /dev/null > /dev/tcp/$host/$port" >/dev/null 2>&1; then
            print_result "$label" 0
        else
            print_result "$label" 1
        fi
    else
        print_result "$label" 1 "no nc/timeout available"
    fi
}

check_port "$TARGET_IP" 53 "DNS (53)"
check_port "$TARGET_DOMAIN" 80 "HTTP (80)"
check_port "$TARGET_DOMAIN" 443 "HTTPS (443)"

echo -e "\n${YELLOW}Check complete.${NC}"
