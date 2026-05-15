# ========================================
# NODE.JS Y DESARROLLO
# ========================================

# Parser JSON mínimo con awk (sin python, sin jq)
# Extrae campos simples de primer nivel de un JSON
_json_field() {
    # $1 = field name, reads JSON from stdin
    awk -v key="\"$1\"" '
    BEGIN { found=0 }
    {
        if (match($0, key "[ \t]*:[ \t]*\"([^\"]*)\"|" key "[ \t]*:[ \t]*([0-9.]+)", arr)) {
            # Try gawk-style match with groups
        }
        # Simpler: just find the key and extract value
        idx = index($0, key)
        if (idx > 0) {
            rest = substr($0, idx + length(key))
            # skip : and whitespace
            gsub(/^[ \t]*:[ \t]*/, "", rest)
            if (substr(rest,1,1) == "\"") {
                # string value
                rest = substr(rest, 2)
                end = index(rest, "\"")
                if (end > 0) print substr(rest, 1, end-1)
            } else {
                # number or other
                gsub(/[,}\n\r].*/, "", rest)
                gsub(/[ \t]+$/, "", rest)
                if (rest != "") print rest
            }
        }
    }' 2>/dev/null
}

# Extrae scripts de package.json con awk puro (sin python, sin jq)
_parse_scripts() {
    [[ ! -f package.json ]] && return 1
    awk '
    BEGIN { in_scripts=0; depth=0 }
    {
        line = $0
        if (in_scripts == 0) {
            if (match(line, /"scripts"[ \t]*:/)) {
                in_scripts = 1
                # Find opening brace on this line or next
                idx = index(line, "{")
                if (idx > 0) {
                    depth = 1
                    line = substr(line, idx+1)
                } else {
                    next
                }
            } else {
                next
            }
        }
        if (in_scripts) {
            n = split(line, chars, "")
            for (i = 1; i <= n; i++) {
                if (chars[i] == "{") depth++
                if (chars[i] == "}") {
                    depth--
                    if (depth <= 0) { in_scripts=0; break }
                }
            }
            # Extract "key": "value" pairs from line
            while (match(line, /"([^"]+)"[ \t]*:[ \t]*"([^"]*)"/, m)) {
                printf "%s\t%s\n", m[1], m[2]
                line = substr(line, RSTART + RLENGTH)
            }
        }
    }' package.json 2>/dev/null
}

