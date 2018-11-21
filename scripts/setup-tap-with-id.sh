#!/bin/bash -e

SB_ID="${1:-0}" # Default to 0
TAP_DEV="fc-${SB_ID}-tap0"

# Setup TAP device that uses proxy ARP
MASK_LONG="255.255.255.252"
MASK_SHORT="/30"
FC_IP="$(printf '169.254.%s.%s' $(((4 * SB_ID + 1) / 256)) $(((4 * SB_ID + 1) % 256)))"
TAP_IP="$(printf '169.254.%s.%s' $(((4 * SB_ID + 2) / 256)) $(((4 * SB_ID + 2) % 256)))"
FC_MAC="$(printf '02:FC:00:00:%02X:%02X' $((SB_ID / 256)) $((SB_ID % 256)))"
ip link del "$TAP_DEV" 2> /dev/null || true
ip tuntap add dev "$TAP_DEV" mode tap
sysctl -w net.ipv4.conf.${TAP_DEV}.proxy_arp=1 > /dev/null
sysctl -w net.ipv6.conf.${TAP_DEV}.disable_ipv6=1 > /dev/null
ip addr add "${TAP_IP}${MASK_SHORT}" dev "$TAP_DEV"
ip link set dev "$TAP_DEV" up

iperf3 -B $TAP_IP -s > /dev/null 2>&1 &

