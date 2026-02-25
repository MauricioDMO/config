# ========================================
# UTILIDADES GENERALES
# ========================================

# Convierte bytes a un formato legible (KB, MB, GB, TB)
function Convert-Size([long]$bytes) {
    if ($bytes -ge 1TB) { return ('{0:N2} TB' -f ($bytes / 1TB)) }
    if ($bytes -ge 1GB) { return ('{0:N2} GB' -f ($bytes / 1GB)) }
    if ($bytes -ge 1MB) { return ('{0:N2} MB' -f ($bytes / 1MB)) }
    if ($bytes -ge 1KB) { return ('{0:N2} KB' -f ($bytes / 1KB)) }
    return ("{0} B" -f $bytes)
}

# Centra texto en la consola (usada por el banner)
function Write-HostCentered {
    param (
        [string]$Text,
        [ConsoleColor]$ForegroundColor = 'White'
    )
    try { $width = [Console]::WindowWidth } catch { $width = 80 }
    if (-not $width -or $width -lt 20) { $width = 80 }
    if ($Text.Length -ge $width) {
        Write-Host $Text -ForegroundColor $ForegroundColor
    }
    else {
        $padding = ' ' * [math]::Floor(($width - $Text.Length) / 2)
        Write-Host "$padding$Text" -ForegroundColor $ForegroundColor
    }
}

# Escribe un encabezado estilizado
function Write-Header {
    param ([string]$Title, [ConsoleColor]$Color = 'DarkGreen')
    $border = '═' * ($Title.Length + 4)
    Write-Host "`n  ╔$border╗" -ForegroundColor $Color
    Write-Host "  ║  $Title  ║" -ForegroundColor $Color
    Write-Host "  ╚$border╝" -ForegroundColor $Color
}

# Escribe una línea de item (Comando » Descripción)
function Write-Item {
    param (
        [string]$Label,
        [string]$Value,
        [int]$Padding = 12,
        [ConsoleColor]$LabelColor = 'DarkGreen',
        [ConsoleColor]$ValueColor = 'White',
        [switch]$Truncate
    )
    
    $displayValue = $Value

    if ($Truncate) {
        # Calcular ancho disponible para evitar que el texto se rompa
        try { $width = [Console]::WindowWidth } catch { $width = 80 }
        if ($width -lt 40) { $width = 80 }
        
        $prefix = "    $($Label.PadRight($Padding)) » "
        $available = $width - $prefix.Length - 1
        
        if ($Value.Length -gt $available -and $available -gt 3) {
            $displayValue = $Value.Substring(0, $available - 3) + "..."
        }
    }

    Write-Host "    $($Label.PadRight($Padding))" -ForegroundColor $LabelColor -NoNewline
    Write-Host " » " -ForegroundColor Gray -NoNewline
    Write-Host $displayValue -ForegroundColor $ValueColor
}

# Escribe una sección de categoría
function Write-Category {
    param ([string]$Name, [ConsoleColor]$Color = 'DarkGreen')
    Write-Host "`n  $Name" -ForegroundColor $Color
    Write-Host "  $('-' * $Name.Length)" -ForegroundColor $Color
}

# Escribe una línea divisoria
function Write-Divider {
    param ([ConsoleColor]$Color = 'DarkGray')
    try { $width = [Console]::WindowWidth } catch { $width = 60 }
    if ($width -lt 20) { $width = 60 }
    $line = '─' * ($width - 4)
    Write-Host "  $line" -ForegroundColor $Color
}


