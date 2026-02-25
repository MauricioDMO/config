# ========================================
# SERVICIOS DEL SISTEMA
# ========================================

# Abre CornHub (sitio de memes de maíz)
function sexo { Start-Process https://cornhub.website/ }

# Habilita y arranca el servicio SSH Agent
function essh {
    $sshAgent = Get-Service ssh-agent
    if ($sshAgent.StartType -ne 'Manual') {
        $sshAgent | Set-Service -StartupType Manual
    }
    if ($sshAgent.Status -ne 'Running') {
        Start-Service ssh-agent
    }
}

# Carga Terminal-Icons
function ti {
    if (-not (Get-Module Terminal-Icons)) {
        Write-Host "Loading Terminal-Icons module..." -ForegroundColor Yellow
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            Import-Module Terminal-Icons
            $stopwatch.Stop()
            Write-Host "✅ Terminal-Icons loaded in $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Green
        }
        catch {
            $stopwatch.Stop()
            Write-Host "❌ Failed to load Terminal-Icons after $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Red
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "✅ Terminal-Icons is already loaded" -ForegroundColor Green
    }
}

New-Alias o opencode

function oc {
    opencode -c
}