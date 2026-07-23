# Entorno Debian, i3 y Zsh

Guía canónica para instalar y mantener la configuración de `deb/`. El repositorio
aporta archivos de configuración, scripts y enlaces simbólicos; no instala por sí
mismo los paquetes externos que esos archivos utilizan.

## Qué es obligatorio y qué es opcional

### Base necesaria

- Un usuario Debian con un `HOME` válido y acceso al repositorio.
- Zsh y Oh My Zsh en `$HOME/.oh-my-zsh`. `deb/init.zsh` carga
  `$ZSH/oh-my-zsh.sh` sin una comprobación previa.
- El tema `powerlevel10k/powerlevel10k`, porque es el tema seleccionado por el
  bootstrap de Zsh.
- Las aplicaciones que se quieran usar con i3 y sus scripts: i3, i3blocks,
  Kitty o Ghostty, Rofi y las utilidades invocadas por los atajos o la barra.
  `deb/setup.zsh` no las instala.

### Componentes opcionales

- `fzf-tab`, `zsh-autosuggestions`, `zsh-history-substring-search` y
  `zsh-syntax-highlighting`. Cada uno se carga solo si existe su archivo en
  `$ZSH_CUSTOM` (o en `$HOME/.oh-my-zsh/custom`). En `init.zsh` están indicadas
  las instrucciones de instalación de `fzf-tab`, autosuggestions y history
  substring search; `fzf-tab` además requiere `fzf`.
- FNM y Bun. El bootstrap configura FNM solo si existe
  `$HOME/.local/share/fnm`; para Bun siempre define `BUN_INSTALL`, pero solo
  añade su directorio a `PATH` y carga `_bun` si existe `$HOME/.bun`.
- `pgcli`, `adb`/`scrcpy`, Wine, la tableta Wacom, BitLocker, el bloqueo con
  imágenes y las rutas rápidas. Sus funciones no son necesarias para iniciar
  Zsh, pero sí requieren sus programas, dispositivos o rutas correspondientes.
- i3, i3blocks, XFCE Power Manager, Xorg/Synaptics, Kitty, Ghostty y Rofi son
  piezas independientes del escritorio. El instalador enlaza sus archivos,
  aunque se puede usar solo el subconjunto que corresponda a la máquina.
- Thermal Guard es una integración aparte. `setup.zsh` deja preparados sus
  enlaces de sistema, pero no habilita ni arranca el servicio.

No hay un modo parcial implementado en `setup.zsh`: aunque una parte sea
opcional, el script intenta realizar también los enlaces de sistema descritos
más abajo.

## Instalación inicial

Se asume que el repositorio está en `~/.config/config`; si se ubica en otro
lugar, sustituye esa ruta en los ejemplos.

### 1. Variables locales, si hacen falta

El archivo `.env` es opcional para el resto del entorno. `deb/init.zsh` busca
automáticamente `../.env` respecto de `deb/init.zsh` y lo carga solo si existe.
No se debe versionar.

Parte de `.env.example` para definir valores específicos de la máquina:

```sh
cp .env.example .env
```

Las variables documentadas actualmente son:

| Variable | Uso |
| --- | --- |
| `BITLOCKER_KEY` | Clave de recuperación que usa `mount-win`. Es obligatoria para esa función. |
| `BITLOCKER_DEVICE` | Dispositivo de la partición de Windows; si falta, `mount-win` usa `/dev/nvme0n1p3`. |
| `BITLOCKER_MOUNT` | Punto de montaje; si falta, `mount-win` usa `/mnt/win`. |

`mount-win` abre el dispositivo con `cryptsetup` y monta la partición con
`ntfs-3g` en modo de solo lectura. Si `BITLOCKER_KEY` está vacía, informa del
error y no continúa. No definas la clave en un archivo que vaya a entrar en el
control de versiones.

La orden `cp` anterior debe ejecutarse desde la raíz del repositorio; si estás
en otro directorio, usa rutas explícitas al checkout.

### 2. Cargar Zsh

Añade la carga del bootstrap al `.zshrc` del usuario:

```zsh
source "$HOME/.config/config/deb/init.zsh"
```

Esto **carga la configuración en la shell actual**: no crea enlaces, no copia
archivos y no instala paquetes. Para probarla sin abrir una shell nueva también
se puede ejecutar ese `source` manualmente.

### 3. Aplicar enlaces

Después, ejecuta el instalador:

```sh
~/.config/config/deb/setup.zsh
```

