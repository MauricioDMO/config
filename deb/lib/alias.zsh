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

compdef _apt_uninstall_completion apt-uninstall
