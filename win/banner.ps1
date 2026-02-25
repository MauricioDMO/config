# ========================================
# BANNER DE INICIO
# ========================================

function Show-Name {
    $asciiArt = @(
        '░█▄█░█▀█░█░█░█▀▄░▀█▀░█▀▀░▀█▀░█▀█░█▀▄░█▄█░█▀█'
        '░█░█░█▀█░█░█░█▀▄░░█░░█░░░░█░░█░█░█░█░█░█░█░█'
        '░▀░▀░▀░▀░▀▀▀░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀▀░░▀░▀░▀▀▀'
    )
    Write-Host ""
    $asciiArt | ForEach-Object { Write-HostCentered $_ -ForegroundColor DarkGreen }
    
    $date = Get-Date -Format "dddd, dd MMMM yyyy HH:mm"
    $os = (Get-CimInstance Win32_OperatingSystem).Caption
    
    Write-HostCentered "────────────────────────────────────────────────" -ForegroundColor Gray
    Write-HostCentered "  $date  " -ForegroundColor Gray
    Write-HostCentered "────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host ""
}

Show-Name
