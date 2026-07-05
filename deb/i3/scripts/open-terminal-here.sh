#!/bin/sh

KITTY=/home/mauriciodmo/.local/bin/kitty
KITTEN=/home/mauriciodmo/.local/bin/kitten
KITTY_SOCKET=unix:/tmp/kitty-mauriciodmo

focused_class="$(i3-msg -t get_tree | jq -r 'first(.. | objects | select(.focused? == true) | (.window_properties.class // .app_id // empty)) // ""')"

case "$focused_class" in
  kitty|Kitty)
    "$KITTEN" @ --to "$KITTY_SOCKET" launch \
      --type=os-window \
      --cwd=current \
      --source-window state:focused \
      --env CONFIG_HIDE_BANNER=1 \
      --no-response >/dev/null 2>&1 && exit 0
    ;;
esac

"$KITTEN" @ --to "$KITTY_SOCKET" launch \
  --type=os-window \
  --cwd "$HOME" \
  --env CONFIG_HIDE_BANNER= \
  --no-response >/dev/null 2>&1 && exit 0

exec "$KITTY" --listen-on "$KITTY_SOCKET"
