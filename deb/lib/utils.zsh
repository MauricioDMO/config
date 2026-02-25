# ========================================
# UTILIDADES GENERALES
# ========================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'     # Dark Gray
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# Convierte bytes a un formato legible
function convert_size() {
    local bytes=$1
    if (( bytes >= 1099511627776 )); then
        printf "%.2f TB\n" $((bytes / 1099511627776.0))
    elif (( bytes >= 1073741824 )); then
        printf "%.2f GB\n" $((bytes / 1073741824.0))
    elif (( bytes >= 1048576 )); then
        printf "%.2f MB\n" $((bytes / 1048576.0))
    elif (( bytes >= 1024 )); then
        printf "%.2f KB\n" $((bytes / 1024.0))
    else
        echo "${bytes} B"
    fi
}

function get_term_width() {
    # If tput is not in path, try hardcoded paths or fallback
    if command -v tput >/dev/null 2>&1; then
        tput cols
    elif [[ -x /usr/bin/tput ]]; then
        /usr/bin/tput cols
    elif [[ -x /bin/tput ]]; then
        /bin/tput cols
    else
        echo 80
    fi
}

# Centra texto en la consola
function write_centered() {
    local text="$1"
    local color="${2:-$WHITE}" # Default white
    local width=$(get_term_width)
    local padding=$(( (width - ${#text}) / 2 ))
    
    # Handle color variable expansion if passed as name
    # But shell script is easier if we just pass the code directly
    
    if (( padding < 0 )); then padding=0; fi
    
    printf "${color}%*s%s${NC}\n" $padding "" "$text"
}

# Escribe un encabezado estilizado
function write_header() {
    local title="$1"
    local color="${2:-$GREEN}"
    local len=${#title}
    local border_len=$((len + 4))
    local border=$(printf '═%.0s' {1..$border_len}) # Create border string

    # Using printf for consistency
    printf "${color}\n  ╔${border}╗${NC}\n"
    printf "${color}  ║  ${title}  ║${NC}\n"
    printf "${color}  ╚${border}╝${NC}\n"
}

# Escribe una línea de item (Comando » Descripción)
function write_item() {
    local label="$1"
    local value="$2"
    local label_color="${3:-$GREEN}"
    local value_color="${4:-$WHITE}"
    
    # Simple formatting: Label (colored) : Value (colored)
    # The PS script aligns them. Let's try basic alignment.
    printf "  ${label_color}%-12s${NC} : ${value_color}%s${NC}\n" "$label" "$value"
}

# Escribe una línea divisoria
function write_divider() {
    local color="${1:-$GRAY}"
    local width=$(get_term_width)
    if (( width < 20 )); then width=60; fi
    local line=$(printf '─%.0s' {1..$((width - 4))})
    printf "  ${color}${line}${NC}\n"
}
