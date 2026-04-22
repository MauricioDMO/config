#!/usr/bin/env bash

iface=$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$2=="ethernet" && $3=="connected"{print $1; exit}')
[ -z "$iface" ] && exit 0

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

if [ "${BLOCK_BUTTON:-}" = "1" ] && [ -n "$ip" ]; then
	copy_to_clipboard "$ip"
fi

printf '<span foreground="#e0af68">LAN</span> <span foreground="#c0caf5">%s</span>\n' "$ip"