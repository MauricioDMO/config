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
