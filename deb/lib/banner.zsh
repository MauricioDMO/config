# ========================================
# BANNER DE INICIO
# ========================================

show_name() {
    local line1='░█▄█░█▀█░█░█░█▀▄░▀█▀░█▀▀░▀█▀░█▀█░█▀▄░█▄█░█▀█'
    local line2='░█░█░█▀█░█░█░█▀▄░░█░░█░░░░█░░█░█░█░█░█░█░█░█'
    local line3='░▀░▀░▀░▀░▀▀▀░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀▀░░▀░▀░▀▀▀'

    echo ""
    write_centered "$line1" "$GREEN"
    write_centered "$line2" "$GREEN"
    write_centered "$line3" "$GREEN"

    local current_date
    current_date=$(date "+%A, %d %B %Y %H:%M")

    local os_info=""
    if [ -f /etc/os-release ]; then
        os_info=$(. /etc/os-release && echo "$PRETTY_NAME")
    else
        os_info=$(uname -s)
    fi

    local separator="────────────────────────────────────────────────"

    write_centered "$separator" "$WHITE"
    write_centered "  $current_date  " "$WHITE"
    write_centered "OS: $os_info" "$WHITE"
    write_centered "$separator" "$WHITE"
    echo ""
}

# Show banner only if shell is interactive
[[ -o interactive ]] && show_name
