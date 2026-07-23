# `wn`: perfiles y launchers de Wine

`wn` administra perfiles Wine por aplicación y genera un `init.sh` para
ejecutar juegos o aplicaciones. Cada perfil se guarda en:

```text
~/wineprefixes/<nombre-normalizado>
```

El nombre se convierte a minúsculas, los espacios pasan a ser `-` y se
eliminan los caracteres que no sean letras ASCII, números, `.`, `_` o `-`.
Si el resultado queda vacío, se usa `app`.

## Uso rápido

Para un juego RPG Maker MV o una aplicación NW.js:

```bash
cd /ruta/al/juego
wn create elise ./Game.exe
./init.sh
```

`create` inicializa el perfil con `wineboot -u` cuando todavía no está
inicializado (no contiene `system.reg` ni `drive_c`), usa `WINEARCH=win64` y
crea `init.sh` en el directorio actual. El launcher
también puede ejecutarse desde otra carpeta porque primero vuelve a su propio
directorio.

## Comandos

```text
wn list
wn create <nombre> [exe] [--type auto|generic|nwjs]
wn init <nombre> [exe] [--type auto|generic|nwjs]
wn info [init.sh]
wn run <nombre> <exe> [args...]
wn cfg|config <nombre>
wn tricks <nombre> <paquetes...>
wn boot <nombre>
wn remove|rm <nombre>
```

`wn`, `wn help`, `wn -h` y `wn --help` muestran la ayuda breve. El
autocompletado de acciones ofrece `list`, `create`, `init`, `info`, `run`,
`cfg`, `tricks`, `boot`, `remove` y `help`. Para `init`, `run`, `cfg`,
`tricks`, `boot` y `remove` completa perfiles en el segundo argumento; para
`info` completa archivos. Los demás argumentos se completan como archivos. En
particular, los paquetes de `wn tricks` no se autocompletan como verbos de
Winetricks.

El comando independiente `winetricks` sí tiene autocompletado de verbos:
consulta `winetricks list-all` cuando está disponible y también busca nombres
de directorios en `~/.cache/winetricks`, `~/.local/share/winetricks`,
`/usr/share/winetricks` y `/usr/lib/winetricks`.

### `wn list`

Lista los perfiles detectados en `~/wineprefixes`, junto con su tamaño y ruta.
Solo se consideran perfiles los directorios que contienen `drive_c` o
`system.reg`.

Si la carpeta raíz no existe o no contiene perfiles, muestra un aviso y
termina sin error.

### `wn create`

Crea o conserva el perfil y escribe `./init.sh` en el directorio actual:

```bash
wn create elise ./Game.exe
wn create elise
wn create elise ./Game.exe --type generic
wn create elise ./Game.exe --type=nwjs
```

El ejecutable es opcional. Si se omite, el launcher se crea sin `APP_EXE` y
no podrá ejecutarse hasta regenerarlo con `wn init <nombre> <exe>`.

Si ya existe `init.sh`, `wn` pide confirmación antes de sobrescribirlo. Wine
debe estar instalado y disponible en `PATH`; de lo contrario, `create` falla.

### `wn init`

Genera o regenera `./init.sh` para un perfil existente:

```bash
wn init elise ./Game.exe
wn init elise ./Game.exe --type nwjs
```

No crea el perfil. Si no existe, muestra el error correspondiente y sugiere
`wn create <nombre>`. También pide confirmación antes de reemplazar un
`init.sh` existente.

Si se omite `exe`, regenera el launcher sin `APP_EXE`; para que vuelva a
ejecutar una aplicación hay que indicar el ejecutable al regenerarlo.

`--type` acepta `auto`, `generic` o `nwjs`, tanto en la forma
`--type valor` como en `--type=valor`. Cualquier otro valor o argumento no
reconocido es un error.

### Tipos de launcher

| Tipo | Comportamiento |
| --- | --- |
| `auto` | Detecta el tipo al generar el launcher. |
| `generic` | Fuerza un launcher sin flags adicionales. |
| `nwjs` | Fuerza un launcher con flags para desactivar GPU y decodificación de vídeo acelerada. |

En modo `auto`, se detecta `nwjs` si el directorio del ejecutable contiene
señales de NW.js/RPG Maker MV: `www/` junto con `www/js/`, `www/data/`,
`www/package.json` o un ejecutable llamado `Game.exe`; o `package.json`
junto con `nw.pak`, `icudtl.dat`, `locales/` o `Game.exe`. En cualquier otro
caso se usa `generic`.

Un launcher `nwjs` ejecuta Wine con estos flags, antes de los argumentos
adicionales que se pasen a `init.sh`:

```text
--disable-gpu
--disable-gpu-compositing
--disable-accelerated-video-decode
```

### `init.sh` generado

El archivo generado:

