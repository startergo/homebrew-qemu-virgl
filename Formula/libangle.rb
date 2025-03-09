class Libangle < Formula
  desc "Conformant OpenGL ES implementation for Windows, Mac, Linux, iOS and Android"
  homepage "https://github.com/google/angle"
  url "https://github.com/google/angle.git", using: :git, revision: "df0f7133799ca6aa0d31802b22d919c6197051cf"
  version "20250309.1"
  license "BSD-3-Clause"

  bottle do
    root_url "https://github.com/startergo/homebrew-qemu-virgl/releases/download/libangle-20250309.1"
    sha256 cellar: :any, arm64_sequoia: "748d93eeabbc36f740e84338393deea0167c49da70e069708c54f5767003d12f"
    sha256 cellar: :any, monterey: "748d93eeabbc36f740e84338393deea0167c49da70e069708c54f5767003d12f"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "python@3.9" => :build

  resource "depot_tools" do
    url "https://chromium.googlesource.com/chromium/tools/depot_tools.git", revision: "dc86a4b9044f9243886ca0da0c1753820ac51f45"
  end

  def install
    resource("depot_tools").stage do
      ENV.prepend_path "PATH", Dir.pwd
      system "python3", "scripts/bootstrap.py"
      system "gclient", "sync"
    end

    mkdir "build" do
      if Hardware::CPU.arm?
        system "gn", "gen", "--args=use_custom_libcxx=false target_cpu=\"arm64\" treat_warnings_as_errors=false", "../angle_build"
      else
        system "gn", "gen", "--args=use_custom_libcxx=false treat_warnings_as_errors=false", "../angle_build"
      end
      system "ninja", "-C", "../angle_build"
      lib.install "../angle_build/libabsl.dylib"
      lib.install "../angle_build/libEGL.dylib"
      lib.install "../angle_build/libGLESv2.dylib"
      lib.install "../angle_build/libchrome_zlib.dylib"
      include.install Pathname.glob("include/*")
    end
  end

  test do
    system "true"
  end
end