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
    if [[ -x /usr/bin/readlink ]]; then
        full_path=$(/usr/bin/readlink -f "$path")
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
        total_bytes=$(/usr/bin/stat -c%s "$full_path" 2>/dev/null || /usr/bin/stat -f%z "$full_path" 2>/dev/null || /usr/bin/ls -l "$full_path" | /usr/bin/awk '{print $5}')
        file_count=1
        dir_count=0
    else
        # Total size in bytes
        if /usr/bin/du --version >/dev/null 2>&1; then
            total_bytes=$(/usr/bin/du -sb "$full_path" | /usr/bin/cut -f1)
        else
            total_bytes=$(/usr/bin/du -sk "$full_path" | /usr/bin/awk '{print $1}')
            total_bytes=$(( ${total_bytes:-0} * 1024 ))
        fi

        file_count=$(/usr/bin/find "$full_path" -type f 2>/dev/null | /usr/bin/wc -l)
        file_count="${file_count// /}"
        dir_count=$(/usr/bin/find "$full_path" -type d 2>/dev/null | /usr/bin/wc -l)
        dir_count="${dir_count// /}"

        # Top 5 largest files (GNU find with -printf, fallback to du)
        if /usr/bin/find "$full_path" -maxdepth 0 -printf "" 2>/dev/null; then
            top_files=$(/usr/bin/find "$full_path" -type f -printf "%s %p\n" 2>/dev/null | /usr/bin/sort -rn | /usr/bin/head -n 5)
        else
            top_files=$(/usr/bin/find "$full_path" -type f -exec /usr/bin/du -k {} + 2>/dev/null | /usr/bin/sort -rn | /usr/bin/head -n 5 | /usr/bin/awk '{print ($1*1024) " " $2}')
        fi
    fi

    # Display results
    echo ""
    write_divider "$WHITE"

    local hr_total size_label
    hr_total=$(convert_size $total_bytes)
    if (( total_bytes >= 1073741824 )); then
        size_label="$hr_total"
    else
        size_label="$hr_total ($total_bytes bytes)"
    fi

    write_item "Ruta"     "$full_path"                              "$WHITE" "$WHITE"
    write_item "Tamaño"   "$size_label"                             "$WHITE" "$GREEN"

    if ! $is_file; then
        write_item "Archivos" "$file_count files / $dir_count folders" "$WHITE" "$WHITE"
    fi

    if [[ -n "$top_files" ]]; then
        echo ""
        printf "  ${WHITE}Top 5 archivos más grandes:${NC}\n"
        local _rel _hr _sz _fp
        while read -r _sz _fp; do
            [[ -z "$_sz" ]] && continue
            _rel="${_fp#${full_path}/}"
            [[ "$_rel" == "$_fp" ]] && _rel="${_fp##*/}"
            _hr=$(convert_size "$_sz")
            printf "    ${GREEN}%-10s${NC} ${WHITE}%s${NC}\n" "$_hr" "$_rel"
        done < <(printf '%s\n' "$top_files")
        echo ""
    fi

    write_divider "$WHITE"
    echo ""
}