`setup.zsh` es un instalador de enlaces, no el bootstrap de Zsh. Usa la ruta de
su propio archivo para localizar la raíz del repositorio, crea directorios de
destino cuando corresponde y aplica `ln -sfn`/`ln -sfnT`. También marca como
ejecutables los scripts de i3, i3blocks y Thermal Guard.

La ejecución termina con error en el primer fallo (`set -e`). No hay una fase de
rollback: si falla un paso posterior, los enlaces anteriores pueden haber sido
creados ya.

## `init.zsh` y `setup.zsh` no hacen lo mismo

| Archivo | Cuándo usarlo | Efecto |
| --- | --- | --- |
| `deb/init.zsh` | Al iniciar Zsh, o después de cambiar el bootstrap | Define el entorno de la shell, carga Oh My Zsh, módulos, aliases, completados y ajustes opcionales. |
| `deb/setup.zsh` | Al instalar, cambiar de máquina o mover el repositorio | Crea o actualiza enlaces simbólicos de usuario y de sistema. No carga funciones en la shell. |

Cambiar `deb/init.zsh` no actualiza por sí solo `~/.p10k.zsh`, i3 ni los demás
destinos: esos destinos dependen de los enlaces de `setup.zsh`. Del mismo modo,
ejecutar `setup.zsh` no hace que una shell ya abierta conozca cambios de Zsh;
recarga `init.zsh` o abre otra shell.

## Orden conceptual de carga de Zsh

El orden real de `deb/init.zsh` es importante:

1. Calcula `DEB_CONFIG_DIR` a partir de la ubicación del script y busca
   `../.env`.
2. Define `ZSH`, el tema Powerlevel10k y los plugins de Oh My Zsh (`git`,
   `sudo`, `z`, `extract`, `colored-man-pages` y `command-not-found`); después
   carga `oh-my-zsh.sh`.
3. Carga de forma condicional `fzf-tab`, `zsh-autosuggestions` y
   `zsh-history-substring-search`. Si está disponible este último, las flechas
   arriba/abajo buscan por el texto ya escrito; si no, se comportan como
   navegación normal del historial.
4. Configura edición, pegado entre corchetes, `bindkey -e`, movimiento y
   borrado por palabras.
5. Carga `~/.zprofile` si existe.
6. Carga los módulos propios, en este orden: `utils`, `banner`, `navigation`,
   `services`, `node`, `size`, `help`, `alias`, `graphic-tablet` y `wine`.
7. Configura FNM si su directorio existe; prepara Bun y solo añade sus rutas si
   `$HOME/.bun` existe. Después ajusta `LS_COLORS` y crea el alias `pg` si
   `pgcli` está disponible.
8. Carga `zsh-syntax-highlighting` **al final**, si está instalado. No se carga
   como plugin de Oh My Zsh para conservar este orden.

El banner solo se muestra en una shell interactiva y cuando
`CONFIG_HIDE_BANNER` está vacío. Los lanzadores de terminal usan esa variable
para abrir shells sin banner cuando corresponde.

### Módulos principales

- `utils.zsh`: colores, ancho de terminal, encabezados, divisores, elementos de
  salida y conversión de bytes.
- `banner.zsh`: banner con Figlet, fecha y sistema operativo.
- `navigation.zsh`: `core`, `dev`, `learn`, `uni`, `work`, `c`, `dps`, `e` y
  `r`; las rutas rápidas apuntan a `$HOME/core` y sus subdirectorios.
- `services.zsh`: `essh`, `svc`, `lock-laptop`, `mount-win` y `umount-win`.
  `svc` usa `sudo systemctl` para los servicios registrados.
- `node.zsh`: `nd clean`, `nd check`, `nd scripts` y `nd pkg`; `nd scripts` y
  `nd pkg` requieren un `package.json` en el directorio actual.
- `size.zsh`: muestra tamaño, cantidad de archivos y los cinco archivos más
  grandes de una ruta.
- `help.zsh`: `myhelp`/`help_config`, con el resumen de comandos disponibles.
- `alias.zsh`: aliases de sistema, red, audio, `lsd`, `apt-uninstall` y la
  función `phone` para ADB y scrcpy.
- `graphic-tablet.zsh`: `tablet_setup` y `tablet_focus`, con validaciones de
  `xsetwacom`, `xrandr`, salidas conectadas y dispositivos LetSketch concretos.
- `wine.zsh`: `wn` para perfiles, launchers, `winecfg`, `winetricks` y
  ejecución de aplicaciones; su ayuda remite a `deb/Docs/wn.md`.

