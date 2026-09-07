#!/usr/bin/env bash

set -euo pipefail

readonly UPTIMEV_VERSION="0.1.0"

usage() {
  cat <<'EOF'
Usage: uptimev [--help] [--version]

Show how long this machine has been running in a friendly format.

Options:
  -h, --help       Show this help message
  -v, --version    Show the installed version
EOF
}

fail() {
  printf 'uptimev: %s\n' "$1" >&2
  exit 1
}

boot_epoch() {
  local system_name
  local boot_info
  local uptime_seconds
  local current_epoch

  if [[ -n "${UPTIMEV_BOOT_EPOCH:-}" ]]; then
    [[ "${UPTIMEV_BOOT_EPOCH}" =~ ^[0-9]+$ ]] || fail "UPTIMEV_BOOT_EPOCH must be an integer"
    printf '%s\n' "${UPTIMEV_BOOT_EPOCH}"
    return
  fi

  system_name="$(uname -s)"
  case "${system_name}" in
    Darwin)
      boot_info="$(/usr/sbin/sysctl -n kern.boottime)" || fail "could not read the system boot time"
      if [[ "${boot_info}" =~ sec[[:space:]]*=[[:space:]]*([0-9]+) ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
      else
        fail "could not understand the system boot time"
      fi
      ;;
    Linux)
      [[ -r /proc/uptime ]] || fail "/proc/uptime is not available"
      read -r uptime_seconds _ < /proc/uptime
      current_epoch="${UPTIMEV_NOW_EPOCH:-$(date +%s)}"
      printf '%s\n' "$((current_epoch - ${uptime_seconds%.*}))"
      ;;
    *)
      fail "unsupported operating system: ${system_name}"
      ;;
  esac
}

format_duration() {
  local total_seconds="$1"
  local days=$((total_seconds / 86400))
  local hours=$(((total_seconds % 86400) / 3600))
  local minutes=$(((total_seconds % 3600) / 60))
  local parts=()
  local count

  ((days > 0)) && parts+=("${days} day$([[ ${days} -eq 1 ]] || printf 's')")
  ((hours > 0)) && parts+=("${hours} hour$([[ ${hours} -eq 1 ]] || printf 's')")
  if ((minutes > 0 || ${#parts[@]} == 0)); then
    parts+=("${minutes} minute$([[ ${minutes} -eq 1 ]] || printf 's')")
  fi

  count="${#parts[@]}"
  case "${count}" in
    1) printf '%s\n' "${parts[0]}" ;;
    2) printf '%s and %s\n' "${parts[0]}" "${parts[1]}" ;;
    3) printf '%s, %s, and %s\n' "${parts[0]}" "${parts[1]}" "${parts[2]}" ;;
  esac
}

format_timestamp() {
  local epoch="$1"
  local formatted

  case "$(uname -s)" in
    Darwin) formatted="$(date -r "${epoch}" '+%A, %B %e, %Y at %l:%M %p')" ;;
    Linux) formatted="$(date -d "@${epoch}" '+%A, %B %e, %Y at %l:%M %p')" ;;
  esac

  # BSD date pads day and hour fields. Collapse that padding for prose output.
  printf '%s\n' "${formatted}" | sed -E 's/  +/ /g'
}

main() {
  local started_at
  local now
  local elapsed

  case "${1:-}" in
    -h|--help)
      usage
      return
      ;;
    -v|--version)
      printf 'uptimev %s\n' "${UPTIMEV_VERSION}"
      return
      ;;
    '') ;;
    *)
      usage >&2
      exit 2
      ;;
  esac

  started_at="$(boot_epoch)"
  now="${UPTIMEV_NOW_EPOCH:-$(date +%s)}"
  ((started_at <= now)) || fail "the system boot time is in the future"
  elapsed=$((now - started_at))

  printf 'Up for %s.\n' "$(format_duration "${elapsed}")"
  printf 'Running since %s.\n' "$(format_timestamp "${started_at}")"
}

main "$@"
