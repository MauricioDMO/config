# ========================================
# CONFIGURACIÓN INICIAL
# ========================================

# Importar módulo de predicción de comandos
if (Get-Module -ListAvailable -Name CompletionPredictor) {
    Import-Module CompletionPredictor -ErrorAction SilentlyContinue
}

# Configurar fnm (Fast Node Manager) para cambio automático de versión de Node
if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd | Out-String | Invoke-Expression
}

# Inicializar oh-my-posh con el tema personalizado
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config $env:POSH_THEMES_PATH/froczh.omp.json | Invoke-Expression
}

# Configurar PSReadLine para autocompletado inteligente
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView -EditMode Windows
}

# Alias para PostgreSQL CLI
if (Get-Command pgcli -ErrorAction SilentlyContinue) {
    Set-Alias pg pgcli
}
