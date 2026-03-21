# ========================================
# AYUDA
# ========================================

help_config() {
    write_header "AYUDA / CONFIGURACIÓN ZSH"

    # Imprime sección de ayuda: usa parameter expansion en lugar de cut (sin subshells)
    _help_section() {
        local cat_name="$1"; shift
        echo ""
        printf "  ${CYAN}%s${NC}\n" "$cat_name"
        printf "  ${GRAY}%s${NC}\n" "$(_repeat_char '─' ${#cat_name})"
        local entry
        for entry in "$@"; do
            write_item "${entry%%|*}" "${entry#*|}"
        done
    }

    _help_section "Navigation" \
        "core|Ir a ~/core" \
        "dev|Ir a ~/core/dev" \
        "uni|Ir a ~/core/university" \
        "work|Ir a ~/core/work" \
        "learn|Ir a ~/core/learn" \
        "oc|Abrir VS Code aquí (code .)"

    _help_section "Package Management" \
        "nclean|Limpiar node_modules y locks" \
        "ncheck|Ver versiones de Node/npm/etc" \
        "nscripts|Listar scripts de npm disponibles"

    _help_section "System" \
        "size|Ver tamaño de directorio/archivo detallado" \
        "essh|Habilitar/Iniciar SSH Agent" \
        "mount-win|Montar partición Windows (BitLocker)" \
        "umount-win|Desmontar partición Windows"

    _help_section "Graphic Tablet" \
        "tablet_setup [OUTPUT]|Aplica setup completo de tableta (acepta salida o desktop)" \
        "tablet_focus [OUTPUT]|Selecciona mapeo por numero (0=desktop, 1..N=pantalla)"

    echo ""
}
