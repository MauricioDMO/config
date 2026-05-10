# ========================================
# SERVICIOS DEL SISTEMA
# ========================================

# Abre CornHub
sexo() { xdg-open https://cornhub.website/ >/dev/null 2>&1 & }

# SSH Agent
essh() {
    if ! pgrep -u "$USER" ssh-agent >/dev/null; then
        printf "${YELLOW}Starting SSH Agent...${NC}\n"
        eval "$(ssh-agent -s)"
    else
        printf "${GREEN}SSH Agent is already running.${NC}\n"
        if [[ -z "$SSH_AUTH_SOCK" ]]; then
            printf "${RED}Warning: SSH_AUTH_SOCK is not set in current shell.${NC}\n"
            echo "Run 'eval \$(ssh-agent -s)' to attach to a new agent."
        fi
    fi
}

# Bloquea la laptop con i3lock usando una imagen aleatoria
lock-laptop() {
    local -a images=("$HOME/core/config/lock/troll"/*(.N))
    local image forest_green lock_display lock_xauthority

    if (( ${#images} == 0 )); then
        printf "${RED}Error: no se encontraron imágenes en %s.${NC}\n" "$HOME/core/config/lock/troll"
        return 1
    fi

    image="${images[$((RANDOM % ${#images} + 1))]}"
    forest_green="#228B22"
    lock_display="${DISPLAY:-:0}"
    lock_xauthority="${XAUTHORITY:-$HOME/.Xauthority}"

    printf "${CYAN}Bloqueando con %s...${NC}\n" "${image:t}"
    DISPLAY="$lock_display" XAUTHORITY="$lock_xauthority" i3lock -n -t -c "${forest_green#\#}" -i "$image"
}

# Monta la partición de Windows cifrada con BitLocker
mount-win() {
    local device="${BITLOCKER_DEVICE:-/dev/nvme0n1p3}"
    local mount_point="${BITLOCKER_MOUNT:-/mnt/win}"
    local mapper_name="winbit"

    if [[ -z "$BITLOCKER_KEY" ]]; then
        printf "${RED}Error: la variable BITLOCKER_KEY no está definida.${NC}\n"
        echo "Crea un archivo .env en la raíz del repo basándote en .env.example"
        return 1
    fi

    printf "${CYAN}Abriendo partición BitLocker en %s...${NC}\n" "$device"
    echo "$BITLOCKER_KEY" | sudo cryptsetup open --type bitlk "$device" "$mapper_name"

    sudo mkdir -p "$mount_point"

    printf "${CYAN}Montando en %s (solo lectura)...${NC}\n" "$mount_point"
    sudo mount -t ntfs-3g -o ro "/dev/mapper/$mapper_name" "$mount_point"

    printf "${GREEN}Partición de Windows montada en %s${NC}\n" "$mount_point"
}

# Desmonta la partición de Windows
umount-win() {
    local mount_point="${BITLOCKER_MOUNT:-/mnt/win}"
    local mapper_name="winbit"

    printf "${CYAN}Desmontando %s...${NC}\n" "$mount_point"
    sudo umount "$mount_point"

    printf "${CYAN}Cerrando mapper %s...${NC}\n" "$mapper_name"
    sudo cryptsetup close "$mapper_name"

    printf "${GREEN}Partición de Windows desmontada correctamente.${NC}\n"
}