- exporta `WINEPREFIX` y `WINEARCH=win64`;
- entra en el directorio que contiene `init.sh`;
- comprueba la existencia del ejecutable cuando puede hacerlo desde Linux;
- ejecuta `wine` y conserva los argumentos adicionales (`./init.sh --debug`,
  por ejemplo).

Si no tiene ejecutable, termina con un mensaje que indica regenerarlo con
`wn init <perfil> <exe>`. Si una ruta Linux o relativa no existe, informa que
no encontró `APP_EXE` en el directorio del launcher y termina sin ejecutar
Wine.

### Rutas de `exe`

El launcher reconoce estas formas de `APP_EXE`:

| Forma | Ejemplo | Destino |
| --- | --- | --- |
| Relativa al launcher | `./Game.exe` | Se busca respecto al directorio de `init.sh`. |
| Linux absoluta | `/home/user/game/Game.exe` | Se usa tal cual. |
| Relativa dentro del perfil | `drive_c/Program Files/App/app.exe` | Se antepone `$WINEPREFIX/`. |
| Windows/Wine | `C:\Program Files\App\app.exe` o `C:/App/app.exe` | Se pasa directamente a Wine. |

Las rutas Linux y relativas deben existir para que el launcher continúe. Las
rutas Windows no se pueden verificar desde Linux y se entregan directamente a
Wine.

### `wn info`

Inspecciona un launcher; por defecto usa `./init.sh`:

```bash
wn info
wn info ./init.sh
wn info /ruta/al/juego/init.sh
```

Muestra la ruta del launcher, el `WINEPREFIX`, si el perfil existe,
`WINEARCH`, el tipo de launcher, `APP_EXE`, la clase de ruta, el destino, si
el ejecutable existe y los flags activos. Para una ruta Windows indica que la
existencia no es verificable desde Linux.

Si el archivo no existe, muestra `No existe init.sh` y termina con error.

### `wn run`

Ejecuta un programa directamente con `WINEPREFIX` y `WINEARCH=win64` del
perfil:

```bash
wn run elise ./setup.exe
wn run elise ./Game.exe --debug
```

El perfil debe existir y se requieren tanto el nombre como el ejecutable.
`run` no añade automáticamente los flags de NW.js; para esos juegos usa el
`init.sh` generado.

### `wn cfg` / `wn config`

Abre `winecfg` para un perfil existente:

```bash
wn cfg elise
wn config elise
```

### `wn tricks`

Ejecuta `winetricks -q` dentro del perfil para instalar uno o más paquetes:

```bash
wn tricks elise vcrun2019 dxvk corefonts
```

Se requiere al menos un paquete, `winetricks` debe estar disponible en
`PATH` y el perfil debe existir.

### `wn boot`

Ejecuta `wineboot -u` con `WINEPREFIX` y `WINEARCH=win64`:

```bash
wn boot elise
```

Si la carpeta del perfil no existe, `boot` la crea antes de ejecutar
`wineboot`.

### `wn remove` / `wn rm`

Elimina permanentemente el perfil normalizado después de pedir confirmación:

```bash
wn remove elise
wn rm elise
```

Solo borra `~/wineprefixes/<nombre-normalizado>`. No elimina los archivos
`init.sh` que estén fuera del perfil. Si el perfil no existe, muestra un
aviso y termina con error; responder negativamente cancela la operación.

## Errores habituales de `wn`

- **`Wine no está instalado o no está en PATH.`**: `create` no puede
  continuar.
- **`winetricks no está instalado o no está en PATH.`**: `tricks` no puede
  continuar.
- **`No existe el perfil: <nombre>`**: `init`, `run`, `cfg`, `tricks` o una
  operación equivalente recibió un perfil que no existe.
- **`Falta valor para --type.`**: se escribió `--type` sin su valor.
- **`Tipo inválido: ...`**: el tipo no es `auto`, `generic` ni `nwjs`.
- **`No se encontró APP_EXE ...`**: el launcher apunta a una ruta Linux o
  relativa que no existe.

Para regenerar un launcher incompleto:

```bash
wn init <perfil> /ruta/al/ejecutable.exe
```

Otros errores observables:

- **`Uso: wn ...`**: falta un argumento obligatorio, por ejemplo el nombre
  del perfil, el ejecutable de `run` o un paquete de `tricks`.
- **`Argumento no reconocido: ...`**: `create` o `init` recibió una opción no
  admitida.
- **`Acción no válida: ...`**: la acción no existe; después se muestra la
  ayuda de `wn`.
- **`Falló wineboot. Revisa tu instalación de Wine.`**: Wine no pudo
  inicializar el perfil durante `create`.

Cancelar una confirmación no es un error: al no aceptar la sobrescritura de
`init.sh` se muestra `No se sobrescribió init.sh.`, y al cancelar `remove` se
muestra `Operación cancelada.`. Los alias `config` y `rm` se aceptan, pero el
autocompletado solo ofrece las acciones canónicas `cfg` y `remove`.
