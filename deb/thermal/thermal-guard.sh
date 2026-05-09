#!/usr/bin/env bash

set -u

# Power policy for this laptop:
# - AC + cool temps: performance profile, turbo on.
# - AC + warm temps: balanced profile, turbo on, moderate CPU cap.
# - AC + hot temps: cool profile, turbo off, reduced CPU cap.
# - Battery: quiet profile, turbo off, reduced CPU cap.

INTERVAL_SECONDS="${THERMAL_GUARD_INTERVAL_SECONDS:-5}"
NOTIFY_TIMEOUT_MS="${THERMAL_GUARD_NOTIFY_TIMEOUT_MS:-5000}"

CPU_WARN_C="${THERMAL_GUARD_CPU_WARN_C:-82}"
CPU_HOT_C="${THERMAL_GUARD_CPU_HOT_C:-88}"
CPU_CRITICAL_C="${THERMAL_GUARD_CPU_CRITICAL_C:-94}"

TMEM_HOT_C="${THERMAL_GUARD_TMEM_HOT_C:-82}"
TMEM_CRITICAL_C="${THERMAL_GUARD_TMEM_CRITICAL_C:-86}"

CPU_RESTORE_C="${THERMAL_GUARD_CPU_RESTORE_C:-72}"
TMEM_RESTORE_C="${THERMAL_GUARD_TMEM_RESTORE_C:-78}"
RESTORE_SAMPLES="${THERMAL_GUARD_RESTORE_SAMPLES:-12}"
MIN_AC_PERFORMANCE_SECONDS="${THERMAL_GUARD_MIN_AC_PERFORMANCE_SECONDS:-120}"
MIN_COOL_SECONDS="${THERMAL_GUARD_MIN_COOL_SECONDS:-45}"

AC_HOT_MAX_PERF="${THERMAL_GUARD_AC_HOT_MAX_PERF:-60}"
AC_CRITICAL_MAX_PERF="${THERMAL_GUARD_AC_CRITICAL_MAX_PERF:-40}"
AC_BALANCED_MAX_PERF="${THERMAL_GUARD_AC_BALANCED_MAX_PERF:-85}"
BATTERY_MAX_PERF="${THERMAL_GUARD_BATTERY_MAX_PERF:-45}"
BATTERY_HOT_MAX_PERF="${THERMAL_GUARD_BATTERY_HOT_MAX_PERF:-35}"

CPU_PKG_TEMP="/sys/class/thermal/thermal_zone6/temp"
CPU_ACPI_TEMP="/sys/class/thermal/thermal_zone3/temp"
TMEM_TEMP="/sys/class/thermal/thermal_zone2/temp"
PLATFORM_PROFILE="/sys/firmware/acpi/platform_profile"
PLATFORM_PROFILE_CHOICES="/sys/firmware/acpi/platform_profile_choices"
INTEL_NO_TURBO="/sys/devices/system/cpu/intel_pstate/no_turbo"
INTEL_MAX_PERF="/sys/devices/system/cpu/intel_pstate/max_perf_pct"

last_policy=""
last_policy_at=0
restore_count=0
dell_smm_hwmon=""

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
    [ -w "$INTEL_NO_TURBO" ] || return 0

    if [ "$1" = "1" ]; then
        write_sysfs "$INTEL_NO_TURBO" 0
    else
        write_sysfs "$INTEL_NO_TURBO" 1
    fi
}

set_max_perf() {
    [ -w "$INTEL_MAX_PERF" ] || return 0
    write_sysfs "$INTEL_MAX_PERF" "$1"
}

dell_smm_hwmon_path() {
    local hwmon name

    if [ -n "$dell_smm_hwmon" ] && [ -w "$dell_smm_hwmon/pwm1" ]; then
        printf '%s\n' "$dell_smm_hwmon"
        return 0
    fi

    for hwmon in /sys/class/hwmon/hwmon*; do
        [ -r "$hwmon/name" ] || continue
        read -r name < "$hwmon/name" || continue
        [ "$name" = "dell_smm" ] || continue
        dell_smm_hwmon="$hwmon"
        printf '%s\n' "$hwmon"
        return 0
    done

    return 1
}

set_fans_max() {
    local hwmon
    hwmon="$(dell_smm_hwmon_path)" || return 0
    write_sysfs "$hwmon/pwm1" 255
}

policy_elapsed_seconds() {
    local now

    [ "$last_policy_at" -gt 0 ] || { printf '999999\n'; return 0; }
    now="$(date +%s)"
    printf '%s\n' "$((now - last_policy_at))"
}

can_apply_policy() {
    local policy="$1"
    local elapsed

    [ -n "$last_policy" ] || return 0
    elapsed="$(policy_elapsed_seconds)"

    if [ "$last_policy" = "ac_performance" ] && [ "$policy" = "ac_balanced" ] && [ "$elapsed" -lt "$MIN_AC_PERFORMANCE_SECONDS" ]; then
        return 1
    fi

    case "$last_policy:$policy" in
        ac_hot:ac_critical)
            return 0
            ;;
        ac_hot:*|ac_critical:*|battery_hot:*)
            [ "$elapsed" -ge "$MIN_COOL_SECONDS" ] || return 1
            ;;
    esac

    return 0
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

run_as_graphical_user() {
    local user="$1"
    local display="$2"
    local xauthority="$3"
    local runtime_dir="$4"
    shift 4

    runuser -u "$user" -- env \
        DISPLAY="$display" \
        XAUTHORITY="$xauthority" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime_dir/bus" \
        "$@" >/dev/null 2>&1 || true
}

