#!/usr/bin/env bash

set -euo pipefail

readonly PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly COMMAND="${PROJECT_DIR}/uptime.sh"
readonly NOW_EPOCH=1788753600

assert_output() {
  local expected="$1"
  shift
  local actual

  actual="$("$@")"
  if [[ "${actual}" != "${expected}" ]]; then
    printf 'Expected:\n%s\n\nActual:\n%s\n' "${expected}" "${actual}" >&2
    exit 1
  fi
}

assert_output \
  "uptimev 0.1.0" \
  "${COMMAND}" --version

assert_output \
  $'Up for 2 days, 4 hours, and 17 minutes.\nRunning since Friday, September 4, 2026 at 11:43 PM.' \
  env TZ=UTC UPTIMEV_NOW_EPOCH="${NOW_EPOCH}" UPTIMEV_BOOT_EPOCH=1788565380 "${COMMAND}"

assert_output \
  $'Up for 1 minute.\nRunning since Monday, September 7, 2026 at 3:59 AM.' \
  env TZ=UTC UPTIMEV_NOW_EPOCH="${NOW_EPOCH}" UPTIMEV_BOOT_EPOCH=1788753540 "${COMMAND}"

printf 'All uptimev checks passed.\n'
