# ========================================
# UTILIDADES GENERALES (optimizado: builtins, sin subshells)
# ========================================

# --- Módulos builtin (evita tput/date) ---
zmodload zsh/terminfo 2>/dev/null || true
zmodload zsh/datetime  2>/dev/null || true

# --- Colors ($'...' => escapes reales, sin subcadenas \033) ---
typeset -g RED=$'\e[0;31m' GREEN=$'\e[0;32m' YELLOW=$'\e[0;33m' BLUE=$'\e[0;34m'
typeset -g CYAN=$'\e[0;36m' GRAY=$'\e[0;90m' WHITE=$'\e[0;37m' NC=$'\e[0m'

# Convierte bytes a un formato legible (pure awk, no python)
convert_size() {
    awk "BEGIN {
        b = $1+0
        if      (b >= 1099511627776) printf \"%.2f TB\n\", b/1099511627776
        else if (b >= 1073741824)    printf \"%.2f GB\n\", b/1073741824
        else if (b >= 1048576)       printf \"%.2f MB\n\", b/1048576
        else if (b >= 1024)          printf \"%.2f KB\n\", b/1024
        else                         printf \"%d B\n\", b
    }"
}

# Ancho terminal (sin tput; usa COLUMNS/terminfo)
get_term_width() {
    local w=${COLUMNS:-${terminfo[cols]:-80}}
    (( w < 20 )) && w=80
    print -r -- "$w"
}

# Repite carácter N veces (zsh padding builtin, sin while)
_repeat_char() {
    local c="$1" n="$2"
    print -r -- "${(l:${n}::${c}:)""}"
}

# Centra texto en la consola (pásale width para no recalcular)
write_centered() {
    local text="$1" color="${2:-$WHITE}" width="${3:-$(get_term_width)}"
    local pad=$(( (width - ${#text}) / 2 ))
    (( pad < 0 )) && pad=0
    print -r -- "${color}${(l:${pad}:: :)""}${text}${NC}"
}

# Escribe un encabezado estilizado
write_header() {
    local title="$1"
    local color="${2:-$GREEN}"
    local border_len=$(( ${#title} + 4 ))
    local border=$(_repeat_char '═' $border_len)
    print -r -- "${color}"
    print -r -- "  ╔${border}╗"
    print -r -- "  ║  ${title}  ║"
    print -r -- "  ╚${border}╝${NC}"
}

# Escribe una línea de item (Comando : Descripción)
write_item() {
    local label="$1" value="$2"
    local label_color="${3:-$GREEN}" value_color="${4:-$WHITE}"
    printf "  ${label_color}%-12s${NC} : ${value_color}%s${NC}\n" "$label" "$value"
}

# Escribe una línea divisoria
write_divider() {
    local color="${1:-$GRAY}"
    local width=$(get_term_width)
    (( width < 20 )) && width=60
    local line=$(_repeat_char '─' $((width - 4)))
    print -r -- "  ${color}${line}${NC}"
}
