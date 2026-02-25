# ========================================
# AYUDA
# ========================================

function help_config() {
    write_header "AYUDA / CONFIGURACIÓN ZSH"

    # Define commands similarly to PS1 structure
    # Format: Category|Command|Description
    local commands=(
        "Navigation|core|Ir a ~/core"
        "Navigation|dev|Ir a ~/core/dev"
        "Navigation|uni|Ir a ~/core/university"
        "Navigation|work|Ir a ~/core/work"
        "Navigation|learn|Ir a ~/core/learn"
        "Navigation|o|Abrir archivo (xdg-open)"
        "Navigation|oc|Abrir VS Code aquí (code .)"
        
        "Package Management|nclean|Limpiar node_modules y locks"
        "Package Management|ncheck|Ver versiones de Node/npm/etc"
        "Package Management|nscripts|Listar scripts de npm disponibles"

        "System|size|Ver tamaño de directorio/archivo detallado"
        "System|essh|Habilitar/Iniciar SSH Agent"
        "System|sexo|???"
        "System|ti|Terminal Icons info"
    )

    # Get unique categories
    local categories=($(printf "%s\n" "${commands[@]}" | cut -d'|' -f1 | sort -u))

    for cat in "${categories[@]}"; do
        echo ""
        echo "  ${CYAN}${cat}${NC}"
        # Print divider for category
        local line=$(printf '─%.0s' {1..${#cat}})
        echo "  ${GRAY}${line}${NC}"

        for entry in "${commands[@]}"; do
            local entry_cat=$(echo "$entry" | cut -d'|' -f1)
            if [[ "$entry_cat" == "$cat" ]]; then
                local cmd=$(echo "$entry" | cut -d'|' -f2)
                local desc=$(echo "$entry" | cut -d'|' -f3)
                write_item "$cmd" "$desc"
            fi
        done
    done
    echo ""
}

# Alias standard help to this if desired, but 'help' is a builtin
alias myhelp='help_config'
