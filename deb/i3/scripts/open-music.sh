#!/bin/sh

workspaces=$(i3-msg -t get_workspaces)
current_workspace=$(printf '%s' "$workspaces" | jq -r '.[] | select(.focused) | .name')
current_output=$(printf '%s' "$workspaces" | jq -r '.[] | select(.focused) | .output')
state_file="${XDG_RUNTIME_DIR:-/tmp}/i3-music-previous-workspace-$(id -u)"

if [ "$current_workspace" = "M" ]; then
  if [ -r "$state_file" ]; then
    IFS= read -r previous_workspace <"$state_file"
    i3-msg "workspace \"$previous_workspace\"" >/dev/null
    rm -f "$state_file"
  fi
  exit
fi

[ -n "$current_workspace" ] && [ -n "$current_output" ] || exit 1
printf '%s\n' "$current_workspace" >"$state_file"

i3-msg 'workspace "M"' >/dev/null
i3-msg "move workspace to output $current_output" >/dev/null
i3-msg -t get_tree |
  jq -e '.. | objects | select(.window_properties.class? == "com.github.th-ch.youtube-music")' >/dev/null ||
  exec youtube-music
