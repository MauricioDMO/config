# ========================================
# BANNER DE INICIO
# ========================================

show_name() {
    echo ""
    local font_dir="$HOME/.config/config/deb/fonts/figlet"
    local -a fonts
    fonts=("$font_dir"/*.flf(N))

    local selected_font="$font_dir/roman.flf"
    if (( ${#fonts[@]} > 0 )); then
        selected_font="${fonts[RANDOM % ${#fonts[@]} + 1]}"
    fi

    figlet -t -c -f "$selected_font" "MauricioDMO" | lolcat -f

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
