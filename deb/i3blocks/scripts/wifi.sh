#!/usr/bin/env bash

iface=$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$2=="wifi" && $3=="connected"{print $1; exit}')
[ -z "$iface" ] && exit 0

line=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | awk -F: '$1=="yes"{print; exit}')
ssid=$(printf '%s\n' "$line" | awk -F: '{print $2}')
signal=$(printf '%s\n' "$line" | awk -F: '{print $3}')
ip=$(ip -4 -o addr show dev "$iface" | awk '{split($4,a,"/"); print a[1]; exit}')

copy_to_clipboard() {
	local value=$1

	if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then
		printf '%s' "$value" | wl-copy
	elif [ -n "${DISPLAY:-}" ] && command -v xclip >/dev/null 2>&1; then
		printf '%s' "$value" | xclip -selection clipboard
	elif [ -n "${DISPLAY:-}" ] && command -v xsel >/dev/null 2>&1; then
		printf '%s' "$value" | xsel --clipboard --input
	elif command -v pbcopy >/dev/null 2>&1; then
		printf '%s' "$value" | pbcopy
	else
		notify-send -i dialog-error "No se copio" "No hay backend de portapapeles disponible" -t 2000
		return 1
	fi

	if [ "$?" -eq 0 ]; then
		notify-send -i dialog-information "Copiado" "IP copiado al portapapeles" -t 1500
	else
		notify-send -i dialog-error "No se copio" "Fallo al copiar IP" -t 2000
		return 1
	fi
}

if [ "${BLOCK_BUTTON:-}" = "1" ] && [ -n "$ip" ]; then
	copy_to_clipboard "$ip"
fi

printf 'WiFi <span foreground="#bb9af7">%s</span> <span foreground="#9ece6a">%s%%</span> <span foreground="#c0caf5">%s</span>\n' "$ssid" "$signal" "$ip"
