# Personal System Config

Configuracion personal versionada para Debian/i3/Zsh y PowerShell en Windows.

El objetivo es mantener el entorno reproducible sin convertir el perfil de shell o la configuracion de i3 en archivos gigantes.

## Estructura

```text
.
├── deb/
│   ├── init.zsh                 # Bootstrap principal de Zsh
│   ├── setup.zsh                # Enlaces de configuracion para Debian
│   ├── lib/                     # Modulos Zsh: navegacion, servicios, node, wine, etc.
│   ├── i3/config                # Configuracion de i3wm
│   ├── i3blocks/                # Barra de estado y scripts
│   ├── ghostty/                 # Terminal Ghostty
│   ├── rofi/                    # Tema de Rofi
│   ├── thermal/                 # Servicio thermal-guard
│   ├── terminal/.p10k.zsh       # Tema Powerlevel10k
│   ├── X11/                     # Configuracion Xorg
│   └── xfce4/                   # Power manager
├── win-main.ps1                 # Bootstrap principal de PowerShell
├── win/                         # Modulos PowerShell
├── .env.example                 # Variables locales de ejemplo
└── .gitignore
```

## Instalacion En Debian

1. Clona o ubica el repo en `~/.config/config`.
2. En tu `.zshrc`, carga el bootstrap:

```zsh
source "$HOME/.config/config/deb/init.zsh"
```

3. Aplica enlaces de configuracion:

```sh
~/.config/config/deb/setup.zsh
```

Puedes ejecutarlo con `sudo` si quieres enlazar tambien archivos de sistema como X11, systemd y thermal-guard. Los enlaces dentro de `$HOME` se crean como el usuario real.

4. Si usas thermal-guard:

```sh
sudo systemctl enable --now thermal-guard.service
```

## Instalacion En Windows

En tu perfil de PowerShell (`$PROFILE`), carga `win-main.ps1`:

```powershell
$ConfigHome = $env:PWSH_CONFIG_HOME
if ([string]::IsNullOrWhiteSpace($ConfigHome)) {
    $ConfigHome = Join-Path $HOME '.config\config'
}

$Bootstrap = Join-Path $ConfigHome 'win-main.ps1'
if (Test-Path $Bootstrap) {
    . $Bootstrap
} else {
    Write-Warning "No se encontro: $Bootstrap"
}
```

## Variables Locales

Copia `.env.example` a `.env` y ajusta valores privados o especificos de maquina.

```sh
cp .env.example .env
```

`.env` no se versiona. Actualmente se usa para BitLocker y puede ampliarse para rutas o dispositivos locales.

Variables utiles para thermal-guard:

```sh
THERMAL_GUARD_CPU_PKG_TEMP=/sys/class/hwmon/hwmonX/tempY_input
THERMAL_GUARD_CPU_ACPI_TEMP=/sys/class/hwmon/hwmonX/tempY_input
THERMAL_GUARD_TMEM_TEMP=/sys/class/hwmon/hwmonX/tempY_input
```

Si no se definen, `thermal-guard` intenta autodetectar sensores por etiqueta `hwmon` y luego usa los paths historicos como fallback.

## Comandos Principales

Zsh:

```text
help_config     Lista comandos personalizados
core/dev/work   Navegacion rapida
c/dps/e/r       Abrir VS Code, Ghostty, Thunar o ranger
nd check        Versiones de Node/npm/pnpm/bun
nd scripts      Scripts disponibles en package.json
nd clean        Limpia node_modules y lockfiles
size            Tamano de archivo/directorio
svc             Administra servicios frecuentes
essh            Inicia ssh-agent
phone           Abre Android conectado con scrcpy
mount-win       Monta particion BitLocker en modo lectura
createwine      Crea perfil Wine e init.sh
removewine      Elimina perfil Wine
```

PowerShell:

```text
commands        Lista comandos personalizados
core/dev/work   Navegacion rapida
c/dps/e         VS Code, Windows Terminal, File Pilot
ncheck          Versiones de Node/npm/pnpm/bun
nscripts        Scripts disponibles en package.json
size            Tamano de archivo/directorio
essh            Inicia ssh-agent
ti              Carga Terminal-Icons
o/oc            Opencode
```

## Validacion

Comandos utiles antes de commitear cambios:

```sh
zsh -n deb/init.zsh deb/lib/*.zsh
bash -n deb/setup.zsh deb/i3blocks/scripts/*.sh deb/thermal/thermal-guard.sh
i3 -C -c deb/i3/config
```

Si tienes `shellcheck`, tambien conviene ejecutarlo sobre los scripts `.sh`.

## Notas

- i3 alterna teclado solo con `Mod+Space`; no se configura un atajo extra de XKB.
- Varias rutas siguen siendo personales (`~/core`, fondos, lockscreen). Ajustalas si migras de maquina.
- Los scripts de hardware incluyen fallbacks, pero la tableta grafica y algunos perifericos siguen dependiendo de nombres concretos de dispositivo.
