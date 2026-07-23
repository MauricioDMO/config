# thermal-guard

`thermal-guard` es un servicio de sistema que vigila las temperaturas expuestas
por Linux y ajusta la política de energía de un portátil Dell. Está pensado
para este equipo y depende de que el kernel exponga los dispositivos
correspondientes en `/sys`.

El proceso se ejecuta como root, en primer plano, y comprueba los sensores cada
`THERMAL_GUARD_INTERVAL_SECONDS` segundos. En cada iteración intenta mantener
el ventilador Dell al máximo (`pwm1=255`), decide una política según la
alimentación y las temperaturas, y aplica esa política mediante sysfs.

## Hardware y sysfs

El script no detecta el modelo del equipo. Espera interfaces compatibles con:

| Función | Ruta sysfs |
| --- | --- |
| Perfil de plataforma | `/sys/firmware/acpi/platform_profile` |
| Perfiles disponibles | `/sys/firmware/acpi/platform_profile_choices` |
| Turbo Intel | `/sys/devices/system/cpu/intel_pstate/no_turbo` |
| Límite de rendimiento Intel | `/sys/devices/system/cpu/intel_pstate/max_perf_pct` |
| Ventilador Dell | `/sys/class/hwmon/hwmon*/name` exactamente igual a `dell_smm`, y luego `pwm1` |

Los perfiles que puede solicitar son `performance`, `balanced`, `cool` y
`quiet`. Solo escribe el perfil si `platform_profile` es escribible y el
nombre aparece como opción disponible. Turbo y `max_perf_pct` se omiten si
las rutas de `intel_pstate` no existen o no son escribibles.

El ventilador se busca en un hwmon cuyo archivo `name` contiene exactamente
`dell_smm`. Si se encuentra un `pwm1` escribible, se escribe `255` al iniciar
y al comienzo de cada iteración. Si no existe ese hwmon, no se intenta usar
otro controlador de ventilador.

### Sensores

Las rutas se pueden fijar con variables de entorno. Si están vacías, el script
busca primero una etiqueta de hwmon, sin distinguir mayúsculas y minúsculas,
y finalmente usa el fallback indicado:

| Variable | Autodetección | Fallback |
| --- | --- | --- |
| `THERMAL_GUARD_CPU_PKG_TEMP` | etiqueta que contiene `package id`, luego `tctl` | `/sys/class/thermal/thermal_zone6/temp` |
| `THERMAL_GUARD_CPU_ACPI_TEMP` | etiqueta que contiene `acpitz` | `/sys/class/thermal/thermal_zone3/temp` |
| `THERMAL_GUARD_TMEM_TEMP` | etiqueta que contiene `tmem`, luego `memory` | `/sys/class/thermal/thermal_zone2/temp` |

Para una etiqueta encontrada se usa el archivo hermano `temp*_input`, pero solo
si es legible. El script lee cada valor como milésimas de grado Celsius y
trunca la división a grados enteros. La temperatura de CPU usada para decidir
es el máximo entre CPU package y CPU ACPI; `TMEM` se evalúa por separado.

La alimentación se considera AC únicamente cuando existe una fuente en
`/sys/class/power_supply/*` cuyo `type` es exactamente `Mains` y cuyo archivo
`online` contiene `1`. Si no se encuentra, el script sigue la política de
batería.

## Política térmica

Los valores de la tabla son los predeterminados. Las comparaciones de entrada
usan `>=`; las condiciones de restauración usan `<`.

| Estado | Condición | Perfil | Turbo | `max_perf_pct` |
| --- | --- | --- | --- | ---: |
| AC fresco | CPU `< 82` °C y TMEM `< 82` °C, sin retención por histéresis | `performance` | activo | 100 |
| AC tibio | CPU `>= 82` °C, sin condición caliente o crítica | `balanced` | activo | 85 |
| AC caliente | CPU `>= 88` °C o TMEM `>= 82` °C | `cool` | desactivado | 60 |
| AC muy caliente | CPU `>= 94` °C o TMEM `>= 86` °C | `cool` | desactivado | 40 |
| Batería | por debajo del límite caliente | `quiet` | desactivado | 45 |
| Batería caliente | CPU `>= 88` °C o TMEM `>= 82` °C | `cool` | desactivado | 35 |

En AC, el límite crítico se evalúa antes que el caliente, y el caliente antes
que el estado tibio. TMEM no tiene un umbral propio para `balanced`: solo
provoca los estados AC caliente o AC muy caliente. En batería no existe un
estado crítico separado.

### Histéresis y permanencia

- Para volver desde un estado AC caliente o muy caliente hacia
  `performance`, ambos valores deben estar por debajo de CPU `72` °C y TMEM
  `78` °C durante `12` muestras consecutivas. Si se supera cualquiera de esos
  límites, el contador vuelve a cero.
