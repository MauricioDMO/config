#!/bin/sh

# i3 ignores command criteria for workspace renames.
focused_workspace=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).name')
[ "$focused_workspace" = M ] && exit 0

exec i3-msg "rename workspace to \"$1\""
