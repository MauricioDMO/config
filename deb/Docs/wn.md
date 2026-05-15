# wn - Gestor Simple De Wine

`wn` administra perfiles Wine por aplicación usando una interfaz corta, parecida a `nd` y `svc`.

Los perfiles viven en:

```bash
~/wineprefixes/<perfil>
```

Cada perfil es un `WINEPREFIX` independiente. Esto permite instalar dependencias con `winetricks`, ejecutar programas y borrar una app sin romper otras.

## Comandos

```bash
wn list
wn create <perfil> [exe] [--type auto|generic|nwjs]
wn init <perfil> [exe] [--type auto|generic|nwjs]
wn info [init.sh]
wn run <perfil> <exe> [args...]
wn cfg <perfil>
wn tricks <perfil> <paquetes...>
wn boot <perfil>
wn remove <perfil>
```

## Perfiles

Un perfil Wine es una carpeta con un Windows falso dentro:

```text
~/wineprefixes/elise/
  drive_c/
  system.reg
  user.reg
  userdef.reg
```

Recomendación: usa un perfil por juego o app importante.

No es necesario tener un `winetricks` por app. `winetricks` es solo la herramienta que instala dependencias dentro de un `WINEPREFIX`.

## wn list

Lista los perfiles encontrados en `~/wineprefixes` y su tamaño.

```bash
wn list
```

Ejemplo:

```text
elise : 1.4G  /home/mauriciodmo/wineprefixes/elise
```

## wn create

Crea un perfil nuevo y siempre genera `init.sh` en el directorio actual.

```bash
wn create elise ./Game.exe
```

Hace esto:

- Crea `~/wineprefixes/elise`.
- Inicializa el prefix con `wineboot -u` si no existe.
- Usa `WINEARCH=win64`.
- Genera `./init.sh`.
- Detecta automáticamente si la app parece NW.js/RPG Maker MV.
- Si detecta NW.js/RPG Maker MV, agrega flags contra errores de GPU/Chromium en Wine.

También puedes crear el prefix sin exe todavía:

```bash
wn create elise
```

Luego puedes regenerar el launcher:

```bash
wn init elise ./Game.exe
```

## wn init

Genera o regenera `init.sh` para un perfil existente.

```bash
wn init elise ./Game.exe
```

No crea el perfil. Si el perfil no existe, usa primero:

```bash
wn create elise
```

## Tipos De Launcher

`wn` soporta tres tipos:

| Tipo | Qué hace |
|---|---|
| `auto` | Detecta automáticamente el tipo de app. Es el default. |
| `generic` | Launcher normal sin flags extra. |
| `nwjs` | Launcher para NW.js/RPG Maker MV con flags de GPU/video. |

Uso normal:

```bash
wn create elise ./Game.exe
```

Forzar launcher genérico:

```bash
wn init elise ./Game.exe --type generic
```

Forzar launcher NW.js/RPG Maker MV:

```bash
wn init elise ./Game.exe --type nwjs
```

## Detección NW.js / RPG Maker MV

`wn` marca una app como `nwjs` si encuentra señales típicas en la carpeta del exe:

- `www/`
- `www/js/`
- `www/data/`
- `www/package.json`
- `package.json`
- `nw.pak`
- `icudtl.dat`
- `locales/`
- `Game.exe`

Esto cubre muchos juegos RPG Maker MV y apps NW.js.

Cuando el tipo es `nwjs`, `init.sh` ejecuta Wine con:

```bash
--disable-gpu
--disable-gpu-compositing
--disable-accelerated-video-decode
```

Estos flags ayudan con errores como:

```text
Failed to create surface
Lost UI shared context
dxva_video_decode_accelerator_win.cc
ContextResult::kFatalFailure
```

## init.sh Generado

El launcher generado hace esto:

- Exporta `WINEPREFIX`.
- Exporta `WINEARCH`.
- Guarda `WN_APP_TYPE`.
- Entra a la carpeta donde vive `init.sh` antes de ejecutar.
- Verifica que el exe exista cuando es una ruta Linux o relativa.
- Pasa flags NW.js si corresponde.
- Pasa tus argumentos extra al final.

