# Documentación

Este directorio es la fuente canónica de documentación del repositorio. Aquí se explica cómo orientarse entre los scripts y configuraciones para Debian, Windows y OpenCode, y se enlazan las guías específicas.

## Qué contiene el repositorio

- **Debian:** `deb/init.zsh` carga Oh My Zsh, módulos locales y ajustes opcionales; `deb/setup.zsh` crea enlaces para las configuraciones de usuario y sistema, incluida la configuración de OpenCode y el servicio Thermal Guard.
- **Windows:** `win-main.ps1` carga en un orden fijo los módulos `.ps1` de `win/` para navegación, servicios, Node, ayuda y utilidades.
- **OpenCode:** `opencode/opencode.json` define el agente `plan`, servidores MCP y plugins. Las carpetas `agents/`, `commands/` y `skills/` contienen instrucciones y definiciones de OpenCode.
- **Variables locales:** `.env.example` documenta variables para valores específicos de la máquina, como BitLocker. El archivo `.env` está ignorado y no debe contenerse en el control de versiones.

Los archivos de dependencias locales de OpenCode pueden existir en una copia de trabajo, pero `opencode/.gitignore` los excluye del control de versiones: por ejemplo, `node_modules/`, `package.json`, `package-lock.json` y `bun.lock`. Que estén ignorados no significa que no existan físicamente.

## Qué no contiene

- No debe contener secretos, claves de BitLocker ni valores privados de `.env`.
- No es una distribución completa de Debian, Windows, Wine u OpenCode: contiene configuración, scripts e instrucciones para este entorno.
- Las guías detalladas no se documentan en este índice; sus ubicaciones se enlazan más abajo.

## Organización por plataforma

### Debian

El punto de entrada del shell es `deb/init.zsh`. Para aplicar enlaces de configuración se usa `deb/setup.zsh`. Dentro de `deb/` se agrupan i3, i3blocks, terminales, X11, XFCE, Thermal Guard y módulos Zsh.

### Windows

El punto de entrada es `win-main.ps1`, que carga los módulos de `win/`. El bootstrap se incorpora desde el perfil de PowerShell.

### OpenCode

La configuración se mantiene en `opencode/` y `deb/setup.zsh` enlaza esa carpeta completa a `~/.config/opencode`. Las reglas para archivos locales ignorados están en `opencode/.gitignore`.

## Guías

Estas son las entradas de navegación previstas para la documentación detallada:

- [Debian](debian.md)
- [Windows](windows.md)
- [OpenCode](opencode.md)
- [Thermal Guard](thermal-guard.md)
- [Wine](wine.md)
- [Mantenimiento](maintenance.md)

Si una guía todavía no está creada, el enlace marca su ubicación prevista; este índice no sustituye su contenido.
