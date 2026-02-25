# ========================================
# NAVEGACIÓN RÁPIDA
# ========================================

autoload -Uz compinit
compinit -i

# ========================================
# RUTAS PERSONALIZADAS (QUICK PATHS)
# ========================================

# Mapa de rutas rápidas
typeset -A quickpath_map
quickpath_map[core]="$HOME/core"
quickpath_map[dev]="$HOME/core/dev"
quickpath_map[learn]="$HOME/core/learn"
quickpath_map[uni]="$HOME/core/university"
quickpath_map[work]="$HOME/core/work"

# Función auxiliar para navegación con error amigable
function _go() {
    local base_path="$1"
    local relative_path="$2"
    # Remove leading slashes from relative path if present
    relative_path=${relative_path#/}
    
    local target="$base_path"
    if [[ -n "$relative_path" ]]; then
        target="$base_path/$relative_path"
    fi

    if [[ -d "$target" ]]; then
        cd "$target" || echo "Error entering $target"
    else
        echo ""
        echo "  📂 Ruta no encontrada: ${RED}$target${NC}"
        echo ""
    fi
}

# Funciones de navegación rápida
function core() { _go "${quickpath_map[core]}" "$1"; }
function dev() { _go "${quickpath_map[dev]}" "$1"; }
function learn() { _go "${quickpath_map[learn]}" "$1"; }
function uni() { _go "${quickpath_map[uni]}" "$1"; }
function work() { _go "${quickpath_map[work]}" "$1"; }

# Autocompletado para rutas rápidas
function _quickpath_complete() {
    local cmd="${words[1]}"
    local base_path="${quickpath_map[$cmd]}"
    
    if [[ ! -d "$base_path" ]]; then
        return 1
    fi

    # -/ limits completion to directories only
    # -W specifies the base directory to complete from
    _path_files -W "$base_path" -/
}

# Registrar autocompletado
compdef _quickpath_complete core dev learn uni work

# ========================================
# ATAJOS DE APLICACIONES Y UTILIDADES
# ========================================

# Abre VS Code aquí o en ruta especificada
function c() {
    local path="${1:-.}"
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH" code "$path" >/dev/null 2>&1
}

# Abre una nueva terminal en la ruta especificada
function dps() {
    local path="${1:-.}"
    local full_path
    full_path="$(cd "$path" 2>/dev/null && pwd || echo "$path")"
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH" xfce4-terminal --working-directory="$full_path" >/dev/null 2>&1 &|
}

# Abre gestor de archivos (thunar) en la ruta especificada
function e() {
    local path="${1:-.}"
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH" thunar "$path" >/dev/null 2>&1 &|
}

# Abre ranger y cambia al directorio al salir
function r() {
  local tmp
  tmp="$(mktemp -t ranger_cd.XXXXXX)" || return

  ranger --cmd="map Q chain shell echo %d > $tmp; quit" -- "${@:-.}" 2>/dev/null
  printf '\r\033[K'

  if [ -f "$tmp" ]; then
    local dir
    dir="$(cat -- "$tmp")"
    [ -n "$dir" ] && [ "$dir" != "$PWD" ] && cd -- "$dir"
  fi

  rm -f -- "$tmp"
}

# ========================================
# AUTOCOMPLETADO GENÉRICO
# ========================================

# Autocompletado para comandos que aceptan rutas (c, e, dps, r)
function _patharg_complete() {
    _files
}
compdef _patharg_complete c dps e r