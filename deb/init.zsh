# ========================================
# CONFIGURACIÓN INICIAL
# ========================================

# Get directory of this script
DEB_CONFIG_DIR="${0:a:h}"

# --- Variables de entorno (.env en la raíz del repo) ---
ENV_FILE="$DEB_CONFIG_DIR/../.env"
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

# Los terminales iniciados desde el escritorio pueden omitir /usr/games.
if [[ ":$PATH:" != *:/usr/games:* ]]; then
  export PATH="$PATH:/usr/games"
fi

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

# Selecciona el comando que se esta editando; no el scrollback de Ghostty.
_zle_select_move() {
  if [[ $LASTWIDGET != select-* ]]; then
    MARK=$CURSOR
    REGION_ACTIVE=1
  fi
  zle ".$1"
}

_zle_select_left() { _zle_select_move backward-char; }
_zle_select_right() { _zle_select_move forward-char; }
_zle_select_up() { _zle_select_move up-line; }
_zle_select_down() { _zle_select_move down-line; }
_zle_select_word_left() { _zle_select_move backward-word; }
_zle_select_word_right() { _zle_select_move forward-word; }

zle -N select-left _zle_select_left
zle -N select-right _zle_select_right
zle -N select-up _zle_select_up
zle -N select-down _zle_select_down
zle -N select-word-left _zle_select_word_left
zle -N select-word-right _zle_select_word_right

_zle_move() {
  REGION_ACTIVE=0
  zle ".$1"
}

_zle_move_left() { _zle_move backward-char; }
_zle_move_right() {
  REGION_ACTIVE=0
  if (( $+widgets[autosuggest-accept] )); then
    zle autosuggest-accept
  else
    zle .forward-char
  fi
}
_zle_move_up() {
  REGION_ACTIVE=0
  if (( $+widgets[history-substring-search-up] )); then
    zle history-substring-search-up
  elif (( $+widgets[up-line-or-beginning-search] )); then
    zle up-line-or-beginning-search
  else
    zle .up-line-or-history
  fi
}
_zle_move_down() {
  REGION_ACTIVE=0
  if (( $+widgets[history-substring-search-down] )); then
    zle history-substring-search-down
  elif (( $+widgets[down-line-or-beginning-search] )); then
    zle down-line-or-beginning-search
  else
    zle .down-line-or-history
  fi
}
_zle_move_word_left() { _zle_move backward-word; }
_zle_move_word_right() { _zle_move forward-word; }

zle -N move-left _zle_move_left
zle -N move-right _zle_move_right
zle -N move-up _zle_move_up
zle -N move-down _zle_move_down
zle -N move-word-left _zle_move_word_left
zle -N move-word-right _zle_move_word_right

_zle_delete_or() {
  if (( REGION_ACTIVE && MARK != CURSOR )); then
    zle .kill-region
    REGION_ACTIVE=0
  else
    REGION_ACTIVE=0
    zle ".$1"
  fi
}

_zle_backspace() { _zle_delete_or backward-delete-char; }
_zle_delete() { _zle_delete_or delete-char; }
_zle_backspace_word() { _zle_delete_or backward-kill-word; }
_zle_delete_word() { _zle_delete_or kill-word; }

zle -N delete-backward _zle_backspace
zle -N delete-forward _zle_delete
zle -N delete-word-backward _zle_backspace_word
zle -N delete-word-forward _zle_delete_word

bindkey '^[[1;2D' select-left
bindkey '^[[1;2C' select-right
bindkey '^[[1;2A' select-up
bindkey '^[[1;2B' select-down
bindkey '^[[1;6D' select-word-left
bindkey '^[[1;6C' select-word-right
bindkey '^[[1;6A' select-up
bindkey '^[[1;6B' select-down

bindkey "$terminfo[kcub1]" move-left
bindkey "$terminfo[kcuf1]" move-right
bindkey "$terminfo[kcuu1]" move-up
bindkey "$terminfo[kcud1]" move-down
bindkey '^[[D' move-left
bindkey '^[[C' move-right
bindkey '^[[A' move-up
bindkey '^[[B' move-down
bindkey '^[b' move-word-left
bindkey '^[f' move-word-right
bindkey '^[[1;5D' move-word-left
bindkey '^[[1;5C' move-word-right
bindkey '^[[1;5A' move-up
bindkey '^[[1;5B' move-down
bindkey '^?' delete-backward
bindkey '^H' delete-backward
bindkey '^[[3~' delete-forward
bindkey '^[^?' delete-word-backward
bindkey '^[[3;5~' delete-word-forward
bindkey '^[d' delete-word-forward

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
source "$DEB_CONFIG_DIR/lib/wine.zsh"

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
