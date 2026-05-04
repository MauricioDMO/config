#!/usr/bin/env bash

profile_path="/sys/firmware/acpi/platform_profile"
turbo_path="/sys/devices/system/cpu/intel_pstate/no_turbo"
max_perf_path="/sys/devices/system/cpu/intel_pstate/max_perf_pct"

profile="unknown"
no_turbo="1"
max_perf="?"

if [ -r "$profile_path" ]; then
    read -r profile < "$profile_path"
fi

if [ -r "$turbo_path" ]; then
    read -r no_turbo < "$turbo_path"
fi

if [ -r "$max_perf_path" ]; then
    read -r max_perf < "$max_perf_path"
fi

case "$profile" in
    performance) label="P"; color="#9ece6a" ;;
    balanced) label="B"; color="#e0af68" ;;
    cool) label="C"; color="#7dcfff" ;;
    quiet) label="Q"; color="#bb9af7" ;;
    *) label="?"; color="#f7768e" ;;
esac

turbo=""
if [ "$no_turbo" = "0" ]; then
    turbo="t"
fi

printf '<span foreground="%s">%s%s%s</span>\n' "$color" "$max_perf" "$label" "$turbo"
