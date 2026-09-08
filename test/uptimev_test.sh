#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
COMMAND=${UPTIMEV_TEST_COMMAND:-$PROJECT_DIR/uptime.sh}
# shellcheck source=uptime.sh
source "$COMMAND"

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT
unset UPTIMEV_BOOT_EPOCH UPTIMEV_NOW_EPOCH
export TZ=UTC LC_ALL=C
checks=0

assert_result() {
  local expected_status=$1 expected_output=$2 expected_error=$3
  local actual status=0 error
  shift 3
  actual=$("$@" 2>"$TEST_DIR/stderr") || status=$?
  error=$(<"$TEST_DIR/stderr")
  if [[ "$status" != "$expected_status" || "$actual" != "$expected_output" || "$error" != "$expected_error" ]]; then
    printf 'Failed: %s\nExpected status/stdout/stderr: %s / %s / %s\nActual: %s / %s / %s\n' \
      "$*" "$expected_status" "$expected_output" "$expected_error" "$status" "$actual" "$error" >&2
    exit 1
  fi
  checks=$((checks + 1))
}

expected=$'Up for 2 days, 4 hours, and 17 minutes.\nRunning since Friday, September 4, 2026 at 11:43 PM.'
for option in -v --version; do
  assert_result 0 "uptimev $UPTIMEV_VERSION" '' "$COMMAND" "$option"
done
for option in -h --help; do
  assert_result 0 "$(usage)" '' env UPTIMEV_NOW_EPOCH=invalid "$COMMAND" "$option"
done
for option in --unknown file.txt -- -hv; do
  assert_result 2 '' "uptimev: unknown option: $option; see --help" "$COMMAND" "$option"
done
assert_result 2 '' 'uptimev: unexpected empty argument; see --help' "$COMMAND" ''
assert_result 2 '' 'uptimev: expected at most one option; see --help' "$COMMAND" --help extra
assert_result 2 '' 'uptimev: expected at most one option; see --help' "$COMMAND" --version --help

assert_result 0 "$expected" '' env UPTIMEV_NOW_EPOCH=1788753600 UPTIMEV_BOOT_EPOCH=1788565380 "$COMMAND"
assert_result 0 "$expected" '' env UPTIMEV_NOW_EPOCH=01788753600 UPTIMEV_BOOT_EPOCH=01788565380 "$COMMAND"
assert_result 0 $'Up for 0 minutes.\nRunning since Thursday, January 1, 1970 at 12:00 AM.' '' \
  env UPTIMEV_NOW_EPOCH=0 UPTIMEV_BOOT_EPOCH=0 "$COMMAND"

# Every duration shape, including sub-minute uptime, carries, and singular/plural units.
while IFS='|' read -r seconds duration; do
  assert_result 0 "Up for $duration.
Running since Friday, September 4, 2026 at 11:43 PM." '' \
    env UPTIMEV_NOW_EPOCH="$((1788565380 + seconds))" UPTIMEV_BOOT_EPOCH=1788565380 "$COMMAND"
done <<'EOF'
0|0 minutes
59|0 minutes
60|1 minute
120|2 minutes
3599|59 minutes
3600|1 hour
3660|1 hour and 1 minute
7200|2 hours
86399|23 hours and 59 minutes
86400|1 day
86460|1 day and 1 minute
90000|1 day and 1 hour
90060|1 day, 1 hour, and 1 minute
172800|2 days
188220|2 days, 4 hours, and 17 minutes
EOF

for value in '' -1 abc 1.5 '1 + 2' 'parts[0]' 0x10 ' 60' 18446744073709551616; do
  assert_result 1 '' 'uptimev: current time must be a non-negative integer of at most 18 digits' \
    env UPTIMEV_NOW_EPOCH="$value" UPTIMEV_BOOT_EPOCH=0 "$COMMAND"
  assert_result 1 '' 'uptimev: system boot time must be a non-negative integer of at most 18 digits' \
    env UPTIMEV_NOW_EPOCH=1788753600 UPTIMEV_BOOT_EPOCH="$value" "$COMMAND"
done
assert_result 1 '' 'uptimev: the system boot time is in the future' \
  env UPTIMEV_NOW_EPOCH=0 UPTIMEV_BOOT_EPOCH=1 "$COMMAND"

