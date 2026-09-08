# uptimev

`uptimev` prints your machine's uptime and boot time in plain English.

```text
Up for 2 days, 4 hours, and 17 minutes.
Running since Friday, September 4, 2026 at 11:43 PM.
```

Works on macOS and Linux with Bash 3.2 or newer and standard system tools.
Linux requires GNU `date` and a readable `/proc/uptime`; BusyBox-only systems
are not supported. No Ruby or other language runtime is needed.

## Install with Homebrew

```sh
brew install VanPaitin/tap/uptimev
```

## Usage

```sh
uptimev
uptimev --help
uptimev --version
```

`-h` and `-v` are aliases for help and version. Output uses your local timezone;
use `TZ=UTC uptimev` for UTC. Durations are rounded down to whole minutes,
so a freshly booted machine shows `0 minutes`.

Exit codes: `0` for success, `1` for a system or timestamp error, and `2` for
invalid arguments. Errors go to stderr without a partial uptime summary.

## Install from source

```sh
git clone https://github.com/VanPaitin/uptimev.git
cd uptimev
./uptime.sh
```

The script is self-contained. To install it for your user:

```sh
mkdir -p "$HOME/.local/bin"
install -m 755 uptime.sh "$HOME/.local/bin/uptimev"
```

Add `$HOME/.local/bin` to your `PATH` if needed. The default branch may contain
unreleased changes; Homebrew installs the tagged release pinned in the formula.

## How it works

macOS provides the kernel boot timestamp via `sysctl kern.boottime`. Linux
provides elapsed seconds via `/proc/uptime`, from which `uptimev` estimates the
boot timestamp using the current clock. Sleep time is included. Clock changes
can affect the displayed boot time; containers report the uptime exposed by
their `/proc` mount and time namespace, not when the container process started.

## Development

```sh
bash -n uptime.sh
bash -n test/uptimev_test.sh
bash test/uptimev_test.sh
shellcheck uptime.sh test/uptimev_test.sh
```

Tests cover formatting, invalid inputs, system failures, both platform readers,
and copied/symlinked installations. CI runs on macOS and Ubuntu and reads the
real system uptime on both.

For deterministic checks, `UPTIMEV_BOOT_EPOCH` and `UPTIMEV_NOW_EPOCH` override
the boot and current Unix timestamps. Values must contain 1–18 decimal digits;
leading zeros are accepted. Leave them unset for normal use. To test an installed
copy, run `UPTIMEV_TEST_COMMAND=/absolute/path/to/uptimev bash test/uptimev_test.sh`.

See [RELEASING.md](RELEASING.md) for versioning and Homebrew release steps.

## License

[MIT](LICENSE)
