#!/bin/sh
setxkbmap -layout "us,latam" -option "grp:win_space_toggle" && \
	xdotool key --clearmodifiers ISO_Next_Group