# Fallback parser para awk sin arrays en match (mawk)
_parse_scripts_compat() {
    [[ ! -f package.json ]] && return 1
    awk '
    BEGIN { in_scripts=0; depth=0 }
    /"scripts"[ \t]*:/ { in_scripts=1 }
    in_scripts {
        n = split($0, c, "")
        for (i=1; i<=n; i++) {
            if (c[i]=="{") depth++
            if (c[i]=="}") { depth--; if (depth<=0) { in_scripts=0; exit } }
        }
        if (match($0, /\"([^\"]+)\"[ \t]*:[ \t]*\"([^\"]*)\"/)) {
            s = substr($0, RSTART, RLENGTH)
            gsub(/^\"/, "", s); gsub(/\"$/, "", s)
            split(s, parts, "\"[ \t]*:[ \t]*\"")
            if (parts[1] != "" && parts[2] != "") {
                printf "%s\t%s\n", parts[1], parts[2]
            }
        }
    }' package.json 2>/dev/null
}

# Extrae dependencies/devDependencies de package.json con awk puro.
_parse_pkg_deps() {
    [[ ! -f package.json ]] && return 1
    awk '
    BEGIN { section=""; depth=0 }
    {
        line = $0
        if (section == "") {
            if (line ~ /"dependencies"[ \t]*:/) section = "Dependencies"
            else if (line ~ /"devDependencies"[ \t]*:/) section = "Dev Dependencies"
            else next

            idx = index(line, "{")
            if (idx > 0) {
                depth = 1
                line = substr(line, idx + 1)
            } else {
                next
            }
        }

        n = split(line, chars, "")
        for (i = 1; i <= n; i++) {
            if (chars[i] == "{") depth++
            if (chars[i] == "}") {
                depth--
                if (depth <= 0) {
                    line = substr(line, 1, i - 1)
                    done = 1
                    break
                }
            }
        }

        while (match(line, /"[^"]+"[ \t]*:[ \t]*"[^"]*"/)) {
            pair = substr(line, RSTART, RLENGTH)
            line = substr(line, RSTART + RLENGTH)
            gsub(/^"/, "", pair)
            gsub(/"$/, "", pair)
            split(pair, parts, /"[ \t]*:[ \t]*"/)
            if (parts[1] != "" && parts[2] != "") printf "%s\t%s\t%s\n", section, parts[1], parts[2]
        }

        if (done) { section=""; depth=0; done=0 }
    }' package.json 2>/dev/null
}

# Extrae campos del package.json con awk puro
_pkg_field() {
    [[ ! -f package.json ]] && return 1
    local field="$1"
    awk -v key="\"$field\"" '
    /"scripts"|"dependencies"|"devDependencies"/ { skip=1 }
    skip && /{/ { depth++ }
    skip && /}/ { depth--; if(depth<=0) skip=0; next }
    skip { next }
    {
        idx = index($0, key)
        if (idx > 0) {
            rest = substr($0, idx + length(key))
            gsub(/^[ \t]*:[ \t]*"?/, "", rest)
            gsub(/"?[ \t]*,?[ \t]*$/, "", rest)
            if (rest != "") { print rest; exit }
        }
    }' package.json 2>/dev/null
}

# Administra comandos frecuentes de Node.js con nombres cortos y autocompletado.
nd() {
    local action="$1"
    shift

    if [[ -z "$action" ]]; then
        echo "Uso: nd <clean|check|scripts|pkg>"
        return 1
    fi

    case "$action" in
        clean)
            clear
            printf "${CYAN}Cleaning node_modules and lock files...${NC}\n"

            local target
            for target in node_modules package-lock.json pnpm-lock.yaml yarn.lock; do
                if [[ -e "$target" ]]; then
                    rm -rf "$target"
                    printf "  ${GREEN}Removed: %s${NC}\n" "$target"
                fi
            done
            ;;
        check)
            write_header "Runtime Information"

            local name cmd bin version
            for name cmd in \
                "Node.js" "node --version" \
                "npm" "npm --version" \
                "pnpm" "pnpm --version" \
                "bun" "bun --version"; do
                bin="${cmd%% *}"
                if command -v "$bin" >/dev/null 2>&1; then
                    version=$(eval "$cmd" 2>/dev/null)
                    write_item "$name" "$version" "$GREEN" "$GRAY"
                else
                    write_item "$name" "Not installed" "$GRAY" "$GRAY"
                fi
            done

            if [[ -f "package.json" ]]; then
                write_header "Current Project"
                local val
                for field in name version description; do
                    val=$(_pkg_field "$field")
                    [[ -n "$val" ]] && write_item "$field" "$val" "$GREEN" "$GRAY"
                done
            fi
            echo ""
            ;;
        scripts)
            if [[ ! -f "package.json" ]]; then
                printf "\n  ${RED}[!] package.json not found.${NC}\n"
                return 1
            fi

            local scripts_output
            # Try gawk-compatible parser first, fall back to compat
            scripts_output=$(_parse_scripts)
            [[ -z "$scripts_output" ]] && scripts_output=$(_parse_scripts_compat)

            if [[ -z "$scripts_output" ]]; then
                printf "\n  ${YELLOW}[!] No scripts found in package.json.${NC}\n"
                return
            fi

            write_header "Available Scripts"

            local max_len=0 key val
            while IFS=$'\t' read -r key _; do
                (( ${#key} > max_len )) && max_len=${#key}
            done <<< "$scripts_output"
            (( max_len < 10 )) && max_len=10

            while IFS=$'\t' read -r key val; do
                (( ${#val} > 60 )) && val="${val:0:57}..."
                printf "  ${GREEN}%-${max_len}s${NC}  ${GRAY}%s${NC}\n" "$key" "$val"
            done <<< "$scripts_output"
            echo ""
            ;;
        pkg)
            if [[ ! -f "package.json" ]]; then
                printf "\n  ${RED}[!] package.json not found.${NC}\n"
                return 1
            fi

            local deps_output
            deps_output=$(_parse_pkg_deps)

            if [[ -z "$deps_output" ]]; then
                printf "\n  ${YELLOW}[!] No dependencies found in package.json.${NC}\n"
                return
            fi

            local section="" current_section="" key val max_len
            for current_section in "Dependencies" "Dev Dependencies"; do
                max_len=0
                while IFS=$'\t' read -r section key _; do
                    [[ "$section" != "$current_section" ]] && continue
                    (( ${#key} > max_len )) && max_len=${#key}
                done <<< "$deps_output"

                (( max_len == 0 )) && continue
                (( max_len < 10 )) && max_len=10

                write_header "$current_section"
                while IFS=$'\t' read -r section key val; do
                    [[ "$section" != "$current_section" ]] && continue
                    printf "  ${GREEN}%-${max_len}s${NC}  ${GRAY}%s${NC}\n" "$key" "$val"
                done <<< "$deps_output"
            done
            echo ""
            ;;
        *)
            echo "Acción no válida: $action"
            return 1
            ;;
    esac
}

_nd_completion() {
    local -a actions
    actions=(clean check scripts pkg)

    if (( CURRENT == 2 )); then
        compadd -a actions
    fi
}

compdef _nd_completion nd
