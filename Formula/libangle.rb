class Libangle < Formula
  desc "Conformant OpenGL ES implementation for multiple platforms"
  homepage "https://github.com/google/angle"
  # Use the GitHub tarball for a specific commit. Tarballs do not include submodules.
  url "https://github.com/google/angle/archive/fffbc739779a2df56a464fd6853bbfb24bebb5f6.tar.gz"
  version "2025.03.08.1"
  license "BSD-3-Clause"
  head "https://github.com/google/angle.git", branch: "master"

  bottle do
    root_url "https://github.com/startergo/homebrew-qemu-virgl/releases/download/libangle-2025.03.08.1"
    sha256 cellar: :any, arm64_big_sur: "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
    sha256 cellar: :any, big_sur:       "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
  end

  depends_on "ninja" => :build
  depends_on "python@3.10" => :build

  resource "depot_tools" do
    url "https://chromium.googlesource.com/chromium/tools/depot_tools.git",
        revision: "22df6f8e622dc3e8df8dc8b5d3e3503b169af78e"
  end

  def install
    # Stage depot_tools and add its directory to PATH.
    resource("depot_tools").stage do
      ENV.prepend_path "PATH", Dir.pwd
    end

    # Find the extracted source directory (tarballs are extracted into a directory that starts with "angle-").
    source_dir = Dir["angle-*"].first
    raise "Source directory not found" unless source_dir

    cd source_dir do
      # Disable depot_tools auto-update.
      ENV["DEPOT_TOOLS_UPDATE"] = "0"
      # Run the bootstrap script to set up additional required files.
      system "python3", "scripts/bootstrap.py"
      # Synchronize dependencies (with the -D flag to remove directories not in DEPS).
      system "gclient", "sync", "-D"
      # Generate build files for a release build (is_debug=false).
      system "gn", "gen", "--args=is_debug=false", "../build/angle"
    end

    # Build ANGLE using ninja.
    system "ninja", "-C", "build/angle"

    # Install only the desired built libraries.
    lib.install "#{buildpath}/build/angle/libabsl.dylib"
    lib.install "#{buildpath}/build/angle/libEGL.dylib"
    lib.install "#{buildpath}/build/angle/libGLESv2.dylib"
    lib.install "#{buildpath}/build/angle/libchrome_zlib.dylib"
    # Install headers from the source directory.
    include.install Dir["#{source_dir}/include/*"]
  end

  test do
    system "true"
  end
end