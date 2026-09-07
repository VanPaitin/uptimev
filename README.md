# uptimev

`uptimev` shows how long your machine has been running and when it started, without making you decode the traditional `uptime` output.

```text
Up for 2 days, 4 hours, and 17 minutes.
Running since Friday, September 4, 2026 at 11:43 PM.
```

It supports macOS and Linux and has no runtime dependencies.

## Install with Homebrew

```sh
brew install VanPaitin/tap/uptimev
```

Then run:

```sh
uptimev
```

## Other commands

```sh
uptimev --help
uptimev --version
```

## Run from source

```sh
git clone https://github.com/VanPaitin/uptimev.git
cd uptimev
./uptime.sh
```

## How it works

On macOS, `uptimev` reads the kernel boot time. On Linux, it reads `/proc/uptime`. It calculates the elapsed days, hours, and minutes and prints the boot time in a readable format.

## Publishing a release

Maintainer steps:

1. Tag the source repository, for example `v0.1.0`.
2. Calculate the release archive's SHA-256:

```sh
curl -L https://github.com/VanPaitin/uptimev/archive/refs/tags/v0.1.0.tar.gz -o uptimev-0.1.0.tar.gz
shasum -a 256 uptimev-0.1.0.tar.gz
```

3. Update `Formula/uptimev.rb` with the checksum.
4. Copy the formula to `VanPaitin/homebrew-tap` and test the installation.

## License

[MIT](LICENSE)
