class Libangle < Formula
  desc "Conformant OpenGL ES implementation for multiple platforms"
  homepage "https://github.com/google/angle"
  # Use the GitHub tarball (which does not include submodules) to avoid internal submodule issues.
  url "https://github.com/google/angle/archive/fffbc739779a2df56a464fd6853bbfb24bebb5f6.tar.gz"
  sha256 "9e777ab3c55d89172c49c51786c9fc9ed71e9b12b05f0b0e8d16cb02cdc3f28b"
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
    # Stage depot_tools and prepend its path.
    resource("depot_tools").stage do
      ENV.prepend_path "PATH", Dir.pwd
    end

    # Detect the extracted source directory from the tarball.
    source_dir = Dir["angle-*"].first
    # If not found, assume the tarball did not create a subdirectory and use the current directory.
    source_dir = "." if source_dir.nil? || source_dir.empty?

    odie "Source directory not found" unless File.directory?(source_dir)

    cd source_dir do
      # Disable depot_tools auto-update.
      ENV["DEPOT_TOOLS_UPDATE"] = "0"
      # Run ANGLE's bootstrap script.
      system "python3", "scripts/bootstrap.py"
      # Synchronize dependencies (using '-D' to remove directories not in DEPS).
      system "gclient", "sync", "-D"
      # Generate build files for a release build.
      system "gn", "gen", "--args=is_debug=false", "../build/angle"
    end

    # Build ANGLE with ninja.
    system "ninja", "-C", "build/angle"

    # Install only the needed libraries.
    lib.install "#{buildpath}/build/angle/libabsl.dylib"
    lib.install "#{buildpath}/build/angle/libEGL.dylib"
    lib.install "#{buildpath}/build/angle/libGLESv2.dylib"
    lib.install "#{buildpath}/build/angle/libchrome_zlib.dylib"
    # Install header files.
    include.install Dir["#{source_dir}/include/*"]
  end

  test do
    system "true"
  end
end