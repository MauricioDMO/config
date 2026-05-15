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

_wn_prefix_root() {
	print -r -- "$HOME/wineprefixes"
}

_wn_prefix_path() {
	local name="$(_wine_slugify "$1")"
	print -r -- "$(_wn_prefix_root)/$name"
}

_wn_profiles() {
	local root="$(_wn_prefix_root)"
	[[ -d "$root" ]] || return 0
	local dir
	for dir in "$root"/*(/N); do
		[[ -d "$dir/drive_c" || -f "$dir/system.reg" ]] && print -r -- "${dir:t}"
	done
}

_wn_init_value() {
	local init_file="$1"
	local key="$2"
	[[ -f "$init_file" ]] || return 1

	local line value
	line="$(command grep -E "^(export[[:space:]]+)?${key}=\".*\"$" "$init_file" 2>/dev/null | head -n 1)"
	[[ -n "$line" ]] || return 1

	value="${line#export }"
	value="${value#${key}=\"}"
	value="${value%\"}"
	[[ -n "$value" ]] || return 1

	print -r -- "$value"
}

_wn_host_app_path() {
	local init_file="$1"
	local prefix_path="$2"
	local app_exe="$3"
	local init_dir="${init_file:h}"

	case "$app_exe" in
		"") return 1 ;;
		[A-Za-z]:\\*|[A-Za-z]:/*) return 1 ;;
		/*) print -r -- "$app_exe" ;;
		drive_c/*) print -r -- "$prefix_path/$app_exe" ;;
		*) print -r -- "$init_dir/$app_exe" ;;
	esac
}

_wn_detect_app_type() {
	local init_file="$1"
	local prefix_path="$2"
	local app_exe="$3"
	local forced_type="$4"

	case "$forced_type" in
		generic|nwjs)
			print -r -- "$forced_type"
			return 0
			;;
	esac

	local host_exe app_dir exe_name
	host_exe="$(_wn_host_app_path "$init_file" "$prefix_path" "$app_exe" 2>/dev/null || true)"
	[[ -n "$host_exe" ]] || { print -r -- "generic"; return 0; }

	app_dir="${host_exe:h}"
	exe_name="${host_exe:t:l}"

	# NW.js/RPG Maker MV normalmente trae Chromium + carpeta www junto al Game.exe.
	if [[ -d "$app_dir/www" ]]; then
		if [[ -d "$app_dir/www/js" || -d "$app_dir/www/data" || -f "$app_dir/www/package.json" || "$exe_name" == "game.exe" ]]; then
			print -r -- "nwjs"
			return 0
		fi
	fi

	if [[ -f "$app_dir/package.json" ]]; then
		if [[ -f "$app_dir/nw.pak" || -f "$app_dir/icudtl.dat" || -d "$app_dir/locales" || "$exe_name" == "game.exe" ]]; then
			print -r -- "nwjs"
			return 0
		fi
	fi

	print -r -- "generic"
}

_wn_write_init() {
	local init_file="$1"
	local prefix_path="$2"
	local wine_arch="$3"
	local app_exe="$4"
	local forced_type="${5:-auto}"
	local app_type
	app_type="$(_wn_detect_app_type "$init_file" "$prefix_path" "$app_exe" "$forced_type")"

	local escaped_prefix escaped_arch escaped_exe escaped_type
	escaped_prefix="$(_wine_escape_for_dq "$prefix_path")"
	escaped_arch="$(_wine_escape_for_dq "$wine_arch")"
	escaped_exe="$(_wine_escape_for_dq "$app_exe")"
	escaped_type="$(_wine_escape_for_dq "$app_type")"

	cat > "$init_file" <<EOF
#!/usr/bin/env bash
set -euo pipefail

INIT_DIR="\$(cd -- "\$(dirname -- "\${BASH_SOURCE[0]}")" && pwd)"
cd "\$INIT_DIR"

export WINEPREFIX="$escaped_prefix"
export WINEARCH="$escaped_arch"

WN_APP_TYPE="$escaped_type"
APP_EXE="$escaped_exe"
APP_FLAGS=()

if [[ "\$WN_APP_TYPE" == "nwjs" ]]; then
  APP_FLAGS+=(
    --disable-gpu
    --disable-gpu-compositing
    --disable-accelerated-video-decode
  )
fi

if [[ -z "\$APP_EXE" ]]; then
  echo "APP_EXE no está definido. Regenera este launcher con: wn init <perfil> <exe>"
  exit 1
fi

case "\$APP_EXE" in
  [A-Za-z]:\\\\*|[A-Za-z]:/*)
    TARGET="\$APP_EXE"
    TARGET_IS_WINDOWS=1
    ;;
  /*)
    TARGET="\$APP_EXE"
    TARGET_IS_WINDOWS=0
    ;;
  drive_c/*)
    TARGET="\$WINEPREFIX/\$APP_EXE"
    TARGET_IS_WINDOWS=0
    ;;
  *)
    TARGET="\$APP_EXE"
    TARGET_IS_WINDOWS=0
    ;;
esac

if [[ "\$TARGET_IS_WINDOWS" -eq 0 && ! -f "\$TARGET" ]]; then
  echo "No se encontró \$APP_EXE en \$INIT_DIR."
  echo "Este launcher debe estar junto a la instalación completa de la app/juego, o APP_EXE debe apuntar a una ruta válida."
  exit 1
fi

exec wine "\$TARGET" "\${APP_FLAGS[@]}" "\$@"
EOF

	chmod +x "$init_file"
	print -r -- "$app_type"
}

_wn_info() {
	local init_input="${1:-./init.sh}"
	local init_file="$(_wine_abs_path "$init_input")"

	if [[ ! -f "$init_file" ]]; then
		print -r -- "${RED}No existe init.sh: $init_file${NC}"
		return 1
	fi

	local prefix_path wine_arch app_exe app_type init_dir target kind exists flags
	prefix_path="$(_wn_init_value "$init_file" WINEPREFIX 2>/dev/null || true)"
	wine_arch="$(_wn_init_value "$init_file" WINEARCH 2>/dev/null || true)"
	app_exe="$(_wn_init_value "$init_file" APP_EXE 2>/dev/null || true)"
	app_type="$(_wn_init_value "$init_file" WN_APP_TYPE 2>/dev/null || true)"
	init_dir="${init_file:h}"

	case "$app_exe" in
		"") kind="sin ejecutable"; target=""; exists="no" ;;
		[A-Za-z]:\\*|[A-Za-z]:/*) kind="ruta Windows/Wine"; target="$app_exe"; exists="no verificable desde Linux" ;;
		/*) kind="ruta Linux absoluta"; target="$app_exe"; [[ -f "$target" ]] && exists="sí" || exists="no" ;;
		drive_c/*) kind="ruta relativa dentro del prefix"; target="$prefix_path/$app_exe"; [[ -f "$target" ]] && exists="sí" || exists="no" ;;
		*) kind="ruta relativa al init.sh"; target="$init_dir/$app_exe"; [[ -f "$target" ]] && exists="sí" || exists="no" ;;
	esac

	case "$app_type" in
		nwjs) flags="--disable-gpu --disable-gpu-compositing --disable-accelerated-video-decode" ;;
		generic) flags="ninguna" ;;
		*) flags="desconocidas" ;;
	esac

	write_header "WINE INIT INFO" "$GREEN"
	write_item "Init" "$init_file"
	write_item "Prefix" "${prefix_path:-No definido}"
	write_item "Prefix existe" "$([[ -n "$prefix_path" && -d "$prefix_path" ]] && print -r -- "sí" || print -r -- "no")"
	write_item "WINEARCH" "${wine_arch:-No definido}"
	write_item "Tipo launcher" "${app_type:-No definido}"
	write_item "APP_EXE" "${app_exe:-No definido}"
	write_item "Tipo APP_EXE" "$kind"
	[[ -n "$target" ]] && write_item "Ejecuta" "$target"
	write_item "Exe existe" "$exists"
	write_item "Flags" "$flags"
	print -r -- ""
}

_wn_usage() {
	print -r -- "Uso: wn <acción> [perfil|init.sh] [args...]"
	print -r -- ""
	print -r -- "Acciones:"
	print -r -- "  list                         Lista perfiles en ~/wineprefixes"
	print -r -- "  create <nombre> [exe] [--type auto|generic|nwjs]"
	print -r -- "                               Crea prefix win64 e init.sh"
	print -r -- "  init <nombre> [exe] [--type auto|generic|nwjs]"
	print -r -- "                               Crea/regenera init.sh para un perfil"
	print -r -- "  info [init.sh]               Muestra prefix y ejecutable asociado"
	print -r -- "  run <nombre> <exe> [args...] Ejecuta un programa con ese perfil"
	print -r -- "  cfg <nombre>                 Abre winecfg"
	print -r -- "  tricks <nombre> <paquetes>   Ejecuta winetricks en el perfil"
	print -r -- "  boot <nombre>                Ejecuta wineboot -u"
	print -r -- "  remove <nombre>              Elimina el perfil"
	print -r -- ""
	print -r -- "Ejemplos:"
	print -r -- "  wn create elise ./Game.exe"
	print -r -- "  wn init elise ./Game.exe --type nwjs"
	print -r -- "  wn tricks elise vcrun2019 dxvk"
	print -r -- "  wn info ./init.sh"
	print -r -- ""
	print -r -- "Docs: deb/Docs/wn.md"
}

wn() {
	local action="${1:-help}"
	shift 2>/dev/null || true

	case "$action" in
		-h|--help|help)
			_wn_usage
			;;
		list)
			local root="$(_wn_prefix_root)"
			if [[ ! -d "$root" ]]; then
				print -r -- "${YELLOW}No existe $root.${NC}"
				return 0
			fi

			local -a profiles
			profiles=("${(@f)$(_wn_profiles)}")
			if (( ${#profiles[@]} == 0 )); then
				print -r -- "${YELLOW}No hay perfiles en $root.${NC}"
				return 0
			fi

			write_header "WINE PROFILES" "$GREEN"
			local profile path size size_line du_bin
			du_bin="${commands[du]:-/usr/bin/du}"
			for profile in "${profiles[@]}"; do
				path="$root/$profile"
				size_line="$($du_bin -sh "$path" 2>/dev/null)"
				size="${size_line%%$'\t'*}"
				size="${size%% *}"
				write_item "$profile" "${size:-?}  $path"
			done
			print -r -- ""
			;;
		create)
			local name="${1:-}"
			local app_exe=""
			local app_type="auto"
			local arg
			[[ $# -gt 0 ]] && shift
			if [[ $# -gt 0 && "${1:-}" != --* ]]; then
				app_exe="$1"
				shift
			fi
			while (( $# > 0 )); do
				arg="$1"
				case "$arg" in
					--type)
						if [[ -z "${2:-}" ]]; then
							print -r -- "${RED}Falta valor para --type.${NC}"
							return 1
						fi
						app_type="$2"
						shift 2
						;;
					--type=*)
						app_type="${arg#--type=}"
						shift
						;;
					*)
						print -r -- "${YELLOW}Argumento no reconocido: $arg${NC}"
						print -r -- "Uso: wn create <nombre> [exe] [--type auto|generic|nwjs]"
						return 1
						;;
				esac
			done
			case "$app_type" in
				auto|generic|nwjs) ;;
				*) print -r -- "${RED}Tipo inválido: $app_type${NC}"; return 1 ;;
			esac
			if [[ -z "$name" ]]; then
				print -r -- "${RED}Uso: wn create <nombre> [exe] [--type auto|generic|nwjs]${NC}"
				return 1
			fi
			if ! command -v wine >/dev/null 2>&1; then
				print -r -- "${RED}Wine no está instalado o no está en PATH.${NC}"
				return 1
			fi

			local prefix_path="$(_wn_prefix_path "$name")"
			local init_file="$PWD/init.sh"
			mkdir -p "$prefix_path"

			write_header "WINE CREATE" "$GREEN"
			write_item "Perfil" "${prefix_path:t}"
			write_item "Prefix" "$prefix_path"
			write_item "WINEARCH" "win64"

			if [[ ! -f "$prefix_path/system.reg" && ! -d "$prefix_path/drive_c" ]]; then
				print -r -- "${YELLOW}Inicializando prefix con wineboot...${NC}"
				if ! WINEPREFIX="$prefix_path" WINEARCH="win64" wineboot -u; then
					print -r -- "${RED}Falló wineboot. Revisa tu instalación de Wine.${NC}"
					return 1
				fi
			else
				print -r -- "${GRAY}El prefix ya existe; se conserva.${NC}"
			fi

			if [[ -f "$init_file" ]] && ! _wine_confirm "Ya existe init.sh aquí. ¿Sobrescribir?" "n"; then
				print -r -- "${YELLOW}No se sobrescribió init.sh.${NC}"
				return 0
			fi

			local detected_type
			detected_type="$(_wn_write_init "$init_file" "$prefix_path" "win64" "$app_exe" "$app_type")"
			write_item "Launcher" "$init_file"
			write_item "Tipo launcher" "$detected_type"
			[[ -n "$app_exe" ]] && write_item "APP_EXE" "$app_exe"
			print -r -- "${GREEN}Perfil listo.${NC}"
			;;
		init)
			local name="${1:-}"
			local app_exe=""
			local app_type="auto"
			local arg
			[[ $# -gt 0 ]] && shift
			if [[ $# -gt 0 && "${1:-}" != --* ]]; then
				app_exe="$1"
				shift
			fi
			while (( $# > 0 )); do
				arg="$1"
				case "$arg" in
					--type)
						if [[ -z "${2:-}" ]]; then
							print -r -- "${RED}Falta valor para --type.${NC}"
							return 1
						fi
						app_type="$2"
						shift 2
						;;
					--type=*)
						app_type="${arg#--type=}"
						shift
						;;
					*)
						print -r -- "${YELLOW}Argumento no reconocido: $arg${NC}"
						print -r -- "Uso: wn init <nombre> [exe] [--type auto|generic|nwjs]"
						return 1
						;;
				esac
			done
			case "$app_type" in
				auto|generic|nwjs) ;;
				*) print -r -- "${RED}Tipo inválido: $app_type${NC}"; return 1 ;;
			esac
			if [[ -z "$name" ]]; then
				print -r -- "${RED}Uso: wn init <nombre> [exe] [--type auto|generic|nwjs]${NC}"
				return 1
			fi

			local prefix_path="$(_wn_prefix_path "$name")"
			local init_file="$PWD/init.sh"
			if [[ ! -d "$prefix_path" ]]; then
				print -r -- "${RED}No existe el perfil: $name${NC}"
				print -r -- "Créalo con: wn create $name"
				return 1
			fi
			if [[ -f "$init_file" ]] && ! _wine_confirm "Ya existe init.sh aquí. ¿Sobrescribir?" "n"; then
				print -r -- "${YELLOW}No se sobrescribió init.sh.${NC}"
				return 0
			fi

			local detected_type
			detected_type="$(_wn_write_init "$init_file" "$prefix_path" "win64" "$app_exe" "$app_type")"
			write_item "Launcher" "$init_file"
			write_item "Prefix" "$prefix_path"
			write_item "Tipo launcher" "$detected_type"
			[[ -n "$app_exe" ]] && write_item "APP_EXE" "$app_exe"
			;;
		info)
			_wn_info "${1:-./init.sh}"
			;;
		run)
			local name="${1:-}"
			local app_exe="${2:-}"
			if [[ -z "$name" || -z "$app_exe" ]]; then
				print -r -- "${RED}Uso: wn run <nombre> <exe> [args...]${NC}"
				return 1
			fi
			shift 2
			local prefix_path="$(_wn_prefix_path "$name")"
			if [[ ! -d "$prefix_path" ]]; then
				print -r -- "${RED}No existe el perfil: $name${NC}"
				return 1
			fi
			WINEPREFIX="$prefix_path" WINEARCH="win64" wine "$app_exe" "$@"
			;;
		cfg|config)
			local name="${1:-}"
			if [[ -z "$name" ]]; then
				print -r -- "${RED}Uso: wn cfg <nombre>${NC}"
				return 1
			fi
			local prefix_path="$(_wn_prefix_path "$name")"
			[[ -d "$prefix_path" ]] || { print -r -- "${RED}No existe el perfil: $name${NC}"; return 1; }
			WINEPREFIX="$prefix_path" WINEARCH="win64" winecfg
			;;
		tricks)
			local name="${1:-}"
			if [[ -z "$name" || $# -lt 2 ]]; then
				print -r -- "${RED}Uso: wn tricks <nombre> <paquetes...>${NC}"
				return 1
			fi
			if ! command -v winetricks >/dev/null 2>&1; then
				print -r -- "${RED}winetricks no está instalado o no está en PATH.${NC}"
				return 1
			fi
			shift
			local prefix_path="$(_wn_prefix_path "$name")"
			[[ -d "$prefix_path" ]] || { print -r -- "${RED}No existe el perfil: $name${NC}"; return 1; }
			WINEPREFIX="$prefix_path" winetricks -q "$@"
			;;
		boot)
			local name="${1:-}"
			if [[ -z "$name" ]]; then
				print -r -- "${RED}Uso: wn boot <nombre>${NC}"
				return 1
			fi
			local prefix_path="$(_wn_prefix_path "$name")"
			mkdir -p "$prefix_path"
			WINEPREFIX="$prefix_path" WINEARCH="win64" wineboot -u
			;;
		remove|rm)
			local name="${1:-}"
			if [[ -z "$name" ]]; then
				print -r -- "${RED}Uso: wn remove <nombre>${NC}"
				return 1
			fi
			local prefix_path="$(_wn_prefix_path "$name")"
			if [[ ! -d "$prefix_path" ]]; then
				print -r -- "${YELLOW}No existe el perfil: $name${NC}"
				return 1
			fi
			write_header "WINE REMOVE" "$RED"
			write_item "Perfil" "$name"
			write_item "Prefix" "$prefix_path"
			if ! _wine_confirm "¿Eliminar este perfil de forma permanente?" "n"; then
				print -r -- "${YELLOW}Operación cancelada.${NC}"
				return 0
			fi
			rm -rf -- "$prefix_path"
			print -r -- "${GREEN}Perfil eliminado.${NC}"
			;;
		*)
			print -r -- "${YELLOW}Acción no válida: $action${NC}"
			_wn_usage
			return 1
			;;
	esac
}

_wn_completion() {
	local -a actions profiles
	actions=(list create init info run cfg tricks boot remove help)
	profiles=("${(@f)$(_wn_profiles)}")

	if (( CURRENT == 2 )); then
		compadd -a actions
		return
	fi

	case "${words[2]}" in
		init|run|cfg|tricks|boot|remove)
			if (( CURRENT == 3 )); then
				compadd -a profiles
			else
				_files
			fi
			;;
		info)
			_files
			;;
		*)
			_files
			;;
	esac
}

if (( $+functions[compdef] )); then
	compdef _winetricks_verbs_complete winetricks
	compdef _wn_completion wn
fi
