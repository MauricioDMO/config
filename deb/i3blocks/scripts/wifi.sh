#!/usr/bin/env bash

iface=$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$2=="wifi" && $3=="connected"{print $1; exit}')
[ -z "$iface" ] && exit 0

line=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | awk -F: '$1=="yes"{print; exit}')
ssid=$(printf '%s\n' "$line" | awk -F: '{print $2}')
signal=$(printf '%s\n' "$line" | awk -F: '{print $3}')
ip=$(ip -4 -o addr show dev "$iface" | awk '{split($4,a,"/"); print a[1]; exit}')

printf 'WiFi <span foreground="#bb9af7">%s</span> <span foreground="#9ece6a">%s%%</span> <span foreground="#c0caf5">%s</span>\n' "$ssid" "$signal" "$ip"