- Mientras se acumulan esas muestras después de un estado caliente, la
  política elegida es `balanced` (y puede quedar retenida por la permanencia
  mínima de `45` segundos antes de aplicarse).
- El paso exacto de AC `performance` a AC `balanced` espera al menos `120`
  segundos desde la entrada en `performance`. Una decisión caliente o crítica
  puede aplicarse sin esa espera.
- Al salir de `ac_hot`, `ac_critical` o `battery_hot`, se exige una permanencia
  mínima de `45` segundos antes de cambiar a otra política, excepto el paso
  inmediato de `ac_hot` a `ac_critical`.
- El contador de restauración se actualiza en cada iteración, también mientras
  el equipo está en batería; cambiar de alimentación no lo reinicia.
- El estado y los temporizadores viven solo en memoria. Al reiniciar el
  proceso se pierde la histéresis y se elige una política inicial nueva.

Cada cambio de política se registra con una abreviatura, por ejemplo `100Pt`
para AC fresco, `85Bt` para AC tibio, `60C` para AC caliente, `40C` para AC muy
caliente, `45Q` para batería y `35C` para batería caliente.

## Configuración

El script admite estas variables de entorno. Un valor vacío en una variable de
sensor activa la autodetección descrita arriba.

### Umbrales y tiempos

| Variable | Predeterminado | Uso |
| --- | ---: | --- |
| `THERMAL_GUARD_INTERVAL_SECONDS` | `5` | Segundos entre iteraciones |
| `THERMAL_GUARD_CPU_WARN_C` | `82` | Umbral CPU para AC `balanced` |
| `THERMAL_GUARD_CPU_HOT_C` | `88` | Umbral CPU caliente |
| `THERMAL_GUARD_CPU_CRITICAL_C` | `94` | Umbral CPU crítico en AC |
| `THERMAL_GUARD_TMEM_HOT_C` | `82` | Umbral TMEM caliente |
| `THERMAL_GUARD_TMEM_CRITICAL_C` | `86` | Umbral TMEM crítico en AC |
| `THERMAL_GUARD_CPU_RESTORE_C` | `72` | Límite CPU para contar restauración |
| `THERMAL_GUARD_TMEM_RESTORE_C` | `78` | Límite TMEM para contar restauración |
| `THERMAL_GUARD_RESTORE_SAMPLES` | `12` | Muestras frías consecutivas requeridas |
| `THERMAL_GUARD_MIN_AC_PERFORMANCE_SECONDS` | `120` | Espera de `performance` a `balanced` |
| `THERMAL_GUARD_MIN_COOL_SECONDS` | `45` | Permanencia mínima antes de salir de estados calientes |

### Límites de rendimiento

| Variable | Predeterminado | Estado afectado |
| --- | ---: | --- |
| `THERMAL_GUARD_AC_BALANCED_MAX_PERF` | `85` | AC tibio |
| `THERMAL_GUARD_AC_HOT_MAX_PERF` | `60` | AC caliente |
| `THERMAL_GUARD_AC_CRITICAL_MAX_PERF` | `40` | AC muy caliente |
| `THERMAL_GUARD_BATTERY_MAX_PERF` | `45` | Batería |
| `THERMAL_GUARD_BATTERY_HOT_MAX_PERF` | `35` | Batería caliente |

### Rutas de sensores y notificaciones

| Variable | Predeterminado efectivo | Uso |
| --- | --- | --- |
| `THERMAL_GUARD_CPU_PKG_TEMP` | autodetección/fallback de CPU package | Ruta del sensor CPU package |
| `THERMAL_GUARD_CPU_ACPI_TEMP` | autodetección/fallback ACPI | Ruta del sensor CPU ACPI |
| `THERMAL_GUARD_TMEM_TEMP` | autodetección/fallback TMEM | Ruta del sensor de memoria |
| `THERMAL_GUARD_NOTIFY_TIMEOUT_MS` | `5000` | Tiempo de `notify-send` en ms |
| `THERMAL_GUARD_DISPLAY` | `:0` | Display X11 para notificar |
| `THERMAL_GUARD_XAUTHORITY` | `<home del usuario gráfico>/.Xauthority` | Archivo Xauthority del usuario gráfico |

Estas variables son entradas del proceso `thermal-guard`; no son opciones de
la unidad por sí mismas.

> **Importante sobre `.env`.** `deb/setup.zsh` no carga `.env` y
> `thermal-guard.service` no contiene `EnvironmentFile=` ni otro mecanismo
> para leerlo. Por tanto, copiar `.env.example` a `.env` no configura este
> servicio, y las variables térmicas definidas allí no llegarían al proceso
> sin un mecanismo adicional de entorno de systemd. El `.env.example` actual
> solo documenta variables de BitLocker.

