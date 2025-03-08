class Libangle < Formula
  desc "Conformant OpenGL ES implementation for Windows, Mac, Linux, iOS and Android"
  homepage "https://github.com/google/angle"
  url "https://github.com/google/angle.git", using: :git, revision: "df0f7133799ca6aa0d31802b22d919c6197051cf"
  version "2025.03.08.1"
  license "BSD-3-Clause"

  bottle do
    root_url "https://github.com/startergo/homebrew-qemu-virgl/releases/download/libangle-2025.03.08.1"
    sha256 cellar: :any, arm64_big_sur: "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
    sha256 cellar: :any, big_sur:       "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build

  resource "depot_tools" do
    url "https://chromium.googlesource.com/chromium/tools/depot_tools.git", revision: "dc86a4b9044f9243886ca0da0c1753820ac51f45"
  end

  def install
    mkdir "build" do
      resource("depot_tools").stage do
        # Append the current directory (depot_tools) to the PATH.
        path = PATH.new(ENV["PATH"], Dir.pwd)
        with_env(PATH: path) do
          Dir.chdir(buildpath)

          system "python2", "scripts/bootstrap.py"
          system "gclient", "sync"
          if Hardware::CPU.arm?
            system "gn", "gen", "--args=use_custom_libcxx=false target_cpu=\"arm64\" treat_warnings_as_errors=false", "./angle_build"
          else
            system "gn", "gen", "--args=use_custom_libcxx=false treat_warnings_as_errors=false", "./angle_build"
          end
          system "ninja", "-C", "angle_build"
          lib.install "angle_build/libabsl.dylib"
          lib.install "angle_build/libEGL.dylib"
          lib.install "angle_build/libGLESv2.dylib"
          lib.install "angle_build/libchrome_zlib.dylib"
          include.install Pathname.glob("include/*")
        end
      end
    end
  end

  test do
    system "true"
  end
end