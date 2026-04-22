#!/usr/bin/env bash

iface=$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$2=="wifi" && $3=="connected"{print $1; exit}')
[ -z "$iface" ] && exit 0

line=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | awk -F: '$1=="yes"{print; exit}')
ssid=$(printf '%s\n' "$line" | awk -F: '{print $2}')
signal=$(printf '%s\n' "$line" | awk -F: '{print $3}')
ip=$(ip -4 -o addr show dev "$iface" | awk '{split($4,a,"/"); print a[1]; exit}')

copy_to_clipboard() {
	if command -v wl-copy >/dev/null 2>&1; then
		printf '%s' "$1" | wl-copy
	elif command -v xclip >/dev/null 2>&1; then
		printf '%s' "$1" | xclip -selection clipboard
	elif command -v xsel >/dev/null 2>&1; then
		printf '%s' "$1" | xsel --clipboard --input
	elif command -v pbcopy >/dev/null 2>&1; then
		printf '%s' "$1" | pbcopy
	else
		return 1
	fi
	notify-send -i dialog-information "Copiado" "IP copiado al portapapeles" -t 1500
}

case "${BLOCK_BUTTON:-}" in
	1)
		[ -n "$ip" ] && copy_to_clipboard "$ip"
		;;
	2)
		[ -n "$ssid" ] && copy_to_clipboard "$ssid"
		;;
esac

printf 'WiFi <span foreground="#bb9af7">%s</span> <span foreground="#9ece6a">%s%%</span> <span foreground="#c0caf5">%s</span>\n' "$ssid" "$signal" "$ip"