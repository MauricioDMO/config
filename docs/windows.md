# Configuración de PowerShell en Windows

Esta guía describe el bootstrap `win-main.ps1` y los scripts de `win/`. Está
pensada para PowerShell 7 o posterior.

## Ubicar el repositorio

El repositorio puede estar en cualquier carpeta, siempre que conserve esta
estructura mínima:

```text
<repositorio>/
├── win-main.ps1
└── win/
    ├── init.ps1
    ├── utils.ps1
    ├── size.ps1
    ├── navigation.ps1
    ├── services.ps1
    ├── node.ps1
    ├── help.ps1
    └── banner.ps1
```

El bloque recomendado para `$PROFILE` usa esta ruta como fallback:

```text
$HOME\.config\config
```

Por tanto, la instalación convencional deja el bootstrap en
`$HOME\.config\config\win-main.ps1`. Para usar otra ubicación, define
`PWSH_CONFIG_HOME` como la **raíz del repositorio** (no como la carpeta `win`):

```powershell
[Environment]::SetEnvironmentVariable(
    'PWSH_CONFIG_HOME',
    'C:\ruta\a\config',
    'User'
)
```

La asignación persistente se aplica a las nuevas sesiones de PowerShell; en la
sesión actual también puedes usar `$env:PWSH_CONFIG_HOME = 'C:\ruta\a\config'`.
`win-main.ps1` no lee `PWSH_CONFIG_HOME` directamente. Esa variable solo la
usa el bloque del perfil para encontrar el archivo; una vez cargado, el
bootstrap calcula sus propias rutas a partir de la ubicación de
`win-main.ps1`.

## Cargar desde `$PROFILE`

Abre el perfil de la sesión:

```powershell
notepad $PROFILE
```

Añade este bloque:

```powershell
$ConfigHome = $env:PWSH_CONFIG_HOME
if ([string]::IsNullOrWhiteSpace($ConfigHome)) {
    $ConfigHome = Join-Path $HOME '.config\config'
}

$Bootstrap = Join-Path $ConfigHome 'win-main.ps1'
if (Test-Path $Bootstrap) {
    . $Bootstrap
} else {
    Write-Warning "No se encontró: $Bootstrap"
}
```

El punto delante de `$Bootstrap` hace *dot-sourcing*: las funciones y alias
quedan disponibles en la sesión actual. Si el bootstrap no existe, el perfil
solo muestra la advertencia y no intenta cargar la configuración; PowerShell
continúa iniciando sin estos comandos.

## Orden de carga

`win-main.ps1` aplica `Set-StrictMode -Version Latest` y establece
`$ErrorActionPreference = 'Stop'`. Después busca cada archivo dentro de `win/`
en este orden:

1. `init.ps1`: inicialización de módulos, `fnm`, el prompt y `pg`.
2. `utils.ps1`: utilidades de salida y conversión de tamaños.
3. `size.ps1`: `Get-Size` y `size`.
4. `navigation.ps1`: rutas rápidas y atajos de navegación.
5. `services.ps1`: SSH Agent, Terminal-Icons y otros comandos del sistema.
6. `node.ps1`: comandos para proyectos Node.js.
7. `help.ps1`: el catálogo `commands`.
8. `banner.ps1`: define `Show-Name` y lo ejecuta inmediatamente.

El orden está fijado en `$scriptOrder`; los archivos no se cargan por orden
alfabético. Si falta uno, el bootstrap muestra `Archivo no encontrado: ...` y
continúa. Si uno produce un error al cargarse, lo captura, muestra el mensaje
en rojo y continúa con el siguiente.

## Comandos

### Navegación

| Comando | Uso y comportamiento |
| --- | --- |
| `core [ruta]` | Va a `$env:USERPROFILE\core` o a una ruta relativa dentro de ella. |
| `dev [ruta]` | Va a `$env:USERPROFILE\core\dev` o a una ruta relativa dentro de ella. |
| `uni [ruta]` | Va a `$env:USERPROFILE\core\university` o a una ruta relativa dentro de ella. |
| `work [ruta]` | Va a `$env:USERPROFILE\core\work` o a una ruta relativa dentro de ella. |
| `learn [ruta]` | Va a `$env:USERPROFILE\core\learn` o a una ruta relativa dentro de ella. |
| `e [ruta]` | Ejecuta `FPilot.exe`; usa `.` si no se proporciona una ruta. |
| `c [ruta]` | Ejecuta `code`; usa `.` si no se proporciona una ruta. |
| `dps [ruta]` | Abre una pestaña nueva de Windows Terminal en la ruta resuelta; usa `.` por defecto. |
| `x` | Sale de la sesión de PowerShell. |

Las cinco rutas rápidas tienen autocompletado de directorios. Si una ruta
rápida no existe, se muestra un mensaje y no se cambia de ubicación. En
particular, `e` abre File Pilot mediante `FPilot.exe`; no usa el Explorador de
archivos, aunque esa es la descripción que aparece en `commands`.

### Node.js y proyectos

| Comando | Comportamiento |
| --- | --- |
| `nclean` | En la carpeta actual intenta eliminar de forma forzada `node_modules`, `package-lock.json`, `pnpm-lock.yaml` y `yarn.lock` cuando existen; no implementa una confirmación propia. |
| `ncheck` | Muestra las versiones de Node.js, npm, pnpm y bun. Si hay un `package.json` en la carpeta actual, también muestra `name`, `version` y `description` cuando están definidos. |
| `nscripts` | Lee el `package.json` actual y lista sus scripts. Informa si no existe el archivo o si no contiene scripts. |