Esto permite ejecutar el launcher desde cualquier carpeta:

```bash
/ruta/al/juego/init.sh
```

Y también desde la carpeta del juego:

```bash
./init.sh
```

## Rutas Soportadas

`APP_EXE` puede ser:

| Forma | Ejemplo | Cómo se interpreta |
|---|---|---|
| Relativa al `init.sh` | `./Game.exe` | Se busca junto al `init.sh`. |
| Absoluta Linux | `/home/user/game/Game.exe` | Se usa tal cual. |
| Dentro del prefix | `drive_c/Program Files/App/app.exe` | Se convierte a `$WINEPREFIX/drive_c/...`. |
| Windows/Wine | `C:\Program Files\App\app.exe` | Se pasa directo a Wine. |

Para juegos RPG Maker MV/NW.js, normalmente usa:

```bash
wn create elise ./Game.exe
```

Y ejecuta con:

```bash
./init.sh
```

## wn info

Inspecciona un `init.sh`.

```bash
wn info
wn info ./init.sh
wn info /ruta/a/init.sh
```

Muestra:

- Ruta del `init.sh`.
- `WINEPREFIX` asociado.
- Si el prefix existe.
- `WINEARCH`.
- Tipo de launcher: `generic` o `nwjs`.
- `APP_EXE`.
- Tipo de ruta del exe.
- Ruta que se ejecutará.
- Si el exe existe.
- Flags activas.

## wn run

Ejecuta un programa con un perfil sin usar `init.sh`.

```bash
wn run elise ./setup.exe
```

También acepta argumentos:

```bash
wn run elise ./Game.exe console
```

Este comando no agrega automáticamente flags NW.js. Para juegos NW.js/RPG Maker MV, usa el `init.sh` generado.

## wn cfg

Abre `winecfg` para un perfil.

```bash
wn cfg elise
```

Útil para cambiar versión de Windows, gráficos, audio o librerías.

## wn tricks

Instala dependencias con `winetricks` dentro del perfil.

```bash
wn tricks elise vcrun2019 dxvk corefonts
```

Ejemplos comunes:

```bash
wn tricks elise vcrun2019
wn tricks elise dxvk
wn tricks elise corefonts
wn tricks elise win10
```

No instales cosas al azar si una app ya funciona. Cada dependencia modifica el prefix.

## wn boot

Ejecuta `wineboot -u` en el perfil.

```bash
wn boot elise
```

Útil cuando el prefix quedó incompleto o después de instalar componentes.

## wn remove

Elimina un perfil completo.

```bash
wn remove elise
```

Esto borra:

```bash
~/wineprefixes/elise
```

No borra automáticamente `init.sh` locales.

## Interpretar Errores Comunes

`ntlm_auth was not found` normalmente es warning. Puede importar para apps con autenticación/red Windows, pero en juegos offline rara vez es la causa del crash.

`Failed to create surface`, `Lost UI shared context`, `dxva_video_decode_accelerator_win.cc` apuntan a problemas de GPU/video en Chromium/NW.js. Para eso el launcher `nwjs` agrega flags automáticamente.

`GStreamer doesn't support H.264` puede afectar videos/cutscenes. Si el juego inicia pero falla al reproducir video, revisa plugins GStreamer o codecs.

`Unable to decode PNG` puede ser asset corrupto o warning de Chromium. No siempre es fatal.

## Flujo Recomendado

Para un juego RPG Maker MV/NW.js:

```bash
cd /ruta/al/juego
wn create elise ./Game.exe
./init.sh
```

Si necesitas dependencias:

```bash
wn tricks elise vcrun2019 dxvk
./init.sh
```

Para diagnosticar el launcher:

```bash
wn info ./init.sh
```

Para borrar todo el ambiente Wine de esa app:

```bash
wn remove elise
```
