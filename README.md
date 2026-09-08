# uptimev

A human-readable alternative to the Unix `uptime` command for macOS and Linux.

![uptimev showing current time, uptime, boot time, and load averages](assets/uptimev-demo.gif)

Requires Bash 3.2+ and standard system tools. Linux also needs GNU `date` and
readable `/proc/uptime` and `/proc/loadavg`; BusyBox-only systems are not supported.

## Install with Homebrew

```sh
brew install VanPaitin/tap/uptimev
uptimev --version
```

To upgrade:

```sh
brew update
brew upgrade VanPaitin/tap/uptimev
```

## Usage

```sh
uptimev
uptimev --help
```

`-h` shows help; `-v` shows the version. Times use your local timezone
(`TZ=UTC uptimev` for UTC). Durations round down to whole minutes.

Exit codes: `0` success, `1` system or timestamp error, `2` invalid arguments.
Errors go to stderr without a partial summary.

## Install from source

```sh
git clone https://github.com/VanPaitin/uptimev.git
cd uptimev
./uptime.sh
```

To install the standalone script:

```sh
mkdir -p "$HOME/.local/bin"
install -m 755 uptime.sh "$HOME/.local/bin/uptimev"
```

Add `$HOME/.local/bin` to your `PATH`. The default branch may contain unreleased
changes; Homebrew installs the release pinned in the tap.

## How it works

Reads boot time and load averages through `sysctl` on macOS and `/proc` on
Linux. Load averages cover 1, 5, and 15 minutes. Sleep counts toward uptime;
clock changes can affect the reported boot time. Containers use the system
metrics exposed by their `/proc` mount.

## Development

```sh
bash test/uptimev_test.sh
shellcheck uptime.sh test/uptimev_test.sh
```

Install ShellCheck to run lint checks. CI tests macOS and Linux, including live
uptime, failures, and standalone installations.

`UPTIMEV_BOOT_EPOCH` and `UPTIMEV_NOW_EPOCH` override Unix timestamps for tests.
Use 1–18 decimal digits; leading zeros are accepted. `UPTIMEV_LOAD_AVERAGES`
accepts three space-separated non-negative decimal values. Leave these overrides unset
for normal use. To test an installed copy, run
`UPTIMEV_TEST_COMMAND=/absolute/path/to/uptimev bash test/uptimev_test.sh`.

[Release guide](RELEASING.md)

## License

Licensed under the [MIT License](LICENSE).
