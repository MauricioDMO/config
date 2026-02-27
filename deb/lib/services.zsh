# ========================================
# SERVICIOS DEL SISTEMA
# ========================================

# Abre CornHub
function sexo() {
    # Linux equivalent for open
    xdg-open https://cornhub.website/ > /dev/null 2>&1 &
}

# SSH Agent
function essh() {
    if ! pgrep -u "$USER" ssh-agent > /dev/null; then
        echo "${YELLOW}Starting SSH Agent...${NC}"
        eval "$(ssh-agent -s)"
    else
        echo "${GREEN}SSH Agent is already running.${NC}"
        # Optionally re-export variables if saved somewhere, but for now just status
        if [[ -z "$SSH_AUTH_SOCK" ]]; then
             echo "${RED}Warning: SSH_AUTH_SOCK is not set in current shell.${NC}"
             echo "Run 'eval \$(ssh-agent -s)' to attach to a new agent."
        fi
    fi
}

# Terminal Icons (lsd or eza are usually used in Linux for icons)
function ti() {
    echo "${YELLOW}On Linux, install lsd or eza and configure aliases for icons.${NC}"
}

# 'oc' ? In win it was `opencode -c`. If that's `code .` or similar.
function oc() {
    code .
}

# Monta la partición de Windows cifrada con BitLocker
function mount-win() {
    local device="${BITLOCKER_DEVICE:-/dev/nvme0n1p3}"
    local mount_point="${BITLOCKER_MOUNT:-/mnt/win}"
    local mapper_name="winbit"

    if [[ -z "$BITLOCKER_KEY" ]]; then
        echo "${RED}Error: la variable BITLOCKER_KEY no está definida.${NC}"
        echo "Crea un archivo .env en la raíz del repo basándote en .env.example"
        return 1
    fi

    echo "${CYAN}Abriendo partición BitLocker en $device...${NC}"
    echo "$BITLOCKER_KEY" | sudo cryptsetup open --type bitlk "$device" "$mapper_name"

    echo "${CYAN}Creando punto de montaje $mount_point...${NC}"
    sudo mkdir -p "$mount_point"

    echo "${CYAN}Montando en $mount_point (solo lectura)...${NC}"
    sudo mount -t ntfs-3g -o ro "/dev/mapper/$mapper_name" "$mount_point"

    echo "${GREEN}Partición de Windows montada en $mount_point${NC}"
}

# Desmonta la partición de Windows
function umount-win() {
    local mount_point="${BITLOCKER_MOUNT:-/mnt/win}"
    local mapper_name="winbit"

    echo "${CYAN}Desmontando $mount_point...${NC}"
    sudo umount "$mount_point"

    echo "${CYAN}Cerrando mapper $mapper_name...${NC}"
    sudo cryptsetup close "$mapper_name"

    echo "${GREEN}Partición de Windows desmontada correctamente.${NC}"
}
