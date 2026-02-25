# ========================================
# NAVEGACIÓN RÁPIDA
# ========================================

# Rutas rápidas
$script:QuickPaths = @{
    core  = "$env:USERPROFILE\core"
    dev   = "$env:USERPROFILE\core\dev"
    uni   = "$env:USERPROFILE\core\university"
    work  = "$env:USERPROFILE\core\work"
    learn = "$env:USERPROFILE\core\learn"
}

# Función auxiliar para navegación con error amigable
function _Go {
    param([string]$BasePath, [string]$RelativePath)
    $target = Join-Path $BasePath ($RelativePath.TrimStart('\').TrimStart('/'))
    if (Test-Path $target) {
        Set-Location $target
    }
    else {
        Write-Host ""
        Write-Host "  📂 " -NoNewline
        Write-Host "Ruta no encontrada: " -ForegroundColor Red -NoNewline
        Write-Host $target -ForegroundColor Yellow
        Write-Host ""
    }
}

function core {
    param([string]$Path = "")
    _Go $script:QuickPaths.core $Path
}
function dev {
    param([string]$Path = "")
    _Go $script:QuickPaths.dev $Path
}
function uni {
    param([string]$Path = "")
    _Go $script:QuickPaths.uni $Path
}
function work {
    param([string]$Path = "")
    _Go $script:QuickPaths.work $Path
}
function learn {
    param([string]$Path = "")
    _Go $script:QuickPaths.learn $Path
}

# Autocompletado para rutas rápidas
$script:QuickPaths.Keys | ForEach-Object {
    $cmd = $_
    Register-ArgumentCompleter -CommandName $cmd -ParameterName Path -ScriptBlock {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        
        $base = $script:QuickPaths.$commandName
        
        $quote = if ($wordToComplete -match "^(['""])") { $matches[1] } else { "" }
        
        $cleanWord = ($wordToComplete -replace "^['""]|['""]$", "").Replace('/', '\').TrimStart('\')
        $fullPath = Join-Path $base $cleanWord
        
        $parent = if (Test-Path $fullPath -PathType Container) { $fullPath } else { Split-Path $fullPath -Parent }
        $filter = if (Test-Path $fullPath -PathType Container) { "*" } else { (Split-Path $fullPath -Leaf) + "*" }

        if (Test-Path $parent) {
            Get-ChildItem -Path $parent -Directory -Filter $filter | ForEach-Object {
                $rel = $_.FullName.Substring($base.Length).Replace('\', '/')
                $completionText = "/$($rel.Trim('/'))/"
                
                if ($quote) {
                    $completionText = $quote + $completionText + $quote
                }

                [System.Management.Automation.CompletionResult]::new($completionText, $_.Name, 'ParameterValue', $_.FullName)
            }
        }
    }
}

# Abre File Pilot en la ruta especificada
function e { 
    param([string]$Path = '.')
    FPilot.exe $Path
}

# Abre VS Code aquí o ruta especificada
function c {
    param([string]$Path = '.')
    code $Path
}

function dps {
    param([string]$Path = '.')
    $fullPath = (Resolve-Path $Path).Path
    wt -w 0 nt -d "$fullPath"
}

function x {
    exit
}