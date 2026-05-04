#!/bin/sh

set -e

SCRIPT_PATH="$0"
case "$SCRIPT_PATH" in
  /*) ;;
  *) SCRIPT_PATH="$PWD/$SCRIPT_PATH" ;;
esac

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd)"
REPO_DIR="$(dirname -- "$SCRIPT_DIR")"

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

if [ -z "$TARGET_HOME" ] || [ ! -d "$TARGET_HOME" ]; then
  echo "No pude detectar el HOME del usuario: $TARGET_USER" >&2
  exit 1
fi

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

# Enlazar configuraciones de i3 y i3status a la carpeta de configuración del usuario
mkdir -p "$TARGET_HOME/.config/i3"
ln -sfn "$REPO_DIR/deb/i3/config" "$TARGET_HOME/.config/i3/config"

# Migracion a i3blocks
# ln -sfn ~/.config/config/deb/i3status/config ~/.config/i3status/config
mkdir -p "$TARGET_HOME/.config/i3blocks"
ln -sfn "$REPO_DIR/deb/i3blocks/config" "$TARGET_HOME/.config/i3blocks/config"
ln -sfn "$REPO_DIR/deb/i3blocks/scripts" "$TARGET_HOME/.config/i3blocks/scripts"
chmod +x "$REPO_DIR"/deb/i3blocks/scripts/*.sh

# Enlazar configuraciones de XFCE4 a la carpeta de configuración del usuario
mkdir -p "$TARGET_HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
ln -sfn "$REPO_DIR/deb/xfce4/xfce4-power-manager.xml" "$TARGET_HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml"

# Enlazar configuraciones de terminal a la carpeta de configuración del usuario
ln -sfn "$REPO_DIR/deb/terminal/.p10k.zsh" "$TARGET_HOME/.p10k.zsh"

# Enlazar configuraciones de Ghostty a la carpeta de configuración del usuario
mkdir -p "$TARGET_HOME/.config/ghostty"
ln -sfn "$REPO_DIR/deb/ghostty/config" "$TARGET_HOME/.config/ghostty/config"
ln -sfn "$REPO_DIR/deb/ghostty/themes" "$TARGET_HOME/.config/ghostty/themes"

# Enlazar configuraciones de X11 a la carpeta de configuración del sistema
as_root mkdir -p /etc/X11/xorg.conf.d
as_root ln -sfn "$REPO_DIR/deb/X11/70-synaptics.conf" /etc/X11/xorg.conf.d/70-synaptics.conf

# Enlazar monitor termico y servicio systemd
chmod +x "$REPO_DIR/deb/thermal/thermal-guard.sh"
as_root mkdir -p /usr/local/bin /etc/systemd/system
as_root ln -sfn "$REPO_DIR/deb/thermal/thermal-guard.sh" /usr/local/bin/thermal-guard
as_root ln -sfn "$REPO_DIR/deb/thermal/thermal-guard.service" /etc/systemd/system/thermal-guard.service
as_root systemctl daemon-reload

echo "Setup aplicado para $TARGET_USER usando repo: $REPO_DIR"
