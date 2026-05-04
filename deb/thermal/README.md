# Thermal Guard

Monitor termico para la Dell Inspiron 15 3520.

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

Los enlaces instalados por `setup.zsh` apuntan al repo:

- `/usr/local/bin/thermal-guard` -> `~/.config/config/deb/thermal/thermal-guard.sh`
- `/etc/systemd/system/thermal-guard.service` -> `~/.config/config/deb/thermal/thermal-guard.service`

Umbrales por defecto:

- Intermedio balanced: CPU >= 80C o TMEM >= 75C.
- Caliente: CPU >= 88C o TMEM >= 78C.
- Muy caliente: CPU >= 94C o TMEM >= 82C.
- Restaurar AC performance: CPU < 72C y TMEM < 68C durante 12 muestras.

Variables opcionales en el servicio o entorno:

- `THERMAL_GUARD_AC_HOT_MAX_PERF=60`
- `THERMAL_GUARD_AC_CRITICAL_MAX_PERF=40`
- `THERMAL_GUARD_AC_BALANCED_MAX_PERF=85`
- `THERMAL_GUARD_BATTERY_MAX_PERF=45`
- `THERMAL_GUARD_BATTERY_HOT_MAX_PERF=35`
- `THERMAL_GUARD_INTERVAL_SECONDS=5`
