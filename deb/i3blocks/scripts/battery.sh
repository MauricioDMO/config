#!/usr/bin/env bash

bat=""
for b in /sys/class/power_supply/BAT*; do
    [ -e "$b" ] && bat="$b" && break
done

[ -z "$bat" ] && exit 0

capacity=$(cat "$bat/capacity" 2>/dev/null)
status=$(cat "$bat/status" 2>/dev/null)

if [ "$capacity" = "100" ]; then
    prefix="BAT "
else
    case "$status" in
        Charging) prefix="⚡" ;;
        Full) prefix="BAT " ;;
        *) prefix="BAT " ;;
    esac
fi

time_str=""
if command -v upower >/dev/null 2>&1; then
    dev=$(upower -e | grep -m1 BAT)
    if [ -n "$dev" ]; then
        if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
            time_str=$(upower -i "$dev" | awk -F: '/time to full/ {gsub(/^[ \t]+/, "", $2); print $2; exit}')
        else
            time_str=$(upower -i "$dev" | awk -F: '/time to empty/ {gsub(/^[ \t]+/, "", $2); print $2; exit}')
        fi
    fi
fi

if [ -n "$time_str" ]; then
    printf '%s%s%% %s\n' "$prefix" "$capacity" "$time_str"
else
    printf '%s%s%%\n' "$prefix" "$capacity"
fi