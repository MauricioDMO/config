#!/bin/sh

if i3-msg -t get_workspaces |
  jq -e '.[] | select(.focused and .name == "M")' >/dev/null; then
  i3-msg 'workspace back_and_forth' >/dev/null
  exit
fi

i3-msg 'workspace "M"' >/dev/null
i3-msg -t get_tree |
  jq -e '.. | objects | select(.window_properties.class? == "com.github.th-ch.youtube-music")' >/dev/null ||
  exec youtube-music
