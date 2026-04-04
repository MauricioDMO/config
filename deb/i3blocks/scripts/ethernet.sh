#!/usr/bin/env bash

iface=$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$2=="ethernet" && $3=="connected"{print $1; exit}')
[ -z "$iface" ] && exit 0

ip=$(ip -4 -o addr show dev "$iface" | awk '{split($4,a,"/"); print a[1]; exit}')
printf '<span foreground="#e0af68">LAN</span> <span foreground="#c0caf5">%s</span>\n' "$ip"