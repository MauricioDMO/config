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
