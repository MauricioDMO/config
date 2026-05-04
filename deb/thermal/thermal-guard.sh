#!/usr/bin/env bash

set -u

# Power policy for this laptop:
# - AC + cool temps: performance profile, turbo on.
# - AC + warm temps: balanced profile, turbo on, moderate CPU cap.
# - AC + hot temps: cool profile, turbo off, reduced CPU cap.
# - Battery: quiet profile, turbo off, reduced CPU cap.

INTERVAL_SECONDS="${THERMAL_GUARD_INTERVAL_SECONDS:-5}"
WARN_REPEAT_SECONDS="${THERMAL_GUARD_WARN_REPEAT_SECONDS:-180}"
NOTIFY_TIMEOUT_MS="${THERMAL_GUARD_NOTIFY_TIMEOUT_MS:-5000}"

CPU_WARN_C="${THERMAL_GUARD_CPU_WARN_C:-80}"
CPU_HOT_C="${THERMAL_GUARD_CPU_HOT_C:-88}"
CPU_CRITICAL_C="${THERMAL_GUARD_CPU_CRITICAL_C:-94}"

TMEM_WARN_C="${THERMAL_GUARD_TMEM_WARN_C:-75}"
TMEM_HOT_C="${THERMAL_GUARD_TMEM_HOT_C:-78}"
TMEM_CRITICAL_C="${THERMAL_GUARD_TMEM_CRITICAL_C:-82}"

CPU_RESTORE_C="${THERMAL_GUARD_CPU_RESTORE_C:-72}"
TMEM_RESTORE_C="${THERMAL_GUARD_TMEM_RESTORE_C:-68}"
RESTORE_SAMPLES="${THERMAL_GUARD_RESTORE_SAMPLES:-12}"

AC_HOT_MAX_PERF="${THERMAL_GUARD_AC_HOT_MAX_PERF:-60}"
AC_CRITICAL_MAX_PERF="${THERMAL_GUARD_AC_CRITICAL_MAX_PERF:-40}"
AC_BALANCED_MAX_PERF="${THERMAL_GUARD_AC_BALANCED_MAX_PERF:-85}"
BATTERY_MAX_PERF="${THERMAL_GUARD_BATTERY_MAX_PERF:-45}"
BATTERY_HOT_MAX_PERF="${THERMAL_GUARD_BATTERY_HOT_MAX_PERF:-35}"

CPU_PKG_TEMP="/sys/class/thermal/thermal_zone5/temp"
CPU_ACPI_TEMP="/sys/class/thermal/thermal_zone3/temp"
TMEM_TEMP="/sys/class/thermal/thermal_zone2/temp"
PLATFORM_PROFILE="/sys/firmware/acpi/platform_profile"
PLATFORM_PROFILE_CHOICES="/sys/firmware/acpi/platform_profile_choices"
INTEL_NO_TURBO="/sys/devices/system/cpu/intel_pstate/no_turbo"
INTEL_MAX_PERF="/sys/devices/system/cpu/intel_pstate/max_perf_pct"

last_policy=""
last_warn_at=0
restore_count=0

log() {
    printf '%s thermal-guard: %s\n' "$(date '+%F %T')" "$*"
}

read_temp_c() {
    local path="$1"
    local raw

    if [ ! -r "$path" ]; then
        printf -- '-999\n'
        return
    fi

    read -r raw < "$path" || raw="-999000"
    printf '%s\n' "$((raw / 1000))"
}

max_temp() {
    local max="$1"
    shift

    for value in "$@"; do
        if [ "$value" -gt "$max" ]; then
            max="$value"
        fi
    done

    printf '%s\n' "$max"
}

