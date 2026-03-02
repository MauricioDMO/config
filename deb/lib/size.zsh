# ========================================
# TAMAÑO DE DIRECTORIOS
# ========================================

size() {
    local path="${1:-.}"

    if [[ ! -e "$path" ]]; then
        echo "Error: Path not found: $path"
        return 1
    fi

    # Resolve absolute path
    local full_path
    if command -v readlink >/dev/null 2>&1; then
        full_path=$(readlink -f "$path")
    elif [[ -d "$path" ]]; then
        full_path=$(cd "$path" && pwd)
    else
        full_path=$(cd "$(dirname "$path")" && pwd)/$(basename "$path")
    fi

    local is_file=false
    [[ -f "$full_path" ]] && is_file=true

    local total_bytes=0
    local file_count=0
    local dir_count=0
    local top_files=""

    if $is_file; then
        total_bytes=$(stat -c%s "$full_path" 2>/dev/null || stat -f%z "$full_path" 2>/dev/null || ls -l "$full_path" | awk '{print $5}')
        file_count=1
        dir_count=0
    else
        # Total size in bytes
        if du --version >/dev/null 2>&1; then
            total_bytes=$(du -sb "$full_path" | cut -f1)
        else
            total_bytes=$(( $(du -sk "$full_path" | awk '{print $1}') * 1024 ))
        fi

        file_count=$(find "$full_path" -type f 2>/dev/null | wc -l)
        file_count="${file_count// /}"
        dir_count=$(find "$full_path" -type d 2>/dev/null | wc -l)
        dir_count="${dir_count// /}"

        # Top 5 largest files (GNU find with -printf, fallback to du)
        if find "$full_path" -maxdepth 0 -printf "" 2>/dev/null; then
            top_files=$(find "$full_path" -type f -printf "%s %p\n" 2>/dev/null | sort -rn | head -n 5)
        else
            top_files=$(find "$full_path" -type f -exec du -k {} + 2>/dev/null | sort -rn | head -n 5 | awk '{print ($1*1024) " " $2}')
        fi
    fi

    # Display results
    echo ""
    write_divider "$GRAY"

    local hr_total
    hr_total=$(convert_size $total_bytes)

    write_item "Ruta"     "$full_path"                              "$GRAY" "$WHITE"
    write_item "Tamaño"   "$hr_total ($total_bytes bytes)"          "$GRAY" "$GREEN"

    if ! $is_file; then
        write_item "Archivos" "$file_count files / $dir_count folders" "$GRAY" "$WHITE"
    fi

    if [[ -n "$top_files" ]]; then
        echo ""
        printf "  ${GRAY}Top 5 archivos más grandes:${NC}\n"
        echo "$top_files" | while read -r size_bytes filepath; do
            if [[ -n "$size_bytes" ]]; then
                local relative="${filepath#${full_path}/}"
                [[ "$relative" == "$filepath" ]] && relative="${filepath##*/}"
                local hr
                hr=$(convert_size $size_bytes)
                printf "    ${GREEN}%-10s${NC} ${GRAY}%s${NC}\n" "$hr" "$relative"
            fi
        done
        echo ""
    fi

    write_divider "$GRAY"
    echo ""
}
