class Libangle < Formula
  desc "Conformant OpenGL ES implementation for Windows, Mac, Linux, iOS and Android"
  homepage "https://github.com/google/angle"
  # Use the ANGLE Git repository with the provided revision.
  url "https://github.com/google/angle.git",
      branch: "main",
      using: :git
  version "head"
  license "BSD-3-Clause"

  bottle do
    root_url "https://github.com/startergo/homebrew-qemu-virgl/releases/download/libangle-2025.03.09.1"
    sha256 cellar: :any, arm64_big_sur: "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
    sha256 cellar: :any, big_sur:       "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  # Ensure we use Python 3 (as Python 2 has been deprecated on modern systems).

  resource "depot_tools" do
    url "https://chromium.googlesource.com/chromium/tools/depot_tools.git", revision: "dc86a4b9044f9243886ca0da0c1753820ac51f45"
  end

  def install
    mkdir "build" do
      resource("depot_tools").stage do
        # Extend the PATH so depot_tools (i.e. gclient) is available.
        path = PATH.new(ENV["PATH"], Dir.pwd)
        with_env(PATH: path) do
          # Change directory to the buildpath root where the ANGLE code is checked out.
          Dir.chdir(buildpath) do
            # Run the bootstrap script with python3.
            system "python3", "scripts/bootstrap.py"
            # Run gclient sync to fetch dependencies. depot_tools will use python3.
            system "gclient", "sync"
            
            # Generate build files using GN.
            if Hardware::CPU.arm?
              system "gn", "gen", "--args=use_custom_libcxx=false target_cpu=\"arm64\" treat_warnings_as_errors=false",
                     "./angle_build"
            else
              system "gn", "gen", "--args=use_custom_libcxx=false treat_warnings_as_errors=false",
                     "./angle_build"
            end

            # Build ANGLE using ninja.
            system "ninja", "-C", "angle_build"

            # Install the built libraries.
            lib.install "angle_build/libabsl.dylib"
            lib.install "angle_build/libEGL.dylib"
            lib.install "angle_build/libGLESv2.dylib"
            lib.install "angle_build/libchrome_zlib.dylib"

            # Install header files.
            include.install Dir["include/*"]
          end
        end
      end
    end
  end

  test do
    system "true"
  end
end