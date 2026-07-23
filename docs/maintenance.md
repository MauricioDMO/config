# Mantenimiento y validación

Esta guía sirve para revisar cambios en scripts y configuraciones sin añadir un
sistema de CI. El repositorio contiene configuraciones para Debian/i3/Zsh,
Windows/PowerShell y OpenCode; ejecuta cada comprobación en la plataforma a la
que corresponde.

## Flujo breve antes de commitear

Desde la raíz del repositorio:

```sh
git rev-parse --show-toplevel
git status --short
git diff --check
git diff
```

Antes de guardar el cambio:

1. Confirma que las rutas nuevas o modificadas existen y que los nombres
   coinciden con los que cargan `deb/init.zsh`, `deb/setup.zsh` y
   `win-main.ps1`.
2. Revisa que las variables locales correspondan a la máquina actual. En
   particular, `.env.example` solo es una plantilla; los valores reales van en
   `.env` y no deben aparecer en el diff.
3. Comprueba los enlaces simbólicos después de mover el repositorio o cambiar
   de usuario. `setup.zsh` enlaza directamente al checkout; no copia los
   archivos.
4. Revisa las diferencias por plataforma: rutas `/sys`, X11 y comandos de
   Debian no se pueden validar como si fueran PowerShell; en Windows, revisa
   `$env:USERPROFILE`, `$env:POSH_THEMES_PATH` y las rutas rápidas de `win/`.
5. Vuelve a inspeccionar `git status --short` y el diff. No uses `git add -A`
   como sustituto de esta revisión: añade solo los archivos intencionados.

## Comprobaciones de sintaxis

Estas comprobaciones no ejecutan la configuración; solo piden al intérprete que
revise la sintaxis.

### Zsh

```sh
zsh -n deb/init.zsh
```

### Shell POSIX y Bash

`deb/setup.zsh` tiene `#!/bin/sh`, aunque su nombre termine en `.zsh`; valida
ese archivo con el intérprete indicado por su shebang. Los scripts de
`i3blocks` y Thermal Guard declaran Bash.

```sh
sh -n deb/setup.zsh
for file in deb/i3blocks/scripts/*.sh deb/thermal/thermal-guard.sh; do
  bash -n "$file" || exit 1
done
```

Si `shellcheck` está instalado, es una revisión adicional útil, no un requisito
del repositorio:

```sh
shellcheck deb/setup.zsh deb/i3blocks/scripts/*.sh deb/thermal/thermal-guard.sh
```

Interpreta sus avisos junto con el entorno real. Algunos scripts dependen de
`nmcli`, `ip`, `pactl`, `notify-send`, ADB, `upower`, X11 o Wayland, y una
advertencia de herramienta externa no demuestra por sí sola que el script esté
roto.

### Configuración de i3

```sh
i3 -C -c deb/i3/config
```

Esta comprobación requiere que `i3` esté disponible. No confirma que todas las
aplicaciones invocadas por los atajos estén instaladas ni que el hardware tenga
los dispositivos esperados.

### PowerShell

No hay un validador de PowerShell ni un comando de comprobación documentado en
este repositorio. La ejecución de `win-main.ps1` tampoco es una prueba de
sintaxis aislada: carga módulos, puede inicializar `fnm` u `oh-my-posh` y el
banner consulta información del sistema.

Si PowerShell está disponible en el equipo Windows, revisa los archivos en una
sesión de prueba sin privilegios y observa los errores o advertencias al cargar
`win-main.ps1`. No lo ejecutes como administrador solo para validar sintaxis.
Si se necesita una validación sintáctica automatizada, usa el analizador de la
versión de PowerShell instalada y documenta esa herramienta en el entorno antes
de convertirla en un requisito.

## Actualizar la configuración

### Debian, i3 y Zsh

- Los cambios de `deb/init.zsh` se prueban recargando el archivo en una shell o
  abriendo una nueva shell. El archivo carga `.env` desde `../.env` si existe.
- Los cambios de destinos o de rutas se aplican volviendo a ejecutar:

  ```sh
  ./deb/setup.zsh
  ```

  Ejecuta esa orden desde la raíz del checkout; si el repositorio está en otra
  ubicación, usa la ruta correspondiente a `deb/setup.zsh`. El script crea o
  actualiza enlaces de usuario y de sistema, marca scripts como ejecutables y
  ejecuta `systemctl daemon-reload`. Termina en el primer error y no tiene
  rollback.
- Tras cambiar `deb/i3/config`, valida con `i3 -C -c ...` y recarga i3 con el
  atajo configurado `Mod+Shift+c` cuando estés en una sesión i3.
- Tras cambiar un bloque de i3blocks, comprueba su script directamente en un
  equipo Debian y verifica que los comandos y sensores que usa existan allí.
  La configuración de la barra usa rutas como `~/.config/i3blocks/scripts`.
- Tras cambiar Thermal Guard, comprueba primero la sintaxis. Si el servicio ya
  está instalado, aplica los enlaces y luego usa:

  ```sh
  sudo systemctl daemon-reload
  sudo systemctl restart thermal-guard.service
  ```

  `setup.zsh` no habilita ni inicia el servicio por sí mismo.

### Windows