Al migrar a otro equipo hay que revisar especialmente `$HOME/core`, el nombre
de los dispositivos de la tableta, la dirección Bluetooth usada por `buds` y
las rutas absolutas del lanzador de Kitty en `deb/i3/scripts`. Si el checkout no
está en `~/.config/config`, revisa también la ruta fija al tema de Rofi en
`deb/i3/config`.

## Enlaces que crea `setup.zsh`

Las flechas indican que el destino apunta al archivo o directorio dentro del
repositorio. `REPO_DIR` es la raíz del repositorio detectada por el script.

### Enlaces del usuario (`TARGET_HOME`)

Estos enlaces se crean para `TARGET_USER`:

| Destino | Origen |
| --- | --- |
| `~/.config/i3/config` | `REPO_DIR/deb/i3/config` |
| `~/.config/i3/scripts` | `REPO_DIR/deb/i3/scripts` |
| `~/.config/i3blocks/config` | `REPO_DIR/deb/i3blocks/config` |
| `~/.config/i3blocks/scripts` | `REPO_DIR/deb/i3blocks/scripts` |
| `~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml` | `REPO_DIR/deb/xfce4/xfce4-power-manager.xml` |
| `~/.p10k.zsh` | `REPO_DIR/deb/terminal/.p10k.zsh` |
| `~/.config/ghostty/config` | `REPO_DIR/deb/ghostty/config` |
| `~/.config/ghostty/themes` | `REPO_DIR/deb/ghostty/themes` (el origen no existe actualmente; el enlace queda roto) |
| `~/.config/kitty/kitty.conf` | `REPO_DIR/deb/kitty/kitty.conf` |
| `~/.config/opencode` | `REPO_DIR/opencode` |

Los directorios padre de i3, i3blocks, XFCE, Ghostty, Kitty y
`~/.config` se crean cuando el script los necesita. La tabla incluye el enlace
de OpenCode porque el instalador lo crea, pero esa configuración queda fuera de
esta guía.

**Advertencia sobre Ghostty:** en el estado actual no existe
`deb/ghostty/themes`, aunque `setup.zsh` intenta enlazarlo y `config` selecciona
el tema `rofi-adi1090x`. Proporciona ese tema por separado o no consideres
válido ese enlace; esta guía no afirma que el instalador lo suministre.

### Enlaces del sistema (root)

Estos destinos requieren permisos de root:

| Destino | Origen |
| --- | --- |
| `/etc/X11/xorg.conf.d/70-synaptics.conf` | `REPO_DIR/deb/X11/70-synaptics.conf` |
| `/usr/local/bin/thermal-guard` | `REPO_DIR/deb/thermal/thermal-guard.sh` |
| `/etc/systemd/system/thermal-guard.service` | `REPO_DIR/deb/thermal/thermal-guard.service` |

Al final de esa parte, `setup.zsh` ejecuta `systemctl daemon-reload`. Eso solo
recarga las unidades conocidas por systemd; no ejecuta
`enable`, `start` ni `enable --now`.

## `sudo`, usuario objetivo y consecuencias

El script separa las operaciones mediante dos funciones:

- `as_root`: ejecuta directamente si ya es root; en caso contrario antepone
  `sudo`.
- `as_user`: si el proceso es root, ejecuta como `TARGET_USER` con
  `HOME=TARGET_HOME`; si no es root, ejecuta directamente con el usuario
  actual.

`TARGET_USER` se calcula como `${SUDO_USER:-$USER}` y su HOME se obtiene con
`getent passwd`. Por tanto:

1. **Ejecución normal:** `TARGET_USER` es el usuario actual. Los enlaces de
   usuario se crean en su HOME y los pasos de `/etc`, `/usr/local` y
   `systemctl` intentan pedir autorización mediante `sudo`.
2. **Ejecución con `sudo`:** si se invoca desde una sesión del usuario, el
   valor `SUDO_USER` conserva a ese usuario como objetivo. Los enlaces de
   usuario no deberían terminar en `/root`; las operaciones de sistema se
   ejecutan con privilegios.
3. **Ejecución como root sin `SUDO_USER`:** `TARGET_USER` puede ser `root`, de
   modo que también los enlaces clasificados como de usuario pueden acabar en
   `/root`. Es una consecuencia importante de ejecutar el script desde una
   sesión root directa o con un cambio de usuario que no conserve `SUDO_USER`.

Usa `sudo` cuando necesites instalar los enlaces de X11, Thermal Guard y la
unidad systemd. Si la cuenta no puede usar `sudo`, `setup.zsh` puede haber
creado ya los enlaces de usuario antes de fallar en la primera operación de
sistema. No hay una opción observada para omitir solo esa parte.

## Qué instala cada configuración

