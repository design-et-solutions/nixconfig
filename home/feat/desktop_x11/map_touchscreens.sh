#!/usr/bin/env bash
# Reliable touchscreen mapping script

TOUCHSCREEN_NAME="Weida Hi-Tech CoolTouch System"

# Find all device IDs matching the name
TOUCHSCREEN_IDS=$(xinput list | grep "$TOUCHSCREEN_NAME" | awk -F'id=' '{print $2}' | awk '{print $1}')

# First screen = HDMI-1
# Second screen = HDMI-2
OUTPUTS=("HDMI1" "HDMI2")

i=0
for ID in $TOUCHSCREEN_IDS; do
    OUTPUT=${OUTPUTS[$i]}
    if [ -n "$OUTPUT" ]; then
        echo "Mapping device ID $ID to output $OUTPUT"
        xinput map-to-output "$ID" "$OUTPUT"
    else
        echo "No output defined for device ID $ID, skipping..."
    fi
    i=$((i+1))
done
