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
	elif [[ "$path" == "~/"* ]]; then
		# En zsh, ${var#~/} no siempre trata ~ como literal; usamos reemplazo anclado.
		path="${path/#\~\//$HOME/}"
	fi

	print -r -- "${path:A}"
}

_wine_unix_to_windows_path() {
	local prefix_path="$1"
	local unix_path="$2"
	local drive_c="$prefix_path/drive_c"
	local rel

	if [[ "$unix_path" == "$drive_c"/* ]]; then
		rel="${unix_path#$drive_c/}"
		rel="${rel//\//\\}"
		print -r -- "C:\\$rel"
		return 0
	fi

	local abs="${unix_path:A}"
	abs="${abs#/}"
	abs="${abs//\//\\}"
	print -r -- "Z:\\$abs"
}

_wine_prompt_exe_path() {
	local prompt="$1"
	local default_value="$2"
	local prefix_path="$3"
	local answer="$default_value"

	if [[ -o interactive ]] && (( $+builtins[vared] )); then
		printf "${CYAN}%s${NC} [${WHITE}TAB autocompleta archivo${NC}]: " "$prompt" > /dev/tty
		if ! vared -c answer < /dev/tty > /dev/tty 2>/dev/null; then
			read -r answer < /dev/tty
		fi
	else
		if [[ -n "$default_value" ]]; then
			printf "${CYAN}%s${NC} [${WHITE}%s${NC}]: " "$prompt" "$default_value" > /dev/tty
		else
			printf "${CYAN}%s${NC}: " "$prompt" > /dev/tty
		fi
		read -r answer < /dev/tty
	fi

	[[ -z "$answer" ]] && answer="$default_value"

	if [[ -n "$answer" && -f "$answer" ]]; then
		answer="$(_wine_unix_to_windows_path "$prefix_path" "$answer")"
	fi

	print -r -- "$answer"
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

_removewine_complete() {
	local -a opts
	opts=(
		"--prefix:Ruta del WINEPREFIX a eliminar"
		"--yes:No pedir confirmaciones"
		"--help:Mostrar ayuda"
		"-h:Mostrar ayuda"
	)
	_describe -t removewine-options "removewine option" opts
}

_wine_prefix_from_init_file() {
	local init_file="$1"
	[[ -f "$init_file" ]] || return 1

	local line value
	line="$(command grep -E '^export WINEPREFIX=".*"$' "$init_file" 2>/dev/null | head -n 1)"
	[[ -n "$line" ]] || return 1

	value="${line#export WINEPREFIX=\"}"
	value="${value%\"}"
	[[ -n "$value" ]] || return 1

	print -r -- "$value"
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

	app_exe="$(_wine_prompt_exe_path "Ruta del .exe (TAB para autocompletar archivo .exe/.msi o pega ruta Wine)" "" "$prefix_path")"

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

removewine() {
	local prefix_input=""
	local prefix_path=""
	local assume_yes=0
	local remove_local_init=0
	local -a extra_args

	while (( $# > 0 )); do
		case "$1" in
			--prefix)
				if [[ -z "${2:-}" ]]; then
					print -r -- "${RED}Falta valor para --prefix.${NC}"
					return 1
				fi
				prefix_input="$2"
				shift 2
				;;
			--yes)
				assume_yes=1
				shift
				;;
			-h|--help)
				print -r -- "Uso: removewine [--prefix RUTA] [--yes]"
				print -r -- "Elimina un WINEPREFIX (incluyendo componentes instalados con winetricks)."
				print -r -- ""
				print -r -- "Opciones:"
				print -r -- "  --prefix RUTA   WINEPREFIX a eliminar."
				print -r -- "  --yes           No pedir confirmaciones."
				print -r -- ""
				print -r -- "Alias: rwine"
				return 0
				;;
			*)
				extra_args+=("$1")
				shift
				;;
		esac
	done

	if (( ${#extra_args[@]} > 0 )); then
		if [[ -z "$prefix_input" && ${#extra_args[@]} -eq 1 ]]; then
			prefix_input="${extra_args[1]}"
		else
			print -r -- "${YELLOW}Argumentos no reconocidos: ${extra_args[*]}${NC}"
			print -r -- "Usa: removewine --help"
			return 1
		fi
	fi

	if [[ -z "$prefix_input" ]]; then
		prefix_input="$(_wine_prefix_from_init_file "$PWD/init.sh" 2>/dev/null || true)"
		if [[ -z "$prefix_input" ]]; then
			prefix_input="$(_wine_prompt "WINEPREFIX a eliminar" "~/wineprefixes/miapp")"
		else
			if (( ! assume_yes )); then
				prefix_input="$(_wine_prompt "WINEPREFIX a eliminar" "$prefix_input")"
			fi
		fi
	fi

	prefix_path="$(_wine_abs_path "$prefix_input")"

	if [[ -z "$prefix_path" || "$prefix_path" == "/" ]]; then
		print -r -- "${RED}Ruta inválida para WINEPREFIX: $prefix_input${NC}"
		return 1
	fi

	if [[ ! -d "$prefix_path" ]]; then
		print -r -- "${YELLOW}No existe el prefix: $prefix_path${NC}"
		return 1
	fi

	if [[ "$prefix_path" == "$HOME" ]]; then
		print -r -- "${RED}Se bloqueó la operación para evitar borrar HOME completo.${NC}"
		return 1
	fi

	write_header "WINE PROFILE REMOVER" "$RED"
	write_item "Prefix" "$prefix_path"
	print -r -- ""

	if (( ! assume_yes )) && ! _wine_confirm "¿Eliminar este WINEPREFIX de forma permanente?" "n"; then
		print -r -- "${YELLOW}Operación cancelada.${NC}"
		return 0
	fi

	if ! rm -rf -- "$prefix_path"; then
		print -r -- "${RED}No se pudo eliminar: $prefix_path${NC}"
		return 1
	fi

	if [[ -f "$PWD/init.sh" ]]; then
		local current_init_prefix=""
		current_init_prefix="$(_wine_prefix_from_init_file "$PWD/init.sh" 2>/dev/null || true)"
		if [[ -n "$current_init_prefix" ]]; then
			current_init_prefix="$(_wine_abs_path "$current_init_prefix")"
			if [[ "$current_init_prefix" == "$prefix_path" ]]; then
				if (( assume_yes )); then
					remove_local_init=1
				elif _wine_confirm "init.sh en este directorio apunta a ese prefix. ¿Eliminar también init.sh?" "y"; then
					remove_local_init=1
				fi
			fi
		fi
	fi

	if (( remove_local_init )); then
		rm -f -- "$PWD/init.sh"
	fi

	print -r -- "${GREEN}WINEPREFIX eliminado correctamente.${NC}"
	if (( remove_local_init )); then
		print -r -- "${GREEN}También se eliminó init.sh local.${NC}"
	fi
}

alias rwine='removewine'

if (( $+functions[compdef] )); then
	compdef _winetricks_verbs_complete winetricks
	compdef _createwine_complete createwine cwine
	compdef _removewine_complete removewine rwine
fi
