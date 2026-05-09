# Thermal Guard

Monitor termico para la Dell Inspiron 15 3520.

Corre como servicio `systemd` de sistema para poder escribir en `/sys` y ajustar
perfil de plataforma, turbo, limite de CPU y ventilador.

Politica:

- Con corriente y temperatura normal: `performance`, turbo activo, `max_perf_pct=100`.
- Con corriente y temperatura intermedia: `balanced`, turbo activo, `max_perf_pct=85`.
- Con corriente y temperatura alta: `cool`, turbo desactivado, rendimiento limitado.
- En bateria: `quiet`, turbo desactivado, rendimiento limitado para priorizar duracion.
- En bateria con temperatura alta: `cool` y limite mas agresivo.
- Al volver a temperatura normal con corriente: notifica que restauro turbo y `performance`.

Instalacion:

```sh
~/.config/config/deb/setup.zsh
sudo systemctl enable --now thermal-guard.service
```

Servicio:

- Unidad: `thermal-guard.service`.
- Binario enlazado: `/usr/local/bin/thermal-guard`.
- Corre en foreground con `Type=simple`.
- Reinicia automaticamente con `Restart=always`.
- Logs: `journalctl -u thermal-guard.service -f`.

Reiniciar despues de cambios:

```sh
sudo systemctl daemon-reload
sudo systemctl restart thermal-guard.service
systemctl status thermal-guard.service
```

Los enlaces instalados por `setup.zsh` apuntan al repo:

- `/usr/local/bin/thermal-guard` -> `~/.config/config/deb/thermal/thermal-guard.sh`
- `/etc/systemd/system/thermal-guard.service` -> `~/.config/config/deb/thermal/thermal-guard.service`

Umbrales por defecto:

- Intermedio balanced: CPU >= 82C.
- Caliente: CPU >= 88C o TMEM >= 82C.
- Muy caliente: CPU >= 94C o TMEM >= 86C.
- Restaurar AC performance: CPU < 72C y TMEM < 78C durante 12 muestras.
- Permanencia minima en AC performance antes de bajar a balanced: 120s, salvo temperatura caliente o critica.
- Permanencia minima en cool: 45s, incluyendo cool critico.
- En Dell, usa `dell_smm` para mantener el unico ventilador fisico al maximo (`fan1`/`pwm1`). `dell_ddv` puede mostrar el mismo ventilador duplicado para lectura.

Variables opcionales en el servicio o entorno:

- `THERMAL_GUARD_CPU_WARN_C=82`
- `THERMAL_GUARD_CPU_HOT_C=88`
- `THERMAL_GUARD_CPU_CRITICAL_C=94`
- `THERMAL_GUARD_TMEM_HOT_C=82`
- `THERMAL_GUARD_TMEM_CRITICAL_C=86`
- `THERMAL_GUARD_CPU_RESTORE_C=72`
- `THERMAL_GUARD_TMEM_RESTORE_C=78`
- `THERMAL_GUARD_RESTORE_SAMPLES=12`
- `THERMAL_GUARD_AC_HOT_MAX_PERF=60`
- `THERMAL_GUARD_AC_CRITICAL_MAX_PERF=40`
- `THERMAL_GUARD_AC_BALANCED_MAX_PERF=85`
- `THERMAL_GUARD_BATTERY_MAX_PERF=45`
- `THERMAL_GUARD_BATTERY_HOT_MAX_PERF=35`
- `THERMAL_GUARD_INTERVAL_SECONDS=5`
- `THERMAL_GUARD_MIN_AC_PERFORMANCE_SECONDS=120`
- `THERMAL_GUARD_MIN_COOL_SECONDS=45`
- `THERMAL_GUARD_NOTIFY_TIMEOUT_MS=5000`
- `THERMAL_GUARD_DISPLAY=:0`
- `THERMAL_GUARD_XAUTHORITY=/home/usuario/.Xauthority`

Notas de mantenimiento:

- El script evita `set -e` a proposito: un fallo temporal leyendo o escribiendo
  `/sys` no debe tumbar el servicio.
- La decision de politica esta separada de la aplicacion de politica para que
  los umbrales y los perfiles sean mas faciles de ajustar.
- `dell_smm` se usa para forzar `pwm1=255`; si el `hwmonN` cambia, el script lo
  vuelve a buscar.
- Las notificaciones se envian al usuario grafico activo desde el servicio root
  usando `loginctl`, `runuser` y el bus de `/run/user/<uid>/bus`.
