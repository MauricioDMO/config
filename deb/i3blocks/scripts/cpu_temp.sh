#!/usr/bin/env bash

temp_path="${1:-/sys/class/thermal/thermal_zone5/temp}"

read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
total=$((user + nice + system + idle + iowait + irq + softirq + steal))
busy=$((user + nice + system + irq + softirq + steal))

cache="/tmp/i3blocks_cpu_usage.cache"

if [ -f "$cache" ]; then
    read -r prev_total prev_busy < "$cache"
    diff_total=$((total - prev_total))
    diff_busy=$((busy - prev_busy))

    if [ "$diff_total" -gt 0 ]; then
        usage=$((100 * diff_busy / diff_total))
    else
        usage=0
    fi
else
    usage=0
fi

echo "$total $busy" > "$cache"

if [ -r "$temp_path" ]; then
    temp_raw=$(cat "$temp_path")
    temp=$((temp_raw / 1000))
else
    temp=0
fi

if [ "$usage" -ge 80 ]; then
    cpu_color="#f7768e"
elif [ "$usage" -ge 50 ]; then
    cpu_color="#e0af68"
else
    cpu_color="#9ece6a"
fi

if [ "$temp" -ge 80 ]; then
    temp_color="#f7768e"
elif [ "$temp" -ge 65 ]; then
    temp_color="#e0af68"
else
    temp_color="#7dcfff"
fi

printf 'CPU <span foreground="%s">%s%%</span> <span foreground="%s">%s°C</span>\n' "$cpu_color" "$usage" "$temp_color" "$temp"