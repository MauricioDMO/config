#!/usr/bin/env bash

ADB="/usr/bin/adb"

serial="$($ADB devices | awk 'NR>1 && $2=="device" {print $1; exit}')"

if [ -z "$serial" ]; then
    exit 0
fi

battery_info="$($ADB -s "$serial" shell dumpsys battery 2>/dev/null)"

level="$(printf '%s\n' "$battery_info" | awk -F': ' '/level/ {print $2; exit}' | tr -d '\r')"
status_code="$(printf '%s\n' "$battery_info" | awk -F': ' '/status/ {print $2; exit}' | tr -d '\r')"

if [ -z "$level" ]; then
    exit 0
fi

case "$status_code" in
    2) status="⚡" ;;
    3) status="" ;;
    4) status="⛔" ;;
    5) status="🔋" ;;
    *) status="" ;;
esac

if [ "$level" = "100" ]; then
    status=""
fi

echo "📱 ${level}% ${status}"