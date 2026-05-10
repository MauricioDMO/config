# ========================================
# ALIAS
# ========================================

# --- Sistema ---
alias cp="rsync -ah --info=progress2"
alias shutdown='systemctl poweroff'
alias reboot='systemctl reboot'

# --- Red ---
alias wifi='nmcli device wifi'

# --- Bluetooth / Audio ---
alias buds='bluetoothctl connect D0:56:FB:81:EF:4E'
alias audio='pavucontrol'

# --- Opencode ---
alias o='opencode'

# --- Android ---
phone() {
    if ! command -v adb >/dev/null 2>&1; then
        echo "adb no esta instalado o no esta en PATH."
        return 1
    fi

    if ! command -v scrcpy >/dev/null 2>&1; then
        echo "scrcpy no esta instalado o no esta en PATH."
        return 1
    fi

    local adb_devices device_count unauthorized_count offline_count
    adb_devices=$(adb devices | awk 'NR > 1 && NF >= 2 { print $2 }')
    device_count=$(printf '%s\n' "$adb_devices" | grep -c '^device$')
    unauthorized_count=$(printf '%s\n' "$adb_devices" | grep -c '^unauthorized$')
    offline_count=$(printf '%s\n' "$adb_devices" | grep -c '^offline$')

    if (( device_count == 0 )); then
        if (( unauthorized_count > 0 )); then
            echo "Telefono detectado, pero falta autorizar la depuracion USB en el telefono."
        elif (( offline_count > 0 )); then
            echo "Telefono detectado, pero ADB lo reporta offline. Reconecta el cable o reinicia ADB."
        else
            echo "No hay telefono Android conectado por ADB. Conecta el USB y activa depuracion USB."
        fi
        return 1
    fi

    echo "Telefono detectado por ADB. Abriendo scrcpy..."
    scrcpy --no-audio --max-size=1280 --max-fps=30 --video-bit-rate=6M --video-codec=h264 "$@" >/dev/null 2>&1 &!
}

# --- Ayuda ---
alias myhelp='help_config'

# ls
alias ls='lsd --icon=auto --group-dirs first'
alias ll='lsd -l --icon=auto --group-dirs first'
alias la='lsd -la --icon=auto --group-dirs first'

lt() {
    local depth=${1:-2}
    lsd --tree --depth "$depth" --icon=auto --group-dirs first
}

lta() {
    local depth=${1:-2}
    lsd -la --tree --depth "$depth" --icon=auto --group-dirs first
}

apt-uninstall() {
    local app=$1
    if [[ -z "$app" ]]; then
        echo "Uso: apt-uninstall <nombre-del-paquete>"
        return 1
    fi

    echo "Desinstalando $app"
    sudo apt purge -y "$app"
    sudo apt autoremove -y

    echo "Paquete $app desinstalado y dependencias no necesarias eliminadas."
}

_apt_uninstall_completion() {
    local -a installed_pkgs
    installed_pkgs=("${(@f)$(dpkg-query -W -f='${binary:Package}\n' 2>/dev/null)}")
    _describe 'paquete instalado' installed_pkgs
}

(( $+functions[compdef] )) && compdef _apt_uninstall_completion apt-uninstall
