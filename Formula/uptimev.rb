class Uptimev < Formula
  desc "Print a friendly summary of how long this machine has been running"
  homepage "https://github.com/VanPaitin/uptimev"
  url "https://github.com/VanPaitin/uptimev/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "REPLACE_WITH_SHA256_AFTER_YOU_CREATE_THE_RELEASE_TARBALL"
  license "MIT"

  def install
    bin.install "uptime.sh" => "uptimev"
  end

  test do
    assert_match "Up for ", shell_output("#{bin}/uptimev")
    assert_match version.to_s, shell_output("#{bin}/uptimev --version")
  end
end
