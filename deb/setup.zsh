# !/bin/zsh
# Enlazar configuraciones de i3 y i3status a la carpeta de configuración del usuario
ln -sfn ~/.config/config/deb/i3/config ~/.config/i3/config

# Migracion a i3blocks
# ln -sfn ~/.config/config/deb/i3status/config ~/.config/i3status/config
ln -sfn ~/.config/config/deb/i3blocks/config ~/.config/i3blocks/config
ln -sfn ~/.config/config/deb/i3blocks/scripts ~/.config/i3blocks/scripts
chmod +x ~/.config/config/deb/i3blocks/scripts/*.sh

# Enlazar configuraciones de XFCE4 a la carpeta de configuración del usuario
ln -sfn ~/.config/config/deb/xfce4/xfce4-power-manager.xml ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml

# Enlazar configuraciones de terminal a la carpeta de configuración del usuario
ln -sfn ~/.config/config/deb/terminal/.p10k.zsh ~/.p10k.zsh

# Enlazar configuraciones de X11 a la carpeta de configuración del sistema
ln -sfn ~/.config/config/deb/X11/70-synaptics.conf /etc/X11/xorg.conf.d/70-synaptics.conf