# ========================================
# WINE HELPERS
# ========================================

_wine_prompt() {
	local prompt="$1"
	local default="$2"
	local answer=""

	if [[ -n "$default" ]]; then
		printf "${CYAN}%s${NC} [${WHITE}%s${NC}]: " "$prompt" "$default" > /dev/tty
	else
		printf "${CYAN}%s${NC}: " "$prompt" > /dev/tty
	fi

	read -r answer < /dev/tty
	[[ -z "$answer" ]] && answer="$default"
	print -r -- "$answer"
}

_wine_confirm() {
	local prompt="$1"
	local default="${2:-y}"
	local answer=""

	if [[ "$default" == "y" ]]; then
		printf "${CYAN}%s${NC} [${WHITE}Y/n${NC}]: " "$prompt" > /dev/tty
	else
		printf "${CYAN}%s${NC} [${WHITE}y/N${NC}]: " "$prompt" > /dev/tty
	fi

	read -r answer < /dev/tty
	answer="${answer:l}"
	[[ -z "$answer" ]] && answer="$default"

	[[ "$answer" == "y" || "$answer" == "yes" || "$answer" == "s" || "$answer" == "si" ]]
}

_wine_slugify() {
	local value="${1:l}"
	value="${value// /-}"
	value="${value//[^a-z0-9._-]/}"
	[[ -z "$value" ]] && value="app"
	print -r -- "$value"
}

_wine_escape_for_dq() {
	local value="$1"
	value="${value//\\/\\\\}"
	value="${value//\"/\\\"}"
	print -r -- "$value"
}

