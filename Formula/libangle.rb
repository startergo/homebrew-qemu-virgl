class Libangle < Formula
  desc "Conformant OpenGL ES implementation for Windows, Mac, Linux, iOS and Android"
  homepage "https://github.com/google/angle"
  # Using the latest revision from the ANGLE git repository on the main branch.
  url "https://github.com/google/angle.git",
      branch: "main",
      using: :git
  version "head"
  license "BSD-3-Clause"

  bottle do
    root_url "https://github.com/startergo/homebrew-qemu-virgl/releases/download/libangle-head"
    sha256 cellar: :any, arm64_big_sur: "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
    sha256 cellar: :any, big_sur:       "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "python@3.10" => :build

  # This resource provides depot_tools required for bootstrapping and syncing additional dependencies.
  resource "depot_tools" do
    url "https://chromium.googlesource.com/chromium/tools/depot_tools.git",
        revision: "dc86a4b9044f9243886ca0da0c1753820ac51f45"
  end

  # Helper method to list directory contents.
  def list_dir(path = ".")
    ohai "Listing contents of #{File.expand_path(path)}:"
    system "ls", "-la", path
  end

  def install
    # Prefer using the cached depot_tools in Homebrew's cache.
    depot_tools_cache = HOMEBREW_CACHE/"libangle--depot_tools--git"
    if depot_tools_cache.directory?
      opoo "Using cached depot_tools at: #{depot_tools_cache}"
      depot_tools_dir = depot_tools_cache
    else
      resource("depot_tools").stage do
        depot_tools_dir = buildpath/"depot_tools"
        depot_tools_dir.install Dir["*"]
      end
    end

    # Add depot_tools to the PATH.
    ENV.prepend_path "PATH", depot_tools_dir

    # Log the depot_tools location and current source root.
    ohai "Depot_tools installed at: #{depot_tools_dir}"
    list_dir(depot_tools_dir)
    ohai "Source root is: #{buildpath}"
    list_dir(buildpath)

    # Patch the DEPS file to skip the internal es-cts dependency.
    # The es-cts module is hosted on chrome-internal.googlesource.com and required permissions are not available for public builds.
    if File.exist?("DEPS")
      opoo "Patching DEPS file to disable internal es-cts dependency"
      inreplace "DEPS", /('angle\/es-cts'\s*:\s*\{)/, "# \\1"
    end

    # Create a build directory and proceed with the build steps.
    mkdir "build" do
      # Run ANGLE's bootstrap script with Python 3.
      system "python3", "scripts/bootstrap.py"
      # Synchronize dependencies using depot_tools's gclient.
      system "gclient", "sync"

      # Generate GN build files using the appropriate arguments.
      if Hardware::CPU.arm?
        system "gn", "gen", "--args=use_custom_libcxx=false target_cpu=\"arm64\" treat_warnings_as_errors=false", "./angle_build"
      else
        system "gn", "gen", "--args=use_custom_libcxx=false treat_warnings_as_errors=false", "./angle_build"
      end

      # Build the project with ninja.
      system "ninja", "-C", "angle_build"

      # Install built libraries.
      lib.install "angle_build/libabsl.dylib"
      lib.install "angle_build/libEGL.dylib"
      lib.install "angle_build/libGLESv2.dylib"
      lib.install "angle_build/libchrome_zlib.dylib"

      # Install header files.
      include.install Dir["include/*"]
    end
  end

  test do
    system "true"
  end
end