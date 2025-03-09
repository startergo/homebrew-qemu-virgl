class Libangle < Formula
  desc "Conformant OpenGL ES implementation for multiple platforms"
  homepage "https://github.com/google/angle"
  url "https://github.com/google/angle.git",
      using: :git,
      revision: "fffbc739779a2df56a464fd6853bbfb24bebb5f6",
      submodules: false
  version "2025.03.08.1"
  license "BSD-3-Clause"

  bottle do
    root_url "https://github.com/startergo/homebrew-qemu-virgl/releases/download/libangle-2025.03.08.1"
    sha256 cellar: :any, arm64_big_sur: "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
    sha256 cellar: :any, big_sur:       "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
  end

  depends_on "ninja" => :build

  resource "depot_tools" do
    url "https://chromium.googlesource.com/chromium/tools/depot_tools.git",
        revision: "22df6f8e622dc3e8df8dc8b5d3e3503b169af78e"
  end

  def install
    # Stage depot_tools and add its directory to PATH.
    resource("depot_tools").stage do
      ENV.prepend_path "PATH", Dir.pwd
    end

    # Create and enter the source/angle directory.
    (buildpath/"source/angle").mkpath
    cd "source/angle" do
      # Initialize an empty repository and fetch the desired commit
      system "git", "init"
      system "git", "fetch", "https://chromium.googlesource.com/angle/angle", "fffbc739779a2df56a464fd6853bbfb24bebb5f6"
      system "git", "checkout", "FETCH_HEAD"

      # Disable depot_tools auto-update.
      ENV["DEPOT_TOOLS_UPDATE"] = "0"

      # Run bootstrap to set up additional required files.
      system "python3", "scripts/bootstrap.py"
      # Synchronize dependencies with the -D flag.
      system "gclient", "sync", "-D"
      # Generate build files with a release build (is_debug=false).
      system "gn", "gen", "--args=is_debug=false", "../../build/angle"
    end

    # Build ANGLE using ninja.
    system "ninja", "-C", "build/angle"

    # Install only the desired built libraries and headers.
    lib.install "#{buildpath}/build/angle/libabsl.dylib"
    lib.install "#{buildpath}/build/angle/libEGL.dylib"
    lib.install "#{buildpath}/build/angle/libGLESv2.dylib"
    lib.install "#{buildpath}/build/angle/libchrome_zlib.dylib"
    include.install Dir["source/angle/include/*"]
  end

  test do
    system "true"
  end
end