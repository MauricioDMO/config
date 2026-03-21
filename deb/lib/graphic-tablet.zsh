# ========================================
# TABLETA GRAFICA / PANTALLAS
# ========================================

# Uso:
#   tablet_setup [OUTPUT]
# Ejemplo:
#   tablet_setup HDMI-1
tablet_setup() {
	local output="${1:-HDMI-1}"
	local stylus_device="LetSketch LetSketch stylus"
	local eraser_device="LetSketch LetSketch eraser"

	if ! command -v xsetwacom >/dev/null 2>&1; then
		echo "xsetwacom no esta disponible. Instala xserver-xorg-input-wacom."
		return 1
	fi

	if ! command -v xrandr >/dev/null 2>&1; then
		echo "xrandr no esta disponible."
		return 1
	fi

	if ! xsetwacom --list devices | grep -Fq "$stylus_device"; then
		echo "No se encontro el dispositivo: $stylus_device"
		return 1
	fi

	if ! xsetwacom --list devices | grep -Fq "$eraser_device"; then
		echo "No se encontro el dispositivo: $eraser_device"
		return 1
	fi

	if ! _tablet_map_output "$output"; then
		return 1
	fi

	# Sensacion mas cruda
	xsetwacom set "$stylus_device" RawSample 1
	xsetwacom set "$eraser_device" RawSample 1
	xsetwacom set "$stylus_device" Suppress 0

	# Presion lineal
	xsetwacom set "$stylus_device" PressureCurve 0 0 100 100
	xsetwacom set "$eraser_device" PressureCurve 0 0 100 100

	echo "Setup de tableta aplicado en $output."
}


_tablet_map_output() {
	local target_output="$1"
	local stylus_device="LetSketch LetSketch stylus"
	local eraser_device="LetSketch LetSketch eraser"

	if [[ "$target_output" != "desktop" ]]; then
		if ! xrandr --query | awk '/ connected/{print $1}' | grep -Fxq "$target_output"; then
			echo "La salida '$target_output' no esta conectada."
			echo "Salidas disponibles:"
			xrandr --query | awk '/ connected/{print " - " $1}'
			echo " - desktop"
			return 1
		fi
	fi

	xsetwacom set "$stylus_device" MapToOutput "$target_output" || return 1
	xsetwacom set "$eraser_device" MapToOutput "$target_output" || return 1

	if [[ "$target_output" == "desktop" ]]; then
		echo "Tableta mapeada a desktop (todas las pantallas)."
	else
		echo "Tableta mapeada a $target_output."
	fi

	return 0
}

# Uso:
#   tablet_focus [OUTPUT]
# Ejemplos:
#   tablet_focus
#   tablet_focus HDMI-1
tablet_focus() {
	if ! command -v xrandr >/dev/null 2>&1; then
		echo "xrandr no esta disponible."
		return 1
	fi

	if ! command -v xsetwacom >/dev/null 2>&1; then
		echo "xsetwacom no esta disponible. Instala xserver-xorg-input-wacom."
		return 1
	fi

	local connected_outputs
	connected_outputs=("${(@f)$(xrandr --query | awk '/ connected/{print $1}')}")

	if (( ${#connected_outputs[@]} == 0 )); then
		echo "No se detectaron pantallas conectadas."
		return 1
	fi

	local primary_output
	primary_output="$(xrandr --query | awk '/ connected primary/{print $1; exit}')"

	local external_output
	external_output="$(xrandr --query | awk '/ connected/{print $1}' | grep -Ev '^eDP|^LVDS' | head -n1)"

	local recommended_output
	recommended_output="${1:-$external_output}"

	if [[ -z "$recommended_output" ]]; then
		recommended_output="${primary_output:-${connected_outputs[1]}}"
	fi

	if ! printf '%s\n' "${connected_outputs[@]}" | grep -Fxq "$recommended_output"; then
		echo "La salida '$recommended_output' no esta conectada."
		echo "Salidas disponibles:"
		printf ' - %s\n' "${connected_outputs[@]}"
		return 1
	fi

	echo "Pantallas conectadas:"
	local i
	echo " 0) desktop (todas las pantallas)"
	for ((i = 1; i <= ${#connected_outputs[@]}; i++)); do
		printf ' %d) %s\n' "$i" "${connected_outputs[$i]}"
	done
	echo ""
	echo "Recomendacion de mapeo: $recommended_output"

	local recommended_index=0
	for ((i = 1; i <= ${#connected_outputs[@]}; i++)); do
		if [[ "${connected_outputs[$i]}" == "$recommended_output" ]]; then
			recommended_index="$i"
			break
		fi
	done

	local choice
	read "choice?Destino [numero, Enter/y=$recommended_index, n=cancelar]: "

	local target_output
	case "$choice" in
		""|[Yy])
			target_output="$recommended_output"
			;;
		[Nn])
			echo "Mapeo sin cambios."
			return 0
			;;
		0)
			target_output="desktop"
			;;
		*)
			if [[ "$choice" != <-> ]]; then
				echo "Entrada invalida: $choice"
				echo "Debes usar un numero de la lista."
				return 1
			fi

			if (( choice < 1 || choice > ${#connected_outputs[@]} )); then
				echo "Numero fuera de rango: $choice"
				echo "Rango valido: 0-${#connected_outputs[@]}"
				return 1
			fi

			target_output="${connected_outputs[$choice]}"
			;;
	esac

	if [[ "$target_output" == "$recommended_output" ]]; then
		echo "Aplicando mapeo recomendado: $target_output"
	elif [[ "$target_output" == "desktop" ]]; then
		echo "Aplicando mapeo global: desktop"
	else
		echo "Aplicando mapeo elegido: $target_output"
	fi

	_tablet_map_output "$target_output"
	if [[ $? -ne 0 ]]; then
		echo "Mapeo sin cambios."
		return 1
	fi

	return 0
}
