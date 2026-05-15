#!/usr/bin/env bash

ADB="/usr/bin/adb"

devices="$($ADB devices 2>/dev/null)"
serial="$(printf '%s\n' "$devices" | awk 'NR>1 && $2=="device" {print $1; exit}')"

if [ -z "$serial" ]; then
    state="$(printf '%s\n' "$devices" | awk 'NR>1 && $2!="" {print $2; exit}')"
    case "$state" in
        unauthorized) echo "📱 authorize USB" ;;
        offline) echo "📱 offline" ;;
        recovery|sideload|rescue) echo "📱 $state" ;;
    esac
    exit 0
fi

battery_info="$(timeout 3 "$ADB" -s "$serial" shell dumpsys battery 2>/dev/null)"

level="$(printf '%s\n' "$battery_info" | awk -F': ' '$1 ~ /^[[:space:]]*level$/ {print $2; exit}' | tr -d '\r')"
status_code="$(printf '%s\n' "$battery_info" | awk -F': ' '$1 ~ /^[[:space:]]*status$/ {print $2; exit}' | tr -d '\r')"

if [ -z "$level" ]; then
    echo "📱 adb error"
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
