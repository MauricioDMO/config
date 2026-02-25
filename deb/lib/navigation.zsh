# ========================================
# NAVEGACIÓN RÁPIDA
# ========================================

autoload -Uz compinit
compinit -i

# Mapa de rutas rápidas
typeset -A quickpath_map
quickpath_map[core]="$HOME/core"
quickpath_map[dev]="$HOME/core/dev"
quickpath_map[uni]="$HOME/core/university"
quickpath_map[work]="$HOME/core/work"
quickpath_map[learn]="$HOME/core/learn"

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

# Functions for quick navigation
# Usage: core [subpath]
function core() { _go "${quickpath_map[core]}" "$1"; }
function dev() { _go "${quickpath_map[dev]}" "$1"; }
function uni() { _go "${quickpath_map[uni]}" "$1"; }
function work() { _go "${quickpath_map[work]}" "$1"; }
function learn() { _go "${quickpath_map[learn]}" "$1"; }

# ========================================
# AUTOCOMPLETADO
# ========================================

function _quickpath_complete() {
    # Get the command name (function being called)
    local cmd="${words[1]}"
    
    # Get the corresponding base path from the map
    local base_path="${quickpath_map[$cmd]}"
    
    # Check if base path exists and is a directory
    if [[ ! -d "$base_path" ]]; then
        return 1
    fi

    # ZSH completion logic
    # -/ limits completion to directories only (since these are navigation commands)
    # -W specifies the base directory to complete from, making relative paths work naturally
    _path_files -W "$base_path" -/
}

# Register completion function for all quickpath commands
compdef _quickpath_complete core dev uni work learn

r() {
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

# Abre gestor de archivos en la ruta especificada
function e() {
    local path="${1:-.}"
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH" thunar "$path" >/dev/null 2>&1 &|
}

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

function x() {
    exit
}

# Autocompletado para c, e y dps (archivos y directorios)
function _patharg_complete() {
    _files
}
compdef _patharg_complete c e dps