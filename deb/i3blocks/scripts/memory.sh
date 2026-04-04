#!/usr/bin/env bash

used_mb=$(free -m | awk '/^Mem:/{print $3}')
used_gb=$(awk "BEGIN { printf \"%.1f\", $used_mb/1000 }")

printf 'RAM <span foreground="#9ece6a">%s GB</span>\n' "$used_gb"