# ========================================
# NODE.JS Y DESARROLLO
# ========================================

function nclean() {
    clear
    echo "${CYAN}Cleaning node_modules and lock files...${NC}"

    local targets=("node_modules" "package-lock.json" "pnpm-lock.yaml" "yarn.lock")

    for target in "${targets[@]}"; do
        if [[ -e "$target" ]]; then
            rm -rf "$target"
            echo "  ${GREEN}Removed: $target${NC}"
        fi
    done
}

function ncheck() {
    write_header "Runtime Information"

    local -a names=("Node.js" "npm" "pnpm" "bun")
    local -a cmds=("node --version" "npm --version" "pnpm --version" "bun --version")

    for i in {1..${#names[@]}}; do
        local name="${names[$i]}"
        local cmd="${cmds[$i]}"
        local bin="${cmd%% *}"

        if command -v "$bin" &> /dev/null; then
            local version
            version=$(eval "$cmd" 2>/dev/null)
            write_item "$name" "$version" "$GREEN" "$GRAY"
        else
            write_item "$name" "Not installed" "$GRAY" "$GRAY"
        fi
    done

    if [[ -f "package.json" ]]; then
        write_header "Current Project"

        local pkg_json
        pkg_json=$(python3 -c "
import json
with open('package.json') as f:
    d = json.load(f)
for k in ('name', 'version', 'description'):
    print(k + '\t' + str(d.get(k, '')))
" 2>/dev/null)

        while IFS=$'\t' read -r key val; do
            [[ -n "$val" ]] && write_item "$key" "$val" "$GREEN" "$GRAY"
        done <<< "$pkg_json"
    fi

    echo ""
}

function _parse_scripts() {
    if command -v jq &> /dev/null; then
        jq -r 'if .scripts then .scripts | to_entries[] | "\(.key)\t\(.value)" else empty end' package.json 2>/dev/null
    elif command -v python3 &> /dev/null; then
        python3 -c "
import json
with open('package.json') as f:
    d = json.load(f)
for k, v in d.get('scripts', {}).items():
    print(k + '\t' + v)
" 2>/dev/null
    fi
}

function nscripts() {
    if [[ ! -f "package.json" ]]; then
        echo -e "\n  ${RED}[!] package.json not found.${NC}"
        return 1
    fi

    local scripts_output
    scripts_output=$(_parse_scripts)

    if [[ -z "$scripts_output" ]]; then
        echo -e "\n  ${YELLOW}[!] No scripts found in package.json.${NC}"
        return
    fi

    write_header "Available Scripts"

    local max_len=0
    while IFS=$'\t' read -r key _; do
        (( ${#key} > max_len )) && max_len=${#key}
    done <<< "$scripts_output"
    (( max_len < 10 )) && max_len=10

    while IFS=$'\t' read -r key val; do
        (( ${#val} > 60 )) && val="${val:0:57}..."
        printf "  ${GREEN}%-${max_len}s${NC}  ${GRAY}%s${NC}\n" "$key" "$val"
    done <<< "$scripts_output"

    echo ""
}
