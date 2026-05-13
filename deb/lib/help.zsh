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
        "c|Abrir VS Code aquí o en una ruta" \
        "dps|Abrir Ghostty en una ruta" \
        "e|Abrir Thunar en una ruta" \
        "r|Abrir ranger y volver al directorio elegido"

    _help_section "Package Management" \
        "nd clean|Limpiar node_modules y locks" \
        "nd check|Ver versiones de Node/npm/etc" \
        "nd scripts|Listar scripts de npm disponibles"

    _help_section "System" \
        "size|Ver tamaño de directorio/archivo detallado" \
        "essh|Habilitar/Iniciar SSH Agent" \
        "svc|Administrar servicios frecuentes" \
        "lock-laptop|Bloquear laptop con i3lock e imagen aleatoria" \
        "mount-win|Montar partición Windows (BitLocker)" \
        "umount-win|Desmontar partición Windows" \
        "apt-uninstall|Purgar paquete apt y dependencias" \
        "phone|Abrir Android conectado con scrcpy"

    _help_section "Graphic Tablet" \
        "tablet_setup [OUTPUT]|Aplica setup completo de tableta (acepta salida o desktop)" \
        "tablet_focus [OUTPUT]|Selecciona mapeo por numero (0=desktop, 1..N=pantalla)"

    _help_section "Wine" \
        "createwine [--init-only]|Asistente para crear perfil o solo init.sh" \
        "cwine|Alias corto de createwine"

    echo ""
}