`ncheck` marca como `Not installed` los runtimes cuya ejecución de versión no
devuelve resultado o produce una excepción. Los tres comandos trabajan
respecto de la carpeta actual; no buscan proyectos en otras rutas.

### Sistema y utilidades

| Comando | Comportamiento |
| --- | --- |
| `essh` | Obtiene el servicio `ssh-agent`, lo deja con inicio `Manual` si hace falta y lo inicia si no está ejecutándose. |
| `ti` | Carga el módulo `Terminal-Icons` si todavía no está cargado e informa el resultado. |
| `size [ruta]` | Muestra el tamaño, cantidad de archivos y carpetas y, para directorios, hasta los cinco archivos más grandes. Usa `.` por defecto y acepta archivos o directorios. |
| `Get-Size [ruta]` | Devuelve el objeto de datos que usa `size`, con ruta, bytes, tamaño legible, conteos, archivos principales e indicador de si la ruta es un archivo. |
| `sexo` | Abre `https://cornhub.website/` mediante `Start-Process`. |
| `commands` | Muestra el catálogo agrupado de comandos. |
| `o` | Alias definido por `services.ps1` para `opencode`. |
| `oc` | Función que ejecuta `opencode -c`. |

Además, `init.ps1` define condicionalmente el alias `pg` hacia `pgcli`: solo
se crea cuando `pgcli` está disponible. `o` y `oc` no son equivalentes: uno es
un alias y el otro una función que añade `-c`.

Las funciones `Convert-Size`, `_Go`, `Write-HostCentered`, `Write-Header`,
`Write-Item`, `Write-Category` y `Write-Divider` son utilidades internas para
las salidas de los demás scripts. `Show-Name` también se ejecuta de forma
automática al cargar `banner.ps1`, por lo que el inicio muestra el arte ASCII
y la fecha.

El catálogo `commands` no es una inspección automática de la sesión: está
escrito manualmente. Por eso no incluye `x`, `Get-Size`, `pg` ni las utilidades
internas, y algunas descripciones pueden no reflejar todos los detalles del
comportamiento real.

## Rutas personales y dependencias opcionales

- Cambia `$script:QuickPaths` en `win/navigation.ps1` si tus carpetas no están
  bajo `$env:USERPROFILE\core`.
- `CompletionPredictor` se importa solo si el módulo está instalado.
- `fnm` se inicializa solo si el comando existe.
- `oh-my-posh` se inicializa solo si el comando existe y usa
  `$env:POSH_THEMES_PATH/froczh.omp.json` como tema.
- `PSReadLine` se configura solo si el módulo está disponible.
- `pgcli` habilita el alias `pg` únicamente cuando el comando se encuentra.
- `Terminal-Icons` es necesario para que `ti` pueda cargar el módulo.
- `FPilot.exe`, `code` y `wt` deben estar disponibles para que funcionen `e`,
  `c` y `dps`, respectivamente.
- `opencode` debe estar disponible para que funcionen el alias `o` y la función
  `oc`.
- El servicio `ssh-agent` debe existir para que `essh` pueda consultarlo y
  arrancarlo.
- `ncheck` intenta ejecutar `node`, `npm`, `pnpm` y `bun`; los que no estén
  disponibles se muestran como `Not installed`.
- `ncheck` y `nscripts` dependen de un `package.json` válido en la carpeta
  actual para mostrar información del proyecto.

El banner consulta información de Windows mediante
`Get-CimInstance Win32_OperatingSystem`. El script asigna esa información, pero
no la muestra en el banner actual.

## Diagnóstico y mantenimiento

1. Comprueba qué ruta resolverá el perfil y si existe el bootstrap:

   ```powershell
   $ConfigHome = if ([string]::IsNullOrWhiteSpace($env:PWSH_CONFIG_HOME)) {
       Join-Path $HOME '.config\config'
   } else {
       $env:PWSH_CONFIG_HOME
   }
   $Bootstrap = Join-Path $ConfigHome 'win-main.ps1'
   Test-Path $Bootstrap
   ```

2. Si `Test-Path` devuelve `False`, corrige `PWSH_CONFIG_HOME` o coloca el
   repositorio en `$HOME\.config\config`. El cargador del perfil mostrará una
   advertencia cuando no encuentre el archivo.

3. Para volver a cargar los cambios en la sesión actual, ejecuta el bloque de
   carga o, directamente, `. $Bootstrap`. Los errores de un módulo se muestran
   durante la carga con el nombre del archivo afectado.

4. Si faltan comandos opcionales, comprueba las mismas condiciones que usa
   `init.ps1`:

   ```powershell
   Get-Module -ListAvailable -Name CompletionPredictor
   Get-Module -ListAvailable -Name PSReadLine
   Get-Command fnm, oh-my-posh, pgcli -ErrorAction SilentlyContinue
   ```

   Para las otras dependencias externas, puedes comprobar lo que usan los
   comandos directamente:

   ```powershell
   Get-Command FPilot.exe, code, wt, opencode -ErrorAction SilentlyContinue
   Get-Module -ListAvailable -Name Terminal-Icons
   Get-Service ssh-agent -ErrorAction SilentlyContinue
   ```

5. Al mantener la configuración, actualiza `$script:QuickPaths` para tus rutas
   personales y conserva los nombres de `$scriptOrder` junto con los archivos
   correspondientes en `win/`. Un archivo nuevo no se carga automáticamente:
   debe aparecer en esa lista.
