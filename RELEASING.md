# Releases

Use `MAJOR.MINOR.PATCH` versions and matching `vMAJOR.MINOR.PATCH` tags.
`UPTIMEV_VERSION` in `uptime.sh` is the source of the CLI version. Bump it in the
release commit; do not move an existing tag. Keep the formula pinned to the
latest published archive until a new archive and checksum exist.

1. Update the version and [changelog](CHANGELOG.md), run the checks in the README,
   and confirm macOS and Linux CI pass for the release commit.
2. Commit and push the release source, then publish its tag. For example, after
   setting the version to `0.1.1`:

   ```sh
   version=0.1.1
   test "$(./uptime.sh --version)" = "uptimev $version"
   git tag -a "v$version" -m "uptimev $version"
   git push origin "v$version"
   ```

3. Download the published archive and calculate its checksum. `--fail` prevents
   accidentally hashing an HTTP error page:

   ```sh
   archive="${TMPDIR:-/tmp}/uptimev-$version.tar.gz"
   curl --fail --location --show-error \
     "https://github.com/VanPaitin/uptimev/archive/refs/tags/v$version.tar.gz" \
     --output "$archive"
   shasum -a 256 "$archive"
   ```

4. Extract that archive to a temporary directory and run its tests and
   `./uptime.sh --version`. Update both `url` and `sha256` in `Formula/uptimev.rb`
   from this verified artifact. Commit the formula update after the source tag;
   the archive cannot contain its own checksum.
5. Copy the formula into a local checkout of `VanPaitin/homebrew-tap`. With that
   checkout registered as a Homebrew tap, validate it by name:

   ```sh
   brew style VanPaitin/tap/uptimev
   brew audit --strict --online VanPaitin/tap/uptimev
   brew install --build-from-source VanPaitin/tap/uptimev
   brew test VanPaitin/tap/uptimev
   ```

   Use `brew reinstall --build-from-source` if already installed. Run these
   checks on macOS and Linux. The formula test checks live uptime and exact
   deterministic output; testing a source checkout alone does not test the
   downloaded package.
6. Push the tested tap update and publish release notes. Verify the README's
   install command from a clean Homebrew environment.

Homebrew references: [Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
and [maintaining a tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap).
