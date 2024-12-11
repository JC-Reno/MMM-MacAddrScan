#!/usr/bin/env bash
# arps2mm.sh -- A script to convert arp-scan output into MMM-MacAddressScan config file device items

IFACE=""
SCAN_ARGS="-l"  # Default to local network scan

# Handle interface argument
if [ "$1" == "-I" ] && [ "$2" ]; then
    IFACE="$2"
    SCAN_ARGS="-l -I ${IFACE}"
fi

# Run arp-scan and capture output, excluding header and footer lines
DARP=$(sudo arp-scan ${SCAN_ARGS} | tail -n +3 | head -n -3 | sort)

echo "devices: ["
while IFS= read -r line; do
    if [ -n "$line" ]; then
        IP=$(echo "$line" | awk '{print $1}')
        MAC=$(echo "$line" | awk '{print $2}')
        VENDOR=$(echo "$line" | cut -d' ' -f3-)
        echo "    { macAddress: \"${MAC}\", name: \"${VENDOR}\", icon: \"mobile\" },    // ${IP}"
    fi
done <<< "$DARP"
echo "],"

exit 0
