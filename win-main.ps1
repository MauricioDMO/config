# ===============================
# Bootstrap de configuración pwsh
# ===============================
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptsDir = Join-Path $ScriptRoot 'win'

# Carga manual en orden lógico
$scriptOrder = @(
    'init.ps1',
    'utils.ps1',
    'size.ps1',
    'navigation.ps1',
    'services.ps1',
    'node.ps1',
    'help.ps1',
    'banner.ps1'
)

foreach ($scriptName in $scriptOrder) {
    $path = Join-Path $ScriptsDir $scriptName
    if (Test-Path $path) {
        try {
            . $path
        } catch {
            Write-Host "❌ Error al cargar $($scriptName): $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Warning "Archivo no encontrado: $scriptName"
    }
}

# Write-Host "✓ Configuración pwsh cargada correctamente" -ForegroundColor DarkGreen