# Exercise both kernel readers and command failures without changing the host clock or /proc.
mock_system() (
  local fixture_os=$1 boot_data=$2 clock_data=${3:-1788753600} failure=${4:-}
  unset UPTIMEV_BOOT_EPOCH UPTIMEV_NOW_EPOCH
  uname() {
    [[ "$failure" != uname ]] || return 1
    printf '%s\n' "$fixture_os"
  }
  function /usr/sbin/sysctl() {
    [[ "$*" == '-n kern.boottime' && "$failure" != boot ]] || return 1
    printf '%s\n' "$boot_data"
  }
  cat() {
    [[ "$1" == /proc/uptime && "$failure" != boot ]] || return 1
    printf '%s\n' "$boot_data"
  }
  date() {
    if [[ "$1" == +%s ]]; then
      [[ "$failure" != clock ]] || return 1
      printf '%s\n' "$clock_data"
    else
      [[ "$failure" != format ]] || return 1
      [[ "$failure" != empty_format ]] || return 0
      [[ "$LC_ALL" == C && "$2" == *1788565380 ]] || return 1
      case "$fixture_os:$1" in
        Darwin:-r|Linux:-d) printf 'Friday, September  4, 2026 at 11:43 PM\n' ;;
        *) return 1 ;;
      esac
    fi
  }
  # Invoked through the platform-specific command array.
  # shellcheck disable=SC2317,SC2329
  function /bin/date() { date "$@"; }
  main
)

assert_result 0 "$expected" '' mock_system Darwin '{ sec = 1788565380, usec = 123456 }'
assert_result 0 "$expected" '' mock_system Linux '188220.99 314159.20'
assert_result 1 '' 'uptimev: could not read the system boot time' mock_system Darwin '' 1788753600 boot
assert_result 1 '' 'uptimev: could not read /proc/uptime' mock_system Linux '' 1788753600 boot
for value in '' garbage '{ usec = 1788565380 }' '{ sec = -1, usec = 0 }'; do
  assert_result 1 '' 'uptimev: could not understand the system boot time' mock_system Darwin "$value"
done
for value in '' garbage '-1.0 0.0' '1+2.0 0.0'; do
  assert_result 1 '' 'uptimev: could not understand /proc/uptime' mock_system Linux "$value"
done
assert_result 1 '' 'uptimev: system uptime must be a non-negative integer of at most 18 digits' \
  mock_system Linux '18446744073709551616.0 0.0'
assert_result 1 '' 'uptimev: system uptime exceeds the current time' mock_system Linux '60.0 0.0' 59
assert_result 1 '' 'uptimev: unsupported operating system: FreeBSD' mock_system FreeBSD ''
assert_result 1 '' 'uptimev: could not determine the operating system' mock_system Linux '' 0 uname
assert_result 1 '' 'uptimev: could not read the current time' mock_system Linux '' 0 clock
assert_result 1 '' 'uptimev: current time must be a non-negative integer of at most 18 digits' mock_system Linux '' invalid
for failure in format empty_format; do
  assert_result 1 '' 'uptimev: could not format the system boot time' mock_system Linux '188220.0 0.0' 1788753600 "$failure"
done

# macOS must use BSD date even when GNU date shadows it on PATH.
mkdir "$TEST_DIR/bin"
cat >"$TEST_DIR/bin/date" <<'EOF'
#!/bin/sh
exit 1
EOF
chmod +x "$TEST_DIR/bin/date"
case "$(uname -s)" in
  Darwin)
    assert_result 0 "$expected" '' \
      env PATH="$TEST_DIR/bin:$PATH" UPTIMEV_NOW_EPOCH=1788753600 UPTIMEV_BOOT_EPOCH=1788565380 "$COMMAND"
    ;;
  Linux)
    assert_result 1 '' 'uptimev: could not format the system boot time' \
      env PATH="$TEST_DIR/bin:$PATH" UPTIMEV_NOW_EPOCH=1788753600 UPTIMEV_BOOT_EPOCH=1788565380 "$COMMAND"
    ;;
esac
assert_result 1 '' 'uptimev: could not read the current time' \
  env PATH="$TEST_DIR/bin:$PATH" UPTIMEV_BOOT_EPOCH=1788565380 "$COMMAND"

assert_result 0 $'Up for 1 minute.\nRunning since Monday, September 7, 2026 at 4:59 AM.' '' \
  env TZ=UTC-1 UPTIMEV_NOW_EPOCH=1788753600 UPTIMEV_BOOT_EPOCH=1788753540 "$COMMAND"
if locale -a | command grep -i '^fr_FR[.]utf' >/dev/null; then
  assert_result 0 "$expected" '' env LC_ALL=fr_FR.UTF-8 UPTIMEV_NOW_EPOCH=1788753600 UPTIMEV_BOOT_EPOCH=1788565380 "$COMMAND"
fi

# Installation must work without the repository or any sibling files.
mkdir -p "$TEST_DIR/install path/bin" "$TEST_DIR/links"
cp "$COMMAND" "$TEST_DIR/install path/bin/uptimev"
chmod +x "$TEST_DIR/install path/bin/uptimev"
ln -s '../install path/bin/uptimev' "$TEST_DIR/links/uptimev"
cd "$TEST_DIR"
assert_result 0 "$expected" '' env UPTIMEV_NOW_EPOCH=1788753600 UPTIMEV_BOOT_EPOCH=1788565380 "$TEST_DIR/links/uptimev"
assert_result 0 "uptimev $UPTIMEV_VERSION" '' env PATH="$TEST_DIR/links:$PATH" uptimev --version

printf 'All %s uptimev checks passed.\n' "$checks"