notify_user() {
    local title="$1"
    local body="$2"
    local urgency="${3:-normal}"
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

    run_as_graphical_user "$user" "$display" "$xauthority" "$runtime_dir" \
        notify-send "${notify_args[@]}" "$title" "$body"
    run_as_graphical_user "$user" "$display" "$xauthority" "$runtime_dir" \
        paplay /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga
}

policy_code() {
    local profile turbo max_perf code log_msg

    if IFS=$'\t' read -r profile turbo max_perf code log_msg < <(policy_settings "$1"); then
        printf '%s\n' "$code"
        return 0
    fi

    printf '?\n'
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

policy_settings() {
    local profile turbo max_perf code log_msg

    case "$1" in
        ac_performance) profile=performance; turbo=1; max_perf=100; code=100Pt; log_msg="AC fresco: performance, turbo on, max_perf=100" ;;
        ac_balanced) profile=balanced; turbo=1; max_perf="$AC_BALANCED_MAX_PERF"; code="${AC_BALANCED_MAX_PERF}Bt"; log_msg="AC tibio: balanced, turbo on, max_perf=$AC_BALANCED_MAX_PERF" ;;
        ac_hot) profile=cool; turbo=0; max_perf="$AC_HOT_MAX_PERF"; code="${AC_HOT_MAX_PERF}C"; log_msg="AC caliente: cool, turbo off, max_perf=$AC_HOT_MAX_PERF" ;;
        ac_critical) profile=cool; turbo=0; max_perf="$AC_CRITICAL_MAX_PERF"; code="${AC_CRITICAL_MAX_PERF}C"; log_msg="AC muy caliente: cool, turbo off, max_perf=$AC_CRITICAL_MAX_PERF" ;;
        battery_saver) profile=quiet; turbo=0; max_perf="$BATTERY_MAX_PERF"; code="${BATTERY_MAX_PERF}Q"; log_msg="bateria: quiet, turbo off, max_perf=$BATTERY_MAX_PERF" ;;
        battery_hot) profile=cool; turbo=0; max_perf="$BATTERY_HOT_MAX_PERF"; code="${BATTERY_HOT_MAX_PERF}C"; log_msg="bateria caliente: cool, turbo off, max_perf=$BATTERY_HOT_MAX_PERF" ;;
        *) return 1 ;;
    esac

    printf '%s\t%s\t%s\t%s\t%s\n' "$profile" "$turbo" "$max_perf" "$code" "$log_msg"
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
    local profile turbo max_perf code log_msg

    if [ "$policy" = "$last_policy" ]; then
        return 0
    fi

    can_apply_policy "$policy" || return 0

    IFS=$'\t' read -r profile turbo max_perf code log_msg < <(policy_settings "$policy") || return 0
    set_profile "$profile"
    set_turbo "$turbo"
    set_max_perf "$max_perf"
    log "$log_msg"

    last_policy="$policy"
    last_policy_at="$(date +%s)"
    notify_policy_change "$policy" "$previous_policy" "$body"
}

update_restore_count() {
    local cpu_c="$1" tmem_c="$2"

    if [ "$cpu_c" -lt "$CPU_RESTORE_C" ] && [ "$tmem_c" -lt "$TMEM_RESTORE_C" ]; then
        restore_count="$((restore_count + 1))"
    else
        restore_count=0
    fi
}

choose_ac_policy() {
    local cpu_c="$1" tmem_c="$2"

    if [ "$cpu_c" -ge "$CPU_CRITICAL_C" ] || [ "$tmem_c" -ge "$TMEM_CRITICAL_C" ]; then
        printf '%s\n' ac_critical
    elif [ "$cpu_c" -ge "$CPU_HOT_C" ] || [ "$tmem_c" -ge "$TMEM_HOT_C" ]; then
        printf '%s\n' ac_hot
    elif [ "$cpu_c" -ge "$CPU_WARN_C" ]; then
        printf '%s\n' ac_balanced
    elif [ "$restore_count" -lt "$RESTORE_SAMPLES" ] && { [ "$last_policy" = "ac_hot" ] || [ "$last_policy" = "ac_critical" ]; }; then
        printf '%s\n' ac_balanced
    elif [ "$restore_count" -ge "$RESTORE_SAMPLES" ] || [ -z "$last_policy" ]; then
        printf '%s\n' ac_performance
    fi
}

choose_battery_policy() {
    local cpu_c="$1" tmem_c="$2"

    if [ "$cpu_c" -ge "$CPU_HOT_C" ] || [ "$tmem_c" -ge "$TMEM_HOT_C" ]; then
        printf '%s\n' battery_hot
        return 0
    fi

    printf '%s\n' battery_saver
}

set_fans_max

while true; do
    set_fans_max

    cpu_pkg_c="$(read_temp_c "$CPU_PKG_TEMP")"
    cpu_acpi_c="$(read_temp_c "$CPU_ACPI_TEMP")"
    tmem_c="$(read_temp_c "$TMEM_TEMP")"
    cpu_c="$(max_temp "$cpu_pkg_c" "$cpu_acpi_c")"
    body="CPU ${cpu_c}C, TMEM ${tmem_c}C"
    policy=""

    update_restore_count "$cpu_c" "$tmem_c"

    if on_ac_power; then
        policy="$(choose_ac_policy "$cpu_c" "$tmem_c")"
    else
        policy="$(choose_battery_policy "$cpu_c" "$tmem_c")"
    fi

    [ -n "$policy" ] && apply_policy "$policy" "$body"

    sleep "$INTERVAL_SECONDS"
done
