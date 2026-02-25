# ========================================
# AYUDA / CATÁLOGO DE COMANDOS
# ========================================

function commands {
    # Para añadir nuevos comandos, solo agrega un objeto a esta lista
    $commandList = @(
        # NAVEGACIÓN
        @{ Cat = "Navigation"; Cmd = "e"; Desc = "Open current directory in Explorer" }
        @{ Cat = "Navigation"; Cmd = "c"; Desc = "Open current directory in VS Code" }
        @{ Cat = "Navigation"; Cmd = "dps"; Desc = "Open new tab in current Terminal window" }
        @{ Cat = "Navigation"; Cmd = "core"; Desc = "Go to core directory" }
        @{ Cat = "Navigation"; Cmd = "dev"; Desc = "Go to dev directory" }
        @{ Cat = "Navigation"; Cmd = "uni"; Desc = "Go to university directory" }
        @{ Cat = "Navigation"; Cmd = "work"; Desc = "Go to work directory" }
        @{ Cat = "Navigation"; Cmd = "learn"; Desc = "Go to learn directory" }
        
        # PACKAGE MANAGEMENT
        @{ Cat = "Package Management"; Cmd = "nclean"; Desc = "Clean node_modules and lock files" }
        @{ Cat = "Package Management"; Cmd = "ncheck"; Desc = "Check Node versions and project info" }
        @{ Cat = "Package Management"; Cmd = "nscripts"; Desc = "List available npm scripts" }
        
        # SYSTEM
        @{ Cat = "System"; Cmd = "ti"; Desc = "Load Terminal-Icons module" }
        @{ Cat = "System"; Cmd = "essh"; Desc = "Enable SSH Agent" }
        @{ Cat = "System"; Cmd = "size"; Desc = "Shows the size of the dir" }
        @{ Cat = "System"; Cmd = "sexo"; Desc = "A funny command..." }
    )

    Write-Header "HELP / COMMAND CATALOG"

    $categories = $commandList | ForEach-Object { $_.Cat } | Select-Object -Unique
    foreach ($cat in $categories) {
        Write-Category $cat
        $commandList | Where-Object { $_.Cat -eq $cat } | ForEach-Object {
            Write-Item -Label $_.Cmd -Value $_.Desc -Padding 10
        }
    }
    Write-Host ""
}
