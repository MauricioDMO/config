# ========================================
# NAVEGACIÓN RÁPIDA
# ========================================

# ========================================
# RUTAS PERSONALIZADAS (QUICK PATHS)
# ========================================

# Mapa de rutas rápidas
typeset -A quickpath_map
quickpath_map=(
    [core]="$HOME/core"
    [dev]="$HOME/core/dev"
    [learn]="$HOME/core/learn"
    [uni]="$HOME/core/university"
    [work]="$HOME/core/work"
)

# Función auxiliar para navegación con error amigable
_go() {
    local base_path="$1"
    local relative_path="${2#/}"
    local target="$base_path"
    [[ -n "$relative_path" ]] && target="$base_path/$relative_path"

    if [[ -d "$target" ]]; then
        cd "$target" || echo "Error entering $target"
    else
        printf "\n  📂 Ruta no encontrada: ${RED}%s${NC}\n\n" "$target"
    fi
}

# Funciones de navegación rápida
core()  { _go "${quickpath_map[core]}"  "$1"; }
dev()   { _go "${quickpath_map[dev]}"   "$1"; }
learn() { _go "${quickpath_map[learn]}" "$1"; }
uni()   { _go "${quickpath_map[uni]}"   "$1"; }
work()  { _go "${quickpath_map[work]}"  "$1"; }

# Autocompletado para rutas rápidas
_quickpath_complete() {
    local cmd="${words[1]}"
    local base_path="${quickpath_map[$cmd]}"
    [[ ! -d "$base_path" ]] && return 1
    _path_files -W "$base_path" -/
}
compdef _quickpath_complete core dev learn uni work

# ========================================
# ATAJOS DE APLICACIONES Y UTILIDADES
# ========================================

# Abre VS Code aquí o en ruta especificada
c() { code "${1:-.}" >/dev/null 2>&1; }

# Abre una nueva terminal en la ruta especificada
dps() {
    local full_path
    full_path="$(cd "${1:-.}" 2>/dev/null && pwd)" || full_path="${1:-.}"
    ghostty --working-directory="$full_path" >/dev/null 2>&1 &!
}

# Abre gestor de archivos (thunar) en la ruta especificada
e() { thunar "${1:-.}" >/dev/null 2>&1; }

# Abre ranger y cambia al directorio al salir
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

# ========================================
# AUTOCOMPLETADO GENÉRICO
# ========================================

_patharg_complete() { _files; }
compdef _patharg_complete c dps e r