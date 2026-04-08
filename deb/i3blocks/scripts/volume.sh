#!/usr/bin/env bash

refresh() {
    pkill -RTMIN+1 i3blocks >/dev/null 2>&1
}

case "${BLOCK_BUTTON:-0}" in
    1) pavucontrol >/dev/null 2>&1 & ;;
    3)
        pactl set-sink-mute @DEFAULT_SINK@ toggle >/dev/null 2>&1
        refresh
        ;;
    4)
        pactl set-sink-mute @DEFAULT_SINK@ 0 >/dev/null 2>&1
        pactl set-sink-volume @DEFAULT_SINK@ +2% >/dev/null 2>&1
        refresh
        ;;
    5)
        pactl set-sink-mute @DEFAULT_SINK@ 0 >/dev/null 2>&1
        pactl set-sink-volume @DEFAULT_SINK@ -2% >/dev/null 2>&1
        refresh
        ;;
esac

mute=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
if [ "$mute" = "yes" ]; then
    echo 'VOL <span foreground="#f7768e">mute</span>'
else
    vol=$(pactl get-sink-volume @DEFAULT_SINK@ | awk 'NR==1{print $5}')
    echo "VOL <span foreground=\"#9ece6a\">$vol</span>"
fi