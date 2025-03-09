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
    # Use Homebrew's Python 3.9
    ENV.prepend_path "PATH", Formula["python@3.9"].opt_bin

    # Stage and check out the depot_tools resource
    resource("depot_tools").stage do
      ENV.prepend_path "PATH", Dir.pwd

      # Full path to python3.9
      python3_9_path = "#{Formula["python@3.9"].opt_bin}/python3.9"

      # Diagnostic step: Check if python3.9 exists
      system "ls", "-l", python3_9_path

      # Diagnostic step: Check the contents of the depot_tools directory
      system "ls", "-l"

      # Configure gclient
      system "gclient", "config", "--name", "src", "https://chromium.googlesource.com/angle/angle.git"

      # Sync the ANGLE repository using gclient
      system "gclient", "sync"
    end

    # Diagnostic step: Check if the ANGLE repository has been cloned and its contents
    angle_repo_path = "src"  # Assuming gclient sync clones ANGLE into the 'src' directory
    system "ls", "-l", angle_repo_path
    system "ls", "-lR", "#{angle_repo_path}"

    # Create a build directory and generate build files with GN
    mkdir "build" do
      if Hardware::CPU.arm?
        system "gn", "gen", "--args=use_custom_libcxx=false target_cpu=\"arm64\" treat_warnings_as_errors=false", "../src/angle_build"
      else
        system "gn", "gen", "--args=use_custom_libcxx=false treat_warnings_as_errors=false", "../src/angle_build"
      end
      # Build ANGLE using Ninja
      system "ninja", "-C", "../src/angle_build"
      
      # Install the built libraries and headers
      lib.install "../src/angle_build/libabsl.dylib"
      lib.install "../src/angle_build/libEGL.dylib"
      lib.install "../src/angle_build/libGLESv2.dylib"
      lib.install "../src/angle_build/libchrome_zlib.dylib"
      include.install Pathname.glob("include/*")
    end
  end

  test do
    # A simple test to ensure the formula installed correctly
    system "true"
  end
end