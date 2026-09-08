# Changelog

## Unreleased

- Show the current local time with seconds and timezone.
- Show the 1-, 5-, and 15-minute load averages on macOS and Linux.

## 0.1.1 — 2026-09-08

- Reject invalid and extra arguments with exit code 2.
- Validate timestamps before arithmetic, including overflow and leading zeros.
- Report system and date failures without partial output or false success.
- Read the current time once and keep prose consistently in English.
- Use the native macOS date formatter when GNU tools shadow system commands.
- Remove unused Ruby helpers and simplify duration formatting.
- Expand regression tests, formula checks, and installation/release guidance.

## 0.1.0 — 2026-09-07

- Initial standalone Bash CLI for macOS and Linux, with Homebrew distribution.
