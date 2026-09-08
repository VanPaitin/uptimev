class Uptimev < Formula
  desc "Show current time, uptime, boot time, and load averages"
  homepage "https://github.com/VanPaitin/uptimev"
  url "https://github.com/VanPaitin/uptimev/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "d752243f2779dfc22d862bea5c75053505982a22ae9f829171bab70423c4a633"
  license "MIT"

  def install
    bin.install "uptime.sh" => "uptimev"
  end

  test do
    output = shell_output(bin/"uptimev")
    assert_match(/^Current time: .+\.$/, output)
    assert_match(/^Up for .+\.$/, output)
    assert_match(/^Running since .+\.$/, output)
    assert_match(/^Load averages \(1, 5, 15 min\): .+\.$/, output)
    assert_equal "uptimev #{version}\n", shell_output("#{bin}/uptimev --version")

    ENV["TZ"] = "UTC"
    ENV["UPTIMEV_NOW_EPOCH"] = "1788753600"
    ENV["UPTIMEV_BOOT_EPOCH"] = "1788565380"
    ENV["UPTIMEV_LOAD_AVERAGES"] = "0.42 0.35 0.28"
    assert_equal <<~EOS, shell_output(bin/"uptimev")
      Current time: 4:00:00 AM UTC.
      Up for 2 days, 4 hours, and 17 minutes.
      Running since Friday, September 4, 2026 at 11:43 PM.
      Load averages (1, 5, 15 min): 0.42, 0.35, 0.28.
    EOS
  end
end
