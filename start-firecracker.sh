#!/bin/bash -e
SB_ID="${1:-0}" # Default to sb_id=0

RO_DRIVE="$PWD/xenial.rootfs.ext4"

# TODO: Boot vmlinuz/bzImage when supported, https://sim.amazon.com/issues/P12329852
KERNEL="$PWD/vmlinux"
TAP_DEV="fc-${SB_ID}-tap0"

KERNEL_BOOT_ARGS="panic=1 pci=off reboot=k tsc=reliable quiet 8250.nr_uarts=0 ipv6.disable=1 $R_INIT"
#KERNEL_BOOT_ARGS="console=ttyS0 reboot=k panic=1 pci=off nomodules ipv6.disable=1 $R_INIT"

API_SOCKET="/tmp/firecracker-sb${SB_ID}.sock"
CURL=(curl --silent --show-error --header Content-Type:application/json --unix-socket "${API_SOCKET}" --write-out "HTTP %{http_code}")

curl_put() {
    local URL_PATH="$1"
    local OUTPUT RC
    OUTPUT="$("${CURL[@]}" -X PUT --data @- "http://localhost/${URL_PATH#/}" 2>&1)"
    RC="$?"
    if [ "$RC" -ne 0 ]; then
        echo "Error: curl PUT ${URL_PATH} failed with exit code $RC, output:"
        echo "$OUTPUT"
        return 1
    fi
    # Error if output doesn't end with "HTTP 2xx"
    if [[ "$OUTPUT" != *HTTP\ 2[0-9][0-9] ]]; then
        echo "Error: curl PUT ${URL_PATH} failed with non-2xx HTTP status code, output:"
        echo "$OUTPUT"
        return 1
    fi
}

logfile="$PWD/output/fc-sb${SB_ID}-log"
#metricsfile="$PWD/output/fc-sb${SB_ID}-metrics"
metricsfile="/dev/null"

touch $logfile

# Setup TAP device that uses proxy ARP
MASK_LONG="255.255.255.252"
#MASK_SHORT="/30"
FC_IP="$(printf '169.254.%s.%s' $(((4 * SB_ID + 1) / 256)) $(((4 * SB_ID + 1) % 256)))"
TAP_IP="$(printf '169.254.%s.%s' $(((4 * SB_ID + 2) / 256)) $(((4 * SB_ID + 2) % 256)))"
FC_MAC="$(printf '02:FC:00:00:%02X:%02X' $((SB_ID / 256)) $((SB_ID % 256)))"
#ip link del "$TAP_DEV" 2> /dev/null || true
#ip tuntap add dev "$TAP_DEV" mode tap
#sysctl -w net.ipv4.conf.${TAP_DEV}.proxy_arp=1 > /dev/null
#sysctl -w net.ipv6.conf.${TAP_DEV}.disable_ipv6=1 > /dev/null
#ip addr add "${TAP_IP}${MASK_SHORT}" dev "$TAP_DEV"
#ip link set dev "$TAP_DEV" up

KERNEL_BOOT_ARGS="${KERNEL_BOOT_ARGS} ip=${FC_IP}::${TAP_IP}:${MASK_LONG}::eth0:off"

# Start Firecracker API server
rm -f "$API_SOCKET"

./firecracker --api-sock "$API_SOCKET" --context '{"id": "fc-'${SB_ID}'", "jailed": false, "seccomp_level": 0, "start_time_us": 0, "start_time_cpu_us": 0}' &

sleep 0.015s

# Wait for API server to start
while [ ! -e "$API_SOCKET" ]; do
    echo "FC $SB_ID still not ready..."
    sleep 0.01s
done

curl_put '/logger' <<EOF
{
  "log_fifo": "$logfile",
  "metrics_fifo": "$metricsfile",
  "level": "Warning",
  "show_level": false,
  "show_log_origin": false
}
EOF

#curl_put '/machine-config' <<EOF
#{
#  "vcpu_count": 1,
#  "mem_size_mib": 128
#}
#EOF

curl_put '/boot-source' <<EOF
{
  "kernel_image_path": "$KERNEL",
  "boot_args": "$KERNEL_BOOT_ARGS"
}
EOF

curl_put '/drives/1' <<EOF
{
  "drive_id": "1",
  "path_on_host": "$RO_DRIVE",
  "is_root_device": true,
  "is_read_only": true
}
EOF
#
#curl_put '/drives/2' <<EOF
#{
#  "drive_id": "2",
#  "path_on_host": "$RW_DRIVE",
#  "is_root_device": false,
#  "is_read_only": false
#}
#EOF

curl_put '/network-interfaces/1' <<EOF
{
  "iface_id": "1",
  "guest_mac": "$FC_MAC",
  "host_dev_name": "$TAP_DEV"
}
EOF

curl_put '/actions' <<EOF
{
  "action_type": "InstanceStart"
}
EOF

