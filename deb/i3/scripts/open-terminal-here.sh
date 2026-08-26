#!/bin/sh

GHOSTTY=/usr/bin/ghostty
SHELL_COMMAND="${SHELL:-/bin/zsh}"

focused_class="$(i3-msg -t get_tree | jq -r 'first(.. | objects | select(.focused? == true) | (.window_properties.class // .app_id // empty)) // ""')"

case "$focused_class" in
  com.mitchellh.ghostty|ghostty|Ghostty)
    # Avoid +new-window's cwd override so Ghostty can inherit the focused PWD.
    gdbus call \
      --session \
      --dest com.mitchellh.ghostty \
      --object-path /com/mitchellh/ghostty \
      --method org.gtk.Actions.Activate \
      new-window-command \
      "[<@as [\"-e\", \"env\", \"CONFIG_HIDE_BANNER=1\", \"$SHELL_COMMAND\"]>]" \
      "[]" \
      >/dev/null 2>&1 && exit 0
    ;;
esac

"$GHOSTTY" +new-window \
  --working-directory=home \
  --command="env CONFIG_HIDE_BANNER= $SHELL_COMMAND" \
  >/dev/null 2>&1 && exit 0

exec env CONFIG_HIDE_BANNER= "$GHOSTTY" --working-directory="$HOME"
