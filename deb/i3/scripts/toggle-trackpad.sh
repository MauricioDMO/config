#!/bin/sh

state=$(synclient -l | awk '/TouchpadOff/ {print $3}')

case "$state" in
  0) new=1 ;;
  1) new=0 ;;
  *) exit 1 ;;
esac

synclient TouchpadOff="$new"

if [ "$new" -eq 1 ]; then
  notify-send "Trackpad desactivado"
else
  notify-send "Trackpad activado"
fi
