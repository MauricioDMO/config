# ========================================
# BANNER DE INICIO
# ========================================

function show_name() {
    # ASCII Art array
    local line1='░█▄█░█▀█░█░█░█▀▄░▀█▀░█▀▀░▀█▀░█▀█░█▀▄░█▄█░█▀█'
    local line2='░█░█░█▀█░█░█░█▀▄░░█░░█░░░░█░░█░█░█░█░█░█░█░█'
    local line3='░▀░▀░▀░▀░▀▀▀░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀▀░░▀░▀░▀▀▀'
    
    echo ""
    write_centered "$line1" "$GREEN"
    write_centered "$line2" "$GREEN"
    write_centered "$line3" "$GREEN"
    
    local current_date=$(date "+%A, %d %B %Y %H:%M")
    # Get OS info properly for Linux
    local os_info=""
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        os_info=$PRETTY_NAME
    else
        os_info=$(uname -s)
    fi

    local separator="────────────────────────────────────────────────"
    
    write_centered "$separator" "$GRAY"
    write_centered "  $current_date  " "$GRAY"
    write_centered "OS: $os_info" "$GRAY"
    write_centered "$separator" "$GRAY"
    echo ""
}

# Show banner only if shell is interactive
if [[ -o interactive ]]; then
    show_name
fi
