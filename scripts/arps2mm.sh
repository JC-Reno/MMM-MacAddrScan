#!/usr/bin/env bash
# arps2mm.sh -- A script to convert arp-scan output into MMM-MacAddressScan config file device items

IFACE=""
SCAN_ARGS="-l"  # Default to local network scan

parse_arp_line() {
    local line="$1"
    local ip mac vendor

    # Split first two columns; third var gets the full remaining vendor text.
    IFS=$' \t' read -r ip mac vendor <<< "$line"

    if [ -z "$ip" ] || [ -z "$mac" ]; then
        return 1
    fi

    printf '%s\t%s\t%s\n' "$ip" "$mac" "$vendor"
}

if [ "$1" = "--self-test" ]; then
    TEST_LINE="192.168.1.10    00:1f:54:a4:da:91    Apple, Inc."
    if PARSED=$(parse_arp_line "$TEST_LINE"); then
        TEST_VENDOR=$(printf '%s\n' "$PARSED" | awk -F'\t' '{print $3}')
        if [ "$TEST_VENDOR" = "Apple, Inc." ]; then
            echo "SELF-TEST PASS: vendor parsing preserved commas"
            exit 0
        fi
    fi
    echo "SELF-TEST FAIL: parser regressed"
    exit 1
fi

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
        if ! PARSED=$(parse_arp_line "$line"); then
            continue
        fi
        IFS=$'\t' read -r IP MAC VENDOR <<< "$PARSED"

        # Escape any quotes/backslashes so output remains valid JS object syntax.
        VENDOR_ESCAPED=${VENDOR//\\/\\\\}
        VENDOR_ESCAPED=${VENDOR_ESCAPED//\"/\\\"}
        echo "    { macAddress: \"${MAC}\", name: \"${VENDOR_ESCAPED}\", icon: \"mobile\" },    // ${IP}"
    fi
done <<< "$DARP"
echo "],"

exit 0