`win-main.ps1` carga los módulos de `win/` en un orden fijo. Si se añade,
elimina o renombra un módulo, actualiza de forma coherente la lista
`$scriptOrder` y confirma que el archivo exista. Después de cambiar un módulo,
abre una nueva sesión de PowerShell o vuelve a cargar el perfil en la sesión de
prueba.

Revisa especialmente que las rutas rápidas bajo `$env:USERPROFILE\core` y los
comandos externos (`fnm`, `oh-my-posh`, `code`, `wt`, `FPilot.exe`, `opencode`)
sean apropiados para ese equipo. `nclean` elimina `node_modules` y varios
archivos de bloqueo del proyecto actual: úsalo solo cuando esa limpieza sea
intencionada.

### OpenCode

`opencode/opencode.json` es JSON y declara un esquema, servidores MCP locales o
remotos y un plugin. Al modificarlo, conserva JSON válido, revisa el nombre de
cada servidor, su comando o URL y si `enabled` corresponde a lo deseado. No hay
un validador local específico documentado. Si `python3` está disponible, puedes
comprobar solo la sintaxis JSON con:

```sh
python3 -m json.tool opencode/opencode.json >/dev/null
```

Esto no valida el esquema ni la disponibilidad de los servidores. Si OpenCode
está instalado, inicia una sesión de prueba y atiende cualquier error que
reporte al leer la configuración enlazada.

## Diagnóstico de enlaces y configuración

### Enlaces creados por `setup.zsh`

Comprueba que el destino resuelva a un archivo o directorio existente y que
apunte a este checkout:

```sh
readlink -e ~/.config/i3/config
readlink -e ~/.config/i3/scripts
readlink -e ~/.config/i3blocks/config
readlink -e ~/.config/i3blocks/scripts
readlink -e ~/.config/opencode
readlink -e /usr/local/bin/thermal-guard
readlink -e /etc/systemd/system/thermal-guard.service
```

Los destinos de sistema requieren permisos para inspeccionarse en algunos
entornos. Si un comando no resuelve, revisa que el origen todavía exista, que
`REPO_DIR` sea la raíz correcta y que `setup.zsh` se haya ejecutado con el
usuario objetivo esperado (`${SUDO_USER:-$USER}`). El script también crea
enlaces para XFCE, Ghostty, Kitty, `.p10k.zsh` y X11; sus destinos se detallan
en `docs/debian.md`.

Para detectar un enlace roto o un destino sustituido por un archivo normal,
inspecciona los metadatos con:

```sh
ls -ld ~/.config/i3/config ~/.config/i3blocks/config ~/.config/opencode
ls -l /usr/local/bin/thermal-guard /etc/systemd/system/thermal-guard.service
```

Después de mover el checkout, vuelve a ejecutar `setup.zsh`; editar el origen
no corrige por sí solo un enlace que apunte a una ruta antigua.

### Thermal Guard y systemd

Comprueba el estado y los registros sin modificar la política manualmente:

```sh
systemctl status thermal-guard.service
systemctl is-enabled thermal-guard.service
systemctl is-active thermal-guard.service
journalctl -u thermal-guard.service -b
```

El primer registro del servicio muestra las rutas de sensores resueltas. Si una
ruta de `/sys` no existe o no es legible, el script puede continuar con datos
incompletos; revisa ese registro antes de atribuir el problema a systemd. Las
variables `THERMAL_GUARD_*` son variables del proceso y no se cargan desde el
`.env` de la raíz mediante la unidad actual.

### i3, i3blocks y dependencias locales

Si i3 rechaza la configuración, empieza por `i3 -C -c deb/i3/config` y revisa
las rutas usadas por `exec`, `bindsym` y la sección `bar`. Comprueba después que
los enlaces `~/.config/i3/scripts` y `~/.config/i3blocks/scripts` existan y que
los scripts mantengan permiso de ejecución.

Si un bloque aparece vacío, puede ser el comportamiento previsto cuando no hay
red, batería, Bluetooth o dispositivo ADB. Para los bloques que sí deberían
mostrar datos, comprueba la herramienta correspondiente (`nmcli`, `ip`, `pactl`,
`bluetoothctl`, `adb`, `upower` o `notify-send`) y el sensor o ruta de sysfs que
lee el script.

## Archivos locales que no se versionan

No versiones secretos ni dependencias generadas o específicas de una máquina.
Las reglas actuales son:

- `.env` en la raíz: contiene valores reales derivados de `.env.example`, como
  la clave de recuperación de BitLocker, el dispositivo y el punto de montaje.
- Dentro de `opencode/`: `node_modules/`, `package.json`, `package-lock.json`,
  `bun.lock`, `.env`, los archivos `.env.*` y `*.local.json`.

`.env.example` sí se versiona y debe contener solo nombres, comentarios y
valores de ejemplo seguros. Que un archivo esté ignorado no significa que no
exista físicamente: antes de commitear revisa:

```sh
git status --short --ignored
git check-ignore -v .env opencode/node_modules opencode/package.json opencode/.env.local.json
```

Si una clave o un archivo local aparece ya rastreado por Git, quitarlo del
próximo commit no borra su historial; trátalo como una posible exposición y
revísalo antes de continuar.
