# ========================================
# CONFIGURACIÓN INICIAL
# ========================================

# Get directory of this script
DEB_CONFIG_DIR="${0:a:h}"

# --- Variables de entorno (.env en la raíz del repo) ---
ENV_FILE="$DEB_CONFIG_DIR/../.env"
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

# --- ZSH / OMZ Setup (Moved from .zshrc) ---

# Ruta de Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

# Tema
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins de Oh My Zsh (sin zsh-autosuggestions)
plugins=(
  git
  sudo
  z
  extract
  colored-man-pages
  command-not-found
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Cargar zsh-autocomplete
source ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# Menos ruido
zstyle ':autocomplete:*' delay 0.12
zstyle ':autocomplete:*' min-input 2

# Limita cuántas opciones aparecen
zstyle ':autocomplete:*:*' list-lines 10

# Si entras a historial (↑ o Ctrl+R), muestra menos líneas
zstyle ':autocomplete:history-incremental-search-backward:*' list-lines 6
zstyle ':autocomplete:history-search-backward:*' list-lines 20

bindkey "$terminfo[kcud1]" down-line-or-select
bindkey "$terminfo[kcuu1]" up-line-or-search

autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic

## combinaciones de teclado

bindkey -e

# Movimiento por palabra (Ctrl+Left / Ctrl+Right)
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[[5D' backward-word
bindkey '^[[5C' forward-word

# Borrar palabra siguiente (Ctrl+Delete)
bindkey '^[[3;5~' kill-word

# Borrar palabra anterior (Alt+Backspace)
bindkey '^[^?' backward-kill-word
bindkey '^[^H' backward-kill-word

bindkey '^W' backward-kill-word
bindkey '^[d' kill-word

autoload -Uz select-word-style
select-word-style bash

# Profile 
source ~/.zprofile

# --- Custom Modules ---

# Source all other config files
source "$DEB_CONFIG_DIR/lib/utils.zsh"
source "$DEB_CONFIG_DIR/lib/banner.zsh"
source "$DEB_CONFIG_DIR/lib/navigation.zsh"
source "$DEB_CONFIG_DIR/lib/services.zsh"
source "$DEB_CONFIG_DIR/lib/node.zsh"
source "$DEB_CONFIG_DIR/lib/size.zsh"
source "$DEB_CONFIG_DIR/lib/help.zsh"
source "$DEB_CONFIG_DIR/lib/alias.zsh"


# Configurar fnm (Fast Node Manager)
FNM_PATH="/home/mauriciodmo/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
    export PATH="$FNM_PATH:$PATH"
    eval "`fnm env`"
fi

# Bun setup
export BUN_INSTALL="$HOME/.bun"
if [ -d "$BUN_INSTALL" ]; then
    export PATH="$BUN_INSTALL/bin:$PATH"
    [ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"
fi

# Postgres alias
if command -v pgcli &> /dev/null; then
  alias pg='pgcli'
fi

