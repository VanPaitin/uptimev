#!/usr/bin/env bash

set -euo pipefail

readonly UPTIMEV_VERSION="0.2.0"

usage() {
  cat <<'EOF'
Usage: uptimev [--help | --version]

Show current time, uptime, boot time, and load averages.

Options:
  -h, --help       Show this help message
  -v, --version    Show the installed version
EOF
}

fail() {
  printf 'uptimev: %s\n' "$1" >&2
  exit "${2:-1}"
}

# Bound input before Bash arithmetic, which otherwise evaluates expressions and overflows.
decimal() {
  [[ "$1" =~ ^[0-9]{1,18}$ ]] || fail "$2 must be a non-negative integer of at most 18 digits"
  printf '%s\n' "$((10#$1))"
}

boot_epoch() {
  local boot_info seconds
  case "$1" in
    Darwin)
      boot_info=$(/usr/sbin/sysctl -n kern.boottime 2>/dev/null) || fail "could not read the system boot time"
      [[ "$boot_info" =~ ^\{[[:space:]]*sec[[:space:]]*=[[:space:]]*([0-9]+), ]] ||
        fail "could not understand the system boot time"
      decimal "${BASH_REMATCH[1]}" "system boot time"
      ;;
    Linux)
      boot_info=$(cat /proc/uptime 2>/dev/null) || fail "could not read /proc/uptime"
      seconds=${boot_info%% *}
      [[ "$seconds" =~ ^[0-9]+\.[0-9]+$ ]] || fail "could not understand /proc/uptime"
      seconds=$(decimal "${seconds%.*}" "system uptime") || return 1
      ((seconds <= $2)) || fail "system uptime exceeds the current time"
      printf '%s\n' "$(($2 - seconds))"
      ;;
  esac
}

load_averages() {
  local values one five fifteen extra value
  if [[ "${UPTIMEV_LOAD_AVERAGES+x}" ]]; then
    values=$UPTIMEV_LOAD_AVERAGES
  else
    case "$1" in
      Darwin)
        values=$(LC_ALL=C /usr/sbin/sysctl -n vm.loadavg 2>/dev/null) || fail "could not read load averages"
        [[ "$values" == \{*\} ]] || fail "could not understand load averages"
        values=${values#\{}
        values=${values%\}}
        ;;
      Linux)
        values=$(cat /proc/loadavg 2>/dev/null) || fail "could not read /proc/loadavg"
        read -r one five fifteen extra <<< "$values"
        values="$one $five $fifteen"
        ;;
    esac
  fi
  read -r one five fifteen extra <<< "$values"
  [[ -z "$extra" && "$values" != *$'\n'* ]] || fail "could not understand load averages"
  for value in "$one" "$five" "$fifteen"; do
    [[ "$value" =~ ^[0-9]+([.][0-9]+)?$ ]] || fail "could not understand load averages"
  done
  printf '%s, %s, %s\n' "$one" "$five" "$fifteen"
}

format_time() {
  local formatted date_args
  case "$1" in
    Darwin) date_args=(/bin/date -r "$2") ;;
    Linux) date_args=(date -d "@$2") ;;
  esac
  formatted=$(LC_ALL=C "${date_args[@]}" "+$3" 2>/dev/null) || fail "could not format $4"
  [[ -n "$formatted" ]] || fail "could not format $4"
  formatted=${formatted//  / }
  printf '%s\n' "${formatted# }"
}

format_duration() {
  local total_seconds="$1"
  local parts=()
  local value unit suffix

  set -- "$((total_seconds / 86400))" "$((total_seconds % 86400 / 3600))" "$((total_seconds % 3600 / 60))"
  for unit in day hour minute; do
    value=$1
    shift
    ((value > 0)) || continue
    suffix=s
    ((value == 1)) && suffix=''
    parts+=("$value $unit$suffix")
  done

  case "${#parts[@]}" in
    0) printf '0 minutes\n' ;;
    1) printf '%s\n' "${parts[0]}" ;;
    2) printf '%s and %s\n' "${parts[0]}" "${parts[1]}" ;;
    3) printf '%s, %s, and %s\n' "${parts[0]}" "${parts[1]}" "${parts[2]}" ;;
  esac
}

main() {
  local system_name now started_at duration timestamp current_time loads

  (($# <= 1)) || fail "expected at most one option; see --help" 2
  case "${1:-}" in
    -h|--help) usage; return ;;
    -v|--version) printf 'uptimev %s\n' "$UPTIMEV_VERSION"; return ;;
    '') (($# == 0)) || fail "unexpected empty argument; see --help" 2 ;;
    *) fail "unknown option: $1; see --help" 2 ;;
  esac

  system_name=$(uname -s 2>/dev/null) || fail "could not determine the operating system"
  case "$system_name" in
    Darwin|Linux) ;;
    *) fail "unsupported operating system: $system_name" ;;
  esac

  now=${UPTIMEV_NOW_EPOCH-$(date +%s 2>/dev/null)} || fail "could not read the current time"
  now=$(decimal "$now" "current time") || return 1
  started_at=${UPTIMEV_BOOT_EPOCH-$(boot_epoch "$system_name" "$now")} || return 1
  started_at=$(decimal "$started_at" "system boot time") || return 1
  ((started_at <= now)) || fail "the system boot time is in the future"

  timestamp=$(format_time "$system_name" "$started_at" '%A, %B %e, %Y at %l:%M %p' 'the system boot time') || return 1
  current_time=$(format_time "$system_name" "$now" '%l:%M:%S %p %Z' 'the current time') || return 1
  duration=$(format_duration "$((now - started_at))") || return 1
  loads=$(load_averages "$system_name") || return 1
  printf 'Current time: %s.\nUp for %s.\nRunning since %s.\nLoad averages (1, 5, 15 min): %s.\n' \
    "$current_time" "$duration" "$timestamp" "$loads"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