### i3 e i3blocks

`deb/i3/config` define i3 con Mod4 como tecla principal, lanzadores para Kitty,
Rofi, Brave, VS Code, Obsidian y Dolphin, controles multimedia y de brillo,
atajos de trackpad, capturas, teclado US/Latam, navegación Vim de ventanas,
workspaces 1–6, multi-monitor y autostart de servicios del escritorio.

La barra usa i3blocks y `deb/i3blocks/config` actualiza:

- Wi-Fi y Ethernet cada 5 segundos;
- batería del teléfono por ADB cada 10 segundos;
- Bluetooth cada 5 segundos;
- batería del equipo cada 10 segundos;
- modo de energía y CPU/temperatura cada 5 segundos;
- memoria cada 5 segundos;
- volumen por señal, y fecha cada segundo.

Los scripts tienen validaciones o salidas vacías para varios casos sin
dispositivo. Algunos comportamientos dependen de herramientas externas: por
ejemplo, NetworkManager (`nmcli`), `ip`, `pactl`, `notify-send`, ADB, `upower`,
`wl-copy`/`xclip`/`xsel` y los comandos de X11. El bloque de CPU/temperatura
recibe por configuración `/sys/class/thermal/thermal_zone5/temp`; ese path
puede no existir en otra máquina y el script muestra temperatura cero si no es
legible.

Los clics de la barra también tienen efecto: el bloque de volumen abre
`pavucontrol`, cambia mute o volumen; Wi-Fi y Ethernet intentan copiar la IP al
portapapeles; y el resto muestra estado.

### Terminales, prompt y Rofi

- Kitty usa Cascadia Code, opacidad `0.92`, control remoto por socket y atajos
  para tamaño de fuente, scrollback, copiar/pegar y borrar palabras.
- Ghostty usa Cascadia Code, el tema `rofi-adi1090x`, opacidad `0.92`, desenfoque
  y atajos equivalentes para búsqueda, portapapeles y navegación por palabras.
- `.p10k.zsh` configura Powerlevel10k con prompt de dos líneas, icono del
  sistema, directorio, estado Git, estado del último comando y otros segmentos
  opcionales.
- `rofi/theme.rasi` define el tema verde/gris, búsqueda centrada, iconos y dos
  columnas de resultados.

### X11 y XFCE

- `70-synaptics.conf` configura toque con uno/dos/tres dedos, desplazamiento en
  dos dedos, desplazamiento natural e inercia para el driver Synaptics. Es un
  archivo de sistema y por eso se enlaza en `/etc/X11`.
- `xfce4-power-manager.xml` activa la restauración del brillo, configura la
  acción de tapa y mantiene el bloqueo de pantalla al suspender o hibernar.

## Validaciones disponibles

Antes de guardar cambios, el repositorio ya contempla estas comprobaciones:

```sh
zsh -n deb/init.zsh
for file in deb/lib/*.zsh; do zsh -n "$file" || exit 1; done
sh -n deb/setup.zsh
for file in deb/i3blocks/scripts/*.sh deb/thermal/thermal-guard.sh; do
  bash -n "$file" || exit 1
done
i3 -C -c deb/i3/config
```

Si está disponible `shellcheck`, puede usarse como comprobación adicional sobre
los scripts `.sh`; no es un requisito del instalador. Las validaciones internas
más relevantes son:

- `setup.zsh` comprueba que puede resolver `TARGET_HOME`; si no existe o no es
  un directorio, termina con error.
- `phone` comprueba `adb`, `scrcpy` y el estado del dispositivo.
- `tablet_setup` y `tablet_focus` comprueban `xsetwacom`, `xrandr`, pantallas y
  dispositivos esperados.
- `nd scripts` y `nd pkg` requieren `package.json`.
- `size` rechaza una ruta inexistente.
- `mount-win` rechaza una `BITLOCKER_KEY` vacía.

## Mantenimiento y servicio térmico

Como `setup.zsh` enlaza directamente al repositorio, editar un archivo fuente
actualiza el contenido visto por el destino; aun así, las aplicaciones pueden
necesitar recargar su configuración. Al mover el repositorio o cambiar el
usuario, vuelve a ejecutar el instalador para que los enlaces apunten a la ruta
correcta.

Para el servicio térmico, consulta [`thermal-guard.md`](thermal-guard.md). Para
la revisión periódica de enlaces, permisos y validaciones, consulta
[`maintenance.md`](maintenance.md).

No se detalla aquí la política térmica, Wine, Windows ni OpenCode; esta guía se
limita al entorno Debian/i3/Zsh y al instalador de enlaces.