## Instalación y activación

Desde este checkout, ejecuta el instalador del repositorio:

```sh
~/.config/config/deb/setup.zsh
```

El script crea los directorios necesarios, hace ejecutable el script térmico,
instala los enlaces simbólicos y ejecuta `systemctl daemon-reload`. No habilita
ni inicia automáticamente el servicio. Para activarlo:

```sh
sudo systemctl enable --now thermal-guard.service
```

La unidad es un servicio de sistema con estas propiedades:

- `Type=simple`, con `ExecStart=/usr/local/bin/thermal-guard`.
- Arranca después de `multi-user.target` y `thermald.service`, y declara
  `Wants=thermald.service`.
- Se reinicia siempre si termina, con una espera de `3` segundos.
- Se instala bajo `multi-user.target` cuando se habilita.

### Enlaces instalados

`setup.zsh` apunta directamente al checkout desde el que se ejecutó; no copia
los archivos. Los destinos son:

```text
/usr/local/bin/thermal-guard -> <REPO_DIR>/deb/thermal/thermal-guard.sh
/etc/systemd/system/thermal-guard.service -> <REPO_DIR>/deb/thermal/thermal-guard.service
```

En la instalación habitual de este equipo, `<REPO_DIR>` es
`/home/mauriciodmo/.config/config`. Comprueba el destino real con:

```sh
readlink -f /usr/local/bin/thermal-guard
readlink -f /etc/systemd/system/thermal-guard.service
```

## Operación y diagnóstico

Estado y activación:

```sh
systemctl status thermal-guard.service
systemctl is-enabled thermal-guard.service
systemctl is-active thermal-guard.service
```

Logs en tiempo real y del arranque actual:

```sh
journalctl -u thermal-guard.service -f
journalctl -u thermal-guard.service -b
```

Al iniciar, el script registra las rutas de sensores resueltas. También
registra cada cambio de política y los fallos al escribir en una ruta sysfs
que sí era escribible. No registra una línea por cada muestra.

Después de modificar el script o sus enlaces, reinicia el servicio:

```sh
sudo systemctl restart thermal-guard.service
```

Si se modificó la unidad systemd, recarga primero la configuración; `setup.zsh`
ya realiza este paso cuando instala los enlaces:

```sh
sudo systemctl daemon-reload
sudo systemctl restart thermal-guard.service
```

Para inspeccionar las interfaces que el script necesita:

```sh
cat /sys/class/thermal/thermal_zone6/temp
cat /sys/class/thermal/thermal_zone3/temp
cat /sys/class/thermal/thermal_zone2/temp
cat /sys/firmware/acpi/platform_profile_choices
cat /sys/devices/system/cpu/intel_pstate/max_perf_pct
```

Las rutas de sensores anteriores son solo los fallbacks; la ruta efectiva es
la que aparece en el mensaje inicial del journal.

## Limitaciones y tolerancia a fallos

- La ausencia o falta de permisos de una ruta de plataforma, Intel o ventilador
  no detiene el bucle: esa escritura se omite. Una escritura fallida en una
  ruta que sí era escribible se registra y el proceso continúa.
- Un sensor ilegible se representa internamente como `-999` °C. El script no
  detiene el servicio por ese motivo; si faltan sensores, las decisiones pueden
  basarse en datos incompletos y no deben interpretarse como una protección
  térmica garantizada.
- El script usa `set -u`, pero deliberadamente no usa `set -e`; los comandos de
  sysfs, notificación y audio son de mejor esfuerzo. Puede registrar una
  política aunque alguna escritura concreta no haya sido posible.
- Las notificaciones solo se intentan si `loginctl` encuentra una sesión
  gráfica activa y existe `/run/user/<uid>/bus`. Se ejecutan como ese usuario
  con `notify-send` y, además, `paplay`. Si el bus, X11 o esos comandos no
  están disponibles, el fallo se ignora.
- No se notifica la política inicial, porque no hay una política anterior que
  comunicar. Los cambios posteriores sí intentan mostrar una notificación;
  las restauraciones usan urgencia baja y una sugerencia de colores.
- Si se detiene el servicio no hay una rutina de limpieza que restaure el
  perfil, el turbo, el límite de rendimiento o el PWM anteriores. El siguiente
  arranque vuelve a aplicar la política que corresponda.
- No hay persistencia de estado ni validación del modelo Dell o de los límites
  configurados. Antes de escribir un perfil, el script sí comprueba que
  `platform_profile_choices` sea legible y que el perfil solicitado aparezca
  entre las opciones disponibles. La unidad depende de las interfaces que el
  kernel y los controladores del equipo expongan en sysfs.
