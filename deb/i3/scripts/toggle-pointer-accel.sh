#!/bin/sh

state_file="${XDG_RUNTIME_DIR:-/tmp}/pointer-accel-mode"
current="normal"

if [ -f "$state_file" ]; then
  current=$(cat "$state_file")
fi

if [ "$current" = "flat" ]; then
  mode="normal"
else
  mode="flat"
fi

set_libinput_profile() {
  id="$1"
  profile="$2"

  if xinput list-props "$id" | grep -q "libinput Accel Profile Enabled"; then
    if [ "$profile" = "flat" ]; then
      xinput set-prop "$id" "libinput Accel Profile Enabled" 0 1 0 2>/dev/null || true
    else
      xinput set-prop "$id" "libinput Accel Profile Enabled" 1 0 0 2>/dev/null || true
    fi

    xinput set-prop "$id" "libinput Accel Speed" 0 2>/dev/null || true
  fi
}

if [ "$mode" = "flat" ]; then
  synclient MinSpeed=1 MaxSpeed=1 AccelFactor=0 2>/dev/null || true
else
  synclient MinSpeed=1 MaxSpeed=1.75 AccelFactor=0.0908678 2>/dev/null || true
fi

xinput list --id-only | while read -r id; do
  set_libinput_profile "$id" "$mode"
done

printf '%s\n' "$mode" > "$state_file"

if [ "$mode" = "flat" ]; then
  notify-send "Aceleracion del puntero desactivada"
else
  notify-send "Aceleracion del puntero activada"
fi
