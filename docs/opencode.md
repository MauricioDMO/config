# OpenCode

Esta guía explica la configuración de OpenCode mantenida en `opencode/`, cómo
se instala en el entorno del usuario y qué debe revisarse al mantenerla.

## Ubicación e instalación

`opencode/` contiene la configuración y las instrucciones de este entorno:

- `opencode/opencode.json`: configuración principal.
- `opencode/AGENTS.md`: instrucciones operativas para los agentes.
- `opencode/agents/`: definiciones de agentes.
- `opencode/commands/`: comandos disponibles.
- `opencode/skills/`: instrucciones reutilizables agrupadas por skill.

`deb/setup.zsh` resuelve la ubicación del repositorio a partir de la ruta del
script, determina el usuario objetivo (`SUDO_USER` o `USER`) y crea, si hace
falta, `~/.config`. Después ejecuta:

```sh
ln -sfnT "$REPO_DIR/opencode" "$TARGET_HOME/.config/opencode"
```

La operación se realiza con el usuario objetivo mediante `as_user`. Por tanto,
`~/.config/opencode` apunta a la carpeta `opencode/` del repositorio; no se
copia una segunda configuración. Para volver a aplicar el enlace, ejecuta
`deb/setup.zsh` desde el repositorio.

## Configuración principal

`opencode/opencode.json` declara el schema:

```text
https://opencode.ai/config.json
```

También contiene lo siguiente:

### Agente `plan`

El agente `plan` está declarado con el color `#B58900`.

### MCP

Los servidores MCP configurados son:

| Nombre | Tipo | Configuración | Estado explícito |
| --- | --- | --- | --- |
| `chrome-devtools` | local | `npx -y chrome-devtools-mcp@latest` | no se declara `enabled` |
| `Astro docs` | remoto | `https://mcp.docs.astro.build/mcp` | habilitado |
| `codegraph` | local | `codegraph serve --mcp` | habilitado |

El comando local de `chrome-devtools` se expresa como la lista
`["npx", "-y", "chrome-devtools-mcp@latest"]`; el de `codegraph`, como
`["codegraph", "serve", "--mcp"]`. `Astro docs` es remoto y usa la URL
indicada.

### Plugin

La lista de plugins incluye `@dietrichgebert/ponytail`.

Esta guía describe únicamente los valores presentes en `opencode.json`; no
supone comportamientos adicionales para valores no declarados.

## Agentes, comandos y skills

Son extensiones distintas de la configuración. Además del agente `plan`,
declarado directamente en `opencode.json`, los agentes definidos mediante
archivos son:

- **Agentes:** definen perfiles de trabajo, permisos y, en algunos casos,
  instrucciones de rol. Los nombres actuales son `brainstorm`, `docs-manager`,
  `commit-writer`, `docs-explorer` y `docs-worker`.
- **Comandos:** son entradas invocables que asocian una descripción con un
  agente y unas instrucciones. Los nombres actuales son `commit` y
  `document`.
- **Skills:** son conjuntos de instrucciones especializadas que un agente puede
  cargar para una tarea. Los nombres actuales son `docs-document`,
  `web-perf`, `docs-discovery`, `docs-orchestration` y `docs-review-fix`.

`opencode/AGENTS.md` contiene instrucciones operativas para los agentes, como
reglas para consultar CodeGraph y recuperar documentación con `ctx7`. No es
una guía general de usuario ni sustituye esta documentación.

## Carga y cambios

Los archivos revisados no documentan explícitamente cuándo OpenCode carga esta
configuración ni si admite recarga dinámica. Como práctica operativa prudente,
reinicia la sesión de OpenCode después de cambiar `opencode.json`, agentes,
comandos o skills para asegurarte de que la nueva versión se utiliza.

## Dependencias locales y versionado

En esta copia de trabajo existen físicamente `node_modules/`, `package.json` y
`package-lock.json`, pero no forman parte del contenido versionado de
`opencode/`: `opencode/.gitignore` los excluye, junto con `bun.lock`, `.env`,
`.env.*` y `*.local.json`. Que estén ignorados no significa que no existan en
el equipo; significa que quedan fuera de la intención de versionado de esta
configuración.

No añadas secretos ni dependencias locales al repositorio. Si el entorno local
necesita reinstalarlas, hazlo según el procedimiento de instalación del
entorno, sin convertir esos archivos ignorados en parte de esta guía.

## Mantenimiento básico

1. Edita los archivos fuente bajo `opencode/`; el destino efectivo es el enlace
   `~/.config/opencode`.
2. Al cambiar la configuración, comprueba que `opencode/opencode.json` siga
   siendo JSON válido y que los nombres de agentes, comandos, skills, MCP y
   plugins coincidan con archivos o valores existentes.
3. Si el enlace falta o apunta a otro lugar, vuelve a ejecutar
   `deb/setup.zsh`.
4. Reinicia la sesión de OpenCode después de los cambios, como medida
   preventiva frente a la ausencia de evidencia sobre recarga dinámica.
5. Revisa el diff antes de versionar: no incluyas `node_modules/`, secretos ni
   otros archivos locales ignorados.

## Límites de alcance

Esta configuración documenta el entorno local de OpenCode: su archivo JSON,
agentes, comandos, skills, instrucciones operativas y el enlace creado por
`deb/setup.zsh`. No documenta aquí el funcionamiento interno de OpenCode, la
documentación de los servicios MCP, la instalación de sus dependencias ni una
guía general de uso de agentes.