on_ac_power() {
    local supply online type

    for supply in /sys/class/power_supply/*; do
        [ -r "$supply/type" ] || continue
        read -r type < "$supply/type" || continue
        [ "$type" = "Mains" ] || continue

        if [ -r "$supply/online" ]; then
            read -r online < "$supply/online" || online=0
            [ "$online" = "1" ] && return 0
        fi
    done

    return 1
}

write_sysfs() {
    local path="$1"
    local value="$2"

    [ -w "$path" ] || return 0

    if ! printf '%s\n' "$value" > "$path" 2>/dev/null; then
        log "no pude escribir $value en $path"
    fi
}

profile_available() {
    local profile="$1"
    local choices

    [ -r "$PLATFORM_PROFILE_CHOICES" ] || return 1
    read -r choices < "$PLATFORM_PROFILE_CHOICES" || return 1

    case " $choices " in
        *" $profile "*) return 0 ;;
        *) return 1 ;;
    esac
}

set_profile() {
    local profile="$1"

    [ -w "$PLATFORM_PROFILE" ] || return 0
    profile_available "$profile" || return 0
    write_sysfs "$PLATFORM_PROFILE" "$profile"
}

set_turbo() {
    local enabled="$1"

    [ -w "$INTEL_NO_TURBO" ] || return 0

    if [ "$enabled" = "1" ]; then
        write_sysfs "$INTEL_NO_TURBO" 0
    else
        write_sysfs "$INTEL_NO_TURBO" 1
    fi
}

set_max_perf() {
    local pct="$1"

    [ -w "$INTEL_MAX_PERF" ] || return 0
    write_sysfs "$INTEL_MAX_PERF" "$pct"
}

active_graphical_user() {
    local session uid user seat tty

    while read -r session uid user seat tty; do
        [ -n "${session:-}" ] || continue
        if [ "$(loginctl show-session "$session" -p State --value 2>/dev/null)" != "active" ]; then
            continue
        fi
        if [ "$(loginctl show-session "$session" -p Type --value 2>/dev/null)" = "tty" ]; then
            continue
        fi

        printf '%s:%s\n' "$uid" "$user"
        return 0
    done < <(loginctl list-sessions --no-legend 2>/dev/null)

    return 1
}

notify_user() {
    local title="$1"
    local body="$2"
    local urgency="${3:-critical}"
    local style="${4:-default}"
    local identity uid user home_dir runtime_dir display xauthority
    local -a notify_args

    identity="$(active_graphical_user || true)"
    [ -n "$identity" ] || return 0

    uid="${identity%%:*}"
    user="${identity#*:}"
    home_dir="$(getent passwd "$user" | cut -d: -f6)"
    runtime_dir="/run/user/$uid"
    display="${THERMAL_GUARD_DISPLAY:-:0}"
    xauthority="${THERMAL_GUARD_XAUTHORITY:-$home_dir/.Xauthority}"

    [ -S "$runtime_dir/bus" ] || return 0

    notify_args=(-t "$NOTIFY_TIMEOUT_MS" -u "$urgency")
    if [ "$style" = "restore" ]; then
        # Color hints are supported by some notification daemons; harmless if ignored.
        notify_args+=(-h string:bgcolor:#006400 -h string:fgcolor:#ffffff)
    fi

    runuser -u "$user" -- env \
        DISPLAY="$display" \
        XAUTHORITY="$xauthority" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime_dir/bus" \
        notify-send "${notify_args[@]}" "$title" "$body" >/dev/null 2>&1 || true

    runuser -u "$user" -- env \
        DISPLAY="$display" \
        XAUTHORITY="$xauthority" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime_dir/bus" \
        paplay /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga >/dev/null 2>&1 || true
}

warn_if_needed() {
    local reason="$1"
    local body="$2"
    local now

    now="$(date +%s)"
    if [ $((now - last_warn_at)) -lt "$WARN_REPEAT_SECONDS" ]; then
        return 0
    fi

    last_warn_at="$now"
    notify_user "Laptop caliente: $reason" "$body"
}

policy_code() {
    case "$1" in
        ac_performance) printf '100Pt\n' ;;
        ac_balanced) printf '%sBt\n' "$AC_BALANCED_MAX_PERF" ;;
        ac_hot) printf '%sC\n' "$AC_HOT_MAX_PERF" ;;
        ac_critical) printf '%sC\n' "$AC_CRITICAL_MAX_PERF" ;;
        battery_saver) printf '%sQ\n' "$BATTERY_MAX_PERF" ;;
        battery_hot) printf '%sC\n' "$BATTERY_HOT_MAX_PERF" ;;
        *) printf '?\n' ;;
    esac
}

is_restore_change() {
    local policy="$1"
    local previous_policy="$2"

    case "$previous_policy:$policy" in
        ac_balanced:ac_performance|ac_hot:ac_performance|ac_critical:ac_performance) return 0 ;;
        ac_hot:ac_balanced|ac_critical:ac_balanced) return 0 ;;
        battery_hot:battery_saver) return 0 ;;
        *) return 1 ;;
    esac
}

notify_policy_change() {
    local policy="$1"
    local previous_policy="$2"
    local body="$3"
    local code previous_code

    [ -n "$previous_policy" ] || return 0

    code="$(policy_code "$policy")"
    previous_code="$(policy_code "$previous_policy")"

    if is_restore_change "$policy" "$previous_policy"; then
        notify_user "Modo restaurado" "$previous_code -> $code" low restore
        return 0
    fi

    case "$policy" in
        ac_performance)
            notify_user "Modo cambiado" "$previous_code -> $code"
            ;;
        ac_balanced)
            notify_user "Modo cambiado" "$previous_code -> $code. $body"
            ;;
        ac_hot)
            notify_user "Modo cambiado" "$previous_code -> $code. $body"
            ;;
        ac_critical)
            notify_user "Modo cambiado" "$previous_code -> $code. $body. Guarda tu trabajo."
            ;;
        battery_saver)
            notify_user "Modo cambiado" "$previous_code -> $code"
            ;;
        battery_hot)
            notify_user "Modo cambiado" "$previous_code -> $code. $body"
            ;;
    esac
}

apply_policy() {
    local policy="$1"
    local body="${2:-}"
    local previous_policy="$last_policy"

    if [ "$policy" = "$last_policy" ]; then
        return 0
    fi

    case "$policy" in
        ac_performance)
            set_profile performance
            set_turbo 1
            set_max_perf 100
            log "AC fresco: performance, turbo on, max_perf=100"
            ;;
        ac_balanced)
            set_profile balanced
            set_turbo 1
            set_max_perf "$AC_BALANCED_MAX_PERF"
            log "AC tibio: balanced, turbo on, max_perf=$AC_BALANCED_MAX_PERF"
            ;;
        ac_hot)
            set_profile cool
            set_turbo 0
            set_max_perf "$AC_HOT_MAX_PERF"
            log "AC caliente: cool, turbo off, max_perf=$AC_HOT_MAX_PERF"
            ;;
        ac_critical)
            set_profile cool
            set_turbo 0
            set_max_perf "$AC_CRITICAL_MAX_PERF"
            log "AC muy caliente: cool, turbo off, max_perf=$AC_CRITICAL_MAX_PERF"
            ;;
        battery_saver)
            set_profile quiet
            set_turbo 0
            set_max_perf "$BATTERY_MAX_PERF"
            log "bateria: quiet, turbo off, max_perf=$BATTERY_MAX_PERF"
            ;;
        battery_hot)
            set_profile cool
            set_turbo 0
            set_max_perf "$BATTERY_HOT_MAX_PERF"
            log "bateria caliente: cool, turbo off, max_perf=$BATTERY_HOT_MAX_PERF"
            ;;
    esac

    last_policy="$policy"
    notify_policy_change "$policy" "$previous_policy" "$body"
}

while true; do
    cpu_pkg_c="$(read_temp_c "$CPU_PKG_TEMP")"
    cpu_acpi_c="$(read_temp_c "$CPU_ACPI_TEMP")"
    tmem_c="$(read_temp_c "$TMEM_TEMP")"
    cpu_c="$(max_temp "$cpu_pkg_c" "$cpu_acpi_c")"
    body="CPU ${cpu_c}C, TMEM ${tmem_c}C"

    if [ "$cpu_c" -lt "$CPU_RESTORE_C" ] && [ "$tmem_c" -lt "$TMEM_RESTORE_C" ]; then
        restore_count="$((restore_count + 1))"
    else
        restore_count=0
    fi

    if on_ac_power; then
        if [ "$cpu_c" -ge "$CPU_CRITICAL_C" ] || [ "$tmem_c" -ge "$TMEM_CRITICAL_C" ]; then
            apply_policy ac_critical "$body"
        elif [ "$cpu_c" -ge "$CPU_HOT_C" ] || [ "$tmem_c" -ge "$TMEM_HOT_C" ]; then
            apply_policy ac_hot "$body"
        elif [ "$cpu_c" -ge "$CPU_WARN_C" ] || [ "$tmem_c" -ge "$TMEM_WARN_C" ]; then
            apply_policy ac_balanced "$body"
        elif [ "$restore_count" -lt "$RESTORE_SAMPLES" ] && { [ "$last_policy" = "ac_hot" ] || [ "$last_policy" = "ac_critical" ]; }; then
            apply_policy ac_balanced "$body"
        elif [ "$restore_count" -ge "$RESTORE_SAMPLES" ] || [ -z "$last_policy" ]; then
            apply_policy ac_performance "$body"
        fi
    else
        if [ "$cpu_c" -ge "$CPU_HOT_C" ] || [ "$tmem_c" -ge "$TMEM_HOT_C" ]; then
            apply_policy battery_hot "$body"
        else
            apply_policy battery_saver "$body"
        fi
    fi

    sleep "$INTERVAL_SECONDS"
done