_wine_abs_path() {
	local input="$1"
	local path="$input"

	# Wine requiere WINEPREFIX absoluto. Expandimos ~ y convertimos relativo -> absoluto.
	if [[ "$path" == "~" ]]; then
		path="$HOME"
	elif [[ "$path" == ~/* ]]; then
		path="$HOME/${path#~/}"
	fi

	print -r -- "${path:A}"
}

_wine_collect_winetricks_verbs() {
	local -a verbs
	local line verb

	if command -v winetricks >/dev/null 2>&1; then
		while IFS= read -r line; do
			[[ -z "$line" ]] && continue
			[[ "$line" == \\#* ]] && continue
			verb="${line%%[[:space:]]*}"
			[[ -n "$verb" ]] && verbs+=("$verb")
		done < <(winetricks list-all 2>/dev/null)
	fi

	# Fallback: tomar nombres de carpetas comunes de cache/local de winetricks.
	local base
	for base in "$HOME/.cache/winetricks" "$HOME/.local/share/winetricks" "/usr/share/winetricks" "/usr/lib/winetricks"; do
		[[ -d "$base" ]] || continue
		local dir
		for dir in "$base"/*(/N); do
			verbs+=("${dir:t}")
		done
	done

	typeset -U verbs
	print -rl -- $verbs
}

_winetricks_verbs_complete() {
	local -a verbs
	verbs=("${(@f)$(_wine_collect_winetricks_verbs)}")
	(( ${#verbs[@]} == 0 )) && return 1
	_describe -t winetricks-verbs "winetricks verb" verbs
}

_createwine_complete() {
	local -a opts
	opts=(
		"--init-only:Solo generar init.sh (sin setup)"
		"--help:Mostrar ayuda"
		"-h:Mostrar ayuda"
	)
	_describe -t createwine-options "createwine option" opts
}

createwine() {
	local init_only=0

	case "${1:-}" in
		--init-only) init_only=1 ;;
		""|-h|--help) ;;
		*)
			print -r -- "${YELLOW}Opción no reconocida: ${1}${NC}"
			print -r -- "Usa: createwine --help"
			return 1
			;;
	esac

	if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
		print -r -- "Uso: createwine [--init-only]"
		print -r -- "Asistente interactivo para crear un perfil de Wine y generar init.sh en el directorio actual."
		print -r -- ""
		print -r -- "Opciones:"
		print -r -- "  --init-only   Solo genera init.sh (omite wineboot/winecfg/winetricks)."
		print -r -- ""
		print -r -- "Alias: cwine"
		return 0
	fi

	if (( ! init_only )) && ! command -v wine >/dev/null 2>&1; then
		print -r -- "${RED}Wine no está instalado o no está en PATH.${NC}"
		print -r -- "Instálalo primero y vuelve a intentar."
		return 1
	fi

	write_header "WINE PROFILE CREATOR" "$GREEN"

	local app_name slug prefix_input prefix_path arch_choice wine_arch
	local run_winecfg win_version winetricks_packages app_exe
	local init_file overwrite

	app_name="$(_wine_prompt "Nombre de la app/perfil" "miapp")"
	slug="$(_wine_slugify "$app_name")"

	prefix_input="$(_wine_prompt "WINEPREFIX" "~/wineprefixes/$slug")"
	prefix_path="$(_wine_abs_path "$prefix_input")"

	arch_choice="$(_wine_prompt "Arquitectura (64/32)" "64")"
	case "$arch_choice" in
		32|win32) wine_arch="win32" ;;
		*) wine_arch="win64" ;;
	esac

	print -r -- ""
	write_item "App" "$app_name"
	write_item "Prefix" "$prefix_path"
	write_item "WINEARCH" "$wine_arch"
	print -r -- ""

	if (( init_only )); then
		print -r -- "${GRAY}Modo --init-only: se omite inicialización del prefix.${NC}"
	elif _wine_confirm "¿Crear e inicializar el prefix ahora?" "y"; then
		mkdir -p "$prefix_path"

		print -r -- "${YELLOW}Inicializando prefix con wineboot...${NC}"
		if ! WINEPREFIX="$prefix_path" WINEARCH="$wine_arch" wineboot -u; then
			print -r -- "${RED}Falló wineboot. Revisa tu instalación de Wine.${NC}"
			return 1
		fi

		if _wine_confirm "¿Abrir winecfg para ajustes manuales ahora?" "y"; then
			WINEPREFIX="$prefix_path" WINEARCH="$wine_arch" winecfg
		fi

		if command -v winetricks >/dev/null 2>&1; then
			win_version="$(_wine_prompt "Versión de Windows para winetricks (ej: win10, vacío para omitir)" "")"
			if [[ -n "$win_version" ]]; then
				print -r -- "${YELLOW}Aplicando versión ${win_version}...${NC}"
				WINEPREFIX="$prefix_path" winetricks -q "$win_version"
			fi

			winetricks_packages="$(_wine_prompt "Paquetes winetricks (separados por espacios, vacío para omitir)" "")"
			if [[ -n "$winetricks_packages" ]]; then
				print -r -- "${YELLOW}Instalando paquetes winetricks...${NC}"
				WINEPREFIX="$prefix_path" winetricks -q ${(z)winetricks_packages}
			fi
		else
			print -r -- "${GRAY}winetricks no está instalado. Se omite configuración adicional.${NC}"
		fi
	fi

	app_exe="$(_wine_prompt "Ruta del .exe dentro de Wine (ej: C:\\Program Files\\MiApp\\miapp.exe)" "")"

	init_file="$PWD/init.sh"
	if [[ -f "$init_file" ]]; then
		if ! _wine_confirm "Ya existe init.sh en este directorio. ¿Sobrescribir?" "n"; then
			print -r -- "${YELLOW}No se sobrescribió init.sh.${NC}"
			print -r -- "Puedes ejecutar manualmente con:"
			print -r -- "WINEPREFIX=\"$prefix_path\" WINEARCH=\"$wine_arch\" wine \"<tu_app.exe>\""
			return 0
		fi
	fi

	local escaped_prefix escaped_arch escaped_exe
	escaped_prefix="$(_wine_escape_for_dq "$prefix_path")"
	escaped_arch="$(_wine_escape_for_dq "$wine_arch")"
	escaped_exe="$(_wine_escape_for_dq "$app_exe")"

	cat > "$init_file" <<EOF
#!/usr/bin/env bash
set -euo pipefail

export WINEPREFIX="$escaped_prefix"
export WINEARCH="$escaped_arch"

APP_EXE="$escaped_exe"

if [[ -z "\$APP_EXE" ]]; then
  echo "Define APP_EXE dentro de init.sh o vuelve a ejecutar createwine."
  exit 1
fi

exec wine "\$APP_EXE" "\$@"
EOF

	chmod +x "$init_file"

	print -r -- ""
	print -r -- "${GREEN}Perfil creado correctamente.${NC}"
	write_item "Prefix" "$prefix_path"
	write_item "Launcher" "$init_file"
	print -r -- ""
	print -r -- "Uso: ./init.sh"
}

alias cwine='createwine'

if (( $+functions[compdef] )); then
	compdef _winetricks_verbs_complete winetricks
	compdef _createwine_complete createwine cwine
fi
