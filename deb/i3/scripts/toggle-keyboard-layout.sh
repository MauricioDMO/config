#!/bin/sh
current=$(setxkbmap -query | sed -n 's/^layout:[[:space:]]*//p')

case "$current" in
    us) next=latam ;;
    latam) next=us ;;
    *) next=us ;;
esac

setxkbmap -option "" -layout "$next"
