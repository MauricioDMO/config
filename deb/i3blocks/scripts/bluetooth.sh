#!/bin/bash

# Get all connected Bluetooth devices
connected_devices=$(bluetoothctl devices Connected 2>/dev/null)

if [ -z "$connected_devices" ]; then
    # No connected devices, output nothing
    exit 0
fi

# Get the first connected device
device_address=$(echo "$connected_devices" | head -1 | awk '{print $2}')

if [ -z "$device_address" ]; then
    exit 0
fi

# Get device info including battery percentage
device_info=$(bluetoothctl info "$device_address" 2>/dev/null)

# Extract device name
device_name=$(echo "$device_info" | grep "Name:" | sed 's/^[[:space:]]*Name: //')

# Extract battery percentage
battery=$(echo "$device_info" | grep "Battery Percentage:" | sed 's/.*: 0x//' | awk '{print "Battery"}')

# Extract the hex battery value and convert to decimal
battery_hex=$(echo "$device_info" | grep "Battery Percentage:" | sed 's/.*: 0x//' | awk '{print $1}')

if [ -z "$battery_hex" ]; then
    # No battery info, just show device name
    echo "$device_name"
else
    # Convert hex to decimal
    battery_decimal=$((16#$battery_hex))
    
    # Format output based on battery level
    if [ "$battery_decimal" -lt 25 ]; then
        echo "<span foreground='#ff0000'>🎧 $device_name $battery_decimal%</span>"
    elif [ "$battery_decimal" -lt 50 ]; then
        echo "<span foreground='#ffaa00'>🎧 $device_name $battery_decimal%</span>"
    else
        echo "🎧 $device_name $battery_decimal%"
    fi
fi
