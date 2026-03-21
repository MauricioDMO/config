# ========================================
# CONFIGURACIÓN INICIAL
# ========================================

# Get directory of this script
DEB_CONFIG_DIR="${0:a:h}"

# --- Variables de entorno (.env en la raíz del repo) ---
ENV_FILE="$DEB_CONFIG_DIR/../.env"
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

# ========================================
# ZSH / OMZ Setup
# ========================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Importante:
# - NO cargamos zsh-syntax-highlighting como plugin de OMZ para poder cargarlo al final (recomendado).
plugins=(
  git
  sudo
  z
  extract
  colored-man-pages
  command-not-found
)

source "$ZSH/oh-my-zsh.sh"

# ========================================
# COMPLETADO / SUGERENCIAS (tipo "fish")
# ========================================

# --- fzf-tab (mejor menú al tab) ---
# Requiere: sudo apt install -y fzf
#          git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab
if [[ -f "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab/fzf-tab.plugin.zsh" ]]; then
  source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab/fzf-tab.plugin.zsh"
fi

# --- zsh-autosuggestions (texto fantasma mientras escribes) ---
# Requiere: git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
if [[ -f "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

  # historial + completion (predicción por comandos/opciones/rutas)
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)

  # más fluido
  ZSH_AUTOSUGGEST_USE_ASYNC=1

  # color de sugerencia (gris)
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

  # Aceptar sugerencia con → (Right Arrow) y/o Ctrl+F
  bindkey '^[[C' autosuggest-accept
  bindkey '^F' autosuggest-accept
fi

# --- history substring search (↑/↓ filtra por lo que ya escribiste) ---
# Requiere: git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
if [[ -f "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh" ]]; then
  source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh"
fi

# ========================================
# KEYBINDS / EDICIÓN
# ========================================

autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic

bindkey -e

# Flechas:
# - Si está cargado history-substring-search -> ↑/↓ buscarán en historial según lo escrito
# - Si no está cargado -> ↑/↓ se comportan normal (up/down line)
if (( $+functions[history-substring-search-up] )); then
  bindkey "$terminfo[kcuu1]" history-substring-search-up
  bindkey "$terminfo[kcud1]" history-substring-search-down
else
  bindkey "$terminfo[kcuu1]" up-line-or-history
  bindkey "$terminfo[kcud1]" down-line-or-history
fi

# Moverse por palabras
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[[5D' backward-word
bindkey '^[[5C' forward-word

# Borrar palabras
bindkey '^[[3;5~' kill-word
bindkey '^[^?' backward-kill-word
bindkey '^[^H' backward-kill-word
bindkey '^W' backward-kill-word
bindkey '^[d' kill-word

autoload -Uz select-word-style
select-word-style bash

# Profile
[[ -f ~/.zprofile ]] && source ~/.zprofile

# ========================================
# --- Custom Modules ---
# ========================================

source "$DEB_CONFIG_DIR/lib/utils.zsh"
source "$DEB_CONFIG_DIR/lib/banner.zsh"
source "$DEB_CONFIG_DIR/lib/navigation.zsh"
source "$DEB_CONFIG_DIR/lib/services.zsh"
source "$DEB_CONFIG_DIR/lib/node.zsh"
source "$DEB_CONFIG_DIR/lib/size.zsh"
source "$DEB_CONFIG_DIR/lib/help.zsh"
source "$DEB_CONFIG_DIR/lib/alias.zsh"
source "$DEB_CONFIG_DIR/lib/graphic-tablet.zsh"

# ========================================
# Node / Bun / Extras
# ========================================

# Configurar fnm (Fast Node Manager)
FNM_PATH="$HOME/.local/share/fnm"
if [[ -d "$FNM_PATH" ]]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell zsh)"
fi

# Bun setup
export BUN_INSTALL="$HOME/.bun"
if [ -d "$BUN_INSTALL" ]; then
  export PATH="$BUN_INSTALL/bin:$PATH"
  [ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"
fi

# if command -v dircolors >/dev/null 2>&1; then
#   # carga colores por defecto
#   eval "$(dircolors -b)"
# fi

# fuerza directorios y “casos especiales” SIN background
export LS_COLORS="${LS_COLORS}:di=01;34:ow=01;34:tw=01;34:st=01;34"

# Postgres alias
if command -v pgcli &> /dev/null; then
  alias pg='pgcli'
fi

# ========================================
# ZSH SYNTAX HIGHLIGHTING (SIEMPRE AL FINAL)
# ========================================
if [[ -f "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi