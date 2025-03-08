class Libangle < Formula
  desc "Conformant OpenGL ES implementation for Windows, Mac, Linux, iOS and Android"
  homepage "https://github.com/google/angle"
  url "https://github.com/google/angle.git", using: :git, revision: "fffbc739779a2df56a464fd6853bbfb24bebb5f6"
  version "2025.03.08.1"
  license "BSD-3-Clause"

  bottle do
    root_url "https://github.com/startergo/homebrew-qemu-virgl/releases/download/libangle-2025.03.08.1"
    sha256 cellar: :any, arm64_big_sur: "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
    sha256 cellar: :any, big_sur:       "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
  end

  depends_on "python@2" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build

  resource "depot_tools" do
    url "https://chromium.googlesource.com/chromium/tools/depot_tools.git",
        revision: "22df6f8e622dc3e8df8dc8b5d3e3503b169af78e"
  end

  def install
    # Stage depot_tools resource and prepend its directory to PATH.
    resource("depot_tools").stage do
      ENV.prepend_path "PATH", Dir.pwd
    end

    # Run bootstrap and sync commands using Python 2.
    system "python2", "scripts/bootstrap.py"
    system "gclient", "sync"

    build_dir = "angle_build"
    args = if Hardware::CPU.arm?
             "use_custom_libcxx=false target_cpu=\"arm64\" treat_warnings_as_errors=false"
           else
             "use_custom_libcxx=false treat_warnings_as_errors=false"
           end

    system "gn", "gen", "--args=#{args}", build_dir
    system "ninja", "-C", build_dir

    # Install the built libraries and headers.
    lib.install "#{build_dir}/libabsl.dylib"
    lib.install "#{build_dir}/libEGL.dylib"
    lib.install "#{build_dir}/libGLESv2.dylib"
    lib.install "#{build_dir}/libchrome_zlib.dylib"
    include.install Dir["include/*"]
  end

  test do
    system "true"
  end
end