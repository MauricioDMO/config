# ========================================
# TAMAÑO DE DIRECTORIOS
# ========================================

function size() {
    local _find="/usr/bin/find"
    local _du="/usr/bin/du"
    local _wc="/usr/bin/wc"
    local _sort="/usr/bin/sort"
    local _head="/usr/bin/head"
    local _awk="/usr/bin/awk"
    local _stat="/usr/bin/stat"
    local _readlink="/usr/bin/readlink"
    local _cut="/usr/bin/cut"
    local _basename="/usr/bin/basename"

    # Fallback to /bin if not found in /usr/bin
    for _cmd in find du wc sort head awk stat readlink cut basename; do
        local _var="_${_cmd}"
        if [[ ! -x "${(P)_var}" ]]; then
            eval "_${_cmd}=/bin/${_cmd}"
        fi
    done

    local path="${1:-.}"

    if [[ ! -e "$path" ]]; then
        echo "Error: Path not found: $path"
        return 1
    fi

    # Resolve absolute path
    local full_path=""
    if [[ -x "$_readlink" ]]; then
        full_path=$("$_readlink" -f "$path")
    else
        if [[ -d "$path" ]]; then
            full_path=$(cd "$path" && pwd)
        else
            full_path=$(cd "$(dirname "$path")" && pwd)/$(basename "$path")
        fi
    fi

    local is_file=false
    [[ -f "$full_path" ]] && is_file=true

    local total_bytes=0
    local file_count=0
    local dir_count=0
    local top_files=""

    if $is_file; then
        if [[ -x "$_stat" ]]; then
            # Check GNU vs BSD stat
            if "$_stat" --version &>/dev/null; then
                total_bytes=$("$_stat" -c%s "$full_path")
            else
                total_bytes=$("$_stat" -f%z "$full_path")
            fi
        else
            total_bytes=$(ls -l "$full_path" | "$_awk" '{print $5}')
        fi
        file_count=1
        dir_count=0
    else
        # Calculate total size in bytes
        if "$_du" --version &>/dev/null 2>&1; then
            total_bytes=$("$_du" -sb "$full_path" | "$_cut" -f1)
        else
            local kbytes=$("$_du" -sk "$full_path" | "$_awk" '{print $1}')
            total_bytes=$((kbytes * 1024))
        fi

        file_count=$("$_find" "$full_path" -type f | "$_wc" -l)
        file_count="${file_count// /}"

        dir_count=$("$_find" "$full_path" -type d | "$_wc" -l)
        dir_count="${dir_count// /}"

        # Get top 5 largest files
        if "$_find" "$full_path" -maxdepth 0 -printf "" &>/dev/null 2>&1; then
            top_files=$("$_find" "$full_path" -type f -printf "%s %p\n" 2>/dev/null | "$_sort" -rn | "$_head" -n 5)
        else
            top_files=$("$_find" "$full_path" -type f -exec "$_du" -k {} + 2>/dev/null | "$_sort" -rn | "$_head" -n 5 | "$_awk" '{print ($1*1024) " " $2}')
        fi
    fi

    # Display results
    echo ""
    write_divider "$GRAY"

    local hr_total=$(convert_size $total_bytes)

    write_item "Ruta"    "$full_path"                          "$GRAY" "$WHITE"
    write_item "Tamaño"  "$hr_total ($total_bytes bytes)"      "$GRAY" "$GREEN"

    if ! $is_file; then
        write_item "Archivos" "$file_count files / $dir_count folders" "$GRAY" "$WHITE"
    fi

    if [[ -n "$top_files" ]]; then
        echo ""
        echo "  ${GRAY}Top 5 archivos más grandes:${NC}"
        echo "$top_files" | while read -r size_bytes filepath; do
            if [[ -n "$size_bytes" ]]; then
                local relative="${filepath#${full_path}/}"
                [[ -z "$relative" ]] && relative="${filepath:t}"
                local hr=$(convert_size $size_bytes)
                printf "    ${GREEN}%-10s${NC} ${GRAY}%s${NC}\n" "$hr" "$relative"
            fi
        done
        echo ""
    fi

    write_divider "$GRAY"
    echo ""
}
