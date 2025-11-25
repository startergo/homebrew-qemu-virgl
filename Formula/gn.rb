class Gn < Formula
  desc "Meta-build system that generates build files for Ninja"
  homepage "https://gn.googlesource.com/gn"
  url "https://gn.googlesource.com/gn.git",
      using: :git,
      branch: "main"
  version "2025.11.24"
  license "BSD-3-Clause"

  depends_on "ninja" => :build
  depends_on "python@3.13" => :build

  def install
    system "python3", "build/gen.py"
    system "ninja", "-C", "out"
    bin.install "out/gn"
  end

  test do
    (testpath/"test.gn").write <<~EOS
      print("Hello from gn")
    EOS
    system bin/"gn", "format", "test.gn"
  end
end
