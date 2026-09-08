class Uptimev < Formula
  desc "Show system uptime and boot time in plain English"
  homepage "https://github.com/VanPaitin/uptimev"
  url "https://github.com/VanPaitin/uptimev/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "768fa54dde543b38ac3ea610b2e4f00a62af3dcabbaaf8816df8baaaec4c3f10"
  license "MIT"

  def install
    bin.install "uptime.sh" => "uptimev"
  end

  test do
    output = shell_output(bin/"uptimev")
    assert_match(/^Up for .+\.$/, output)
    assert_match(/^Running since .+\.$/, output)
    assert_equal "uptimev #{version}\n", shell_output("#{bin}/uptimev --version")

    ENV["TZ"] = "UTC"
    ENV["UPTIMEV_NOW_EPOCH"] = "1788753600"
    ENV["UPTIMEV_BOOT_EPOCH"] = "1788565380"
    assert_match <<~EOS, shell_output(bin/"uptimev")
      Up for 2 days, 4 hours, and 17 minutes.
      Running since Friday, September 4, 2026 at 11:43 PM.
    EOS
  end
end
