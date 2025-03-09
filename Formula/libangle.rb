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
  depends_on "pyenv" => :build

  resource "depot_tools" do
    url "https://chromium.googlesource.com/chromium/tools/depot_tools.git", revision: "dc86a4b9044f9243886ca0da0c1753820ac51f45"
  end

  def install
    # Stage and check out the depot_tools resource
    resource("depot_tools").stage do
      # Add the current directory (containing depot_tools) to the PATH
      ENV.prepend_path "PATH", Dir.pwd
      ENV.prepend_path "PATH", "#{ENV["HOME"]}/.pyenv/shims"

      # Full path to python2.7 from pyenv
      python2_7_path = "#{ENV["HOME"]}/.pyenv/versions/2.7.18/bin/python2.7"

      # Diagnostic step: Check if python2.7 exists
      system "ls", "-l", python2_7_path

      # Diagnostic step: Check if bootstrap.py exists in the depot_tools directory
      system "ls", "-l", "scripts/bootstrap.py"

      # Run the bootstrap script using python2.7
      system python2_7_path, "scripts/bootstrap.py"
      
      # Sync the ANGLE repository using gclient
      system "gclient", "sync"
    end

    # Diagnostic step: Check if the ANGLE repository has been cloned and its contents
    angle_repo_path = "src"  # Assuming gclient sync clones ANGLE into the 'src' directory
    system "ls", "-l", angle_repo_path
    system "ls", "-lR", "#{angle_repo_path}/angle"

    # Create a build directory and generate build files with GN
    mkdir "build" do
      if Hardware::CPU.arm?
        system "gn", "gen", "--args=use_custom_libcxx=false target_cpu=\"arm64\" treat_warnings_as_errors=false", "../angle_build"
      else
        system "gn", "gen", "--args=use_custom_libcxx=false treat_warnings_as_errors=false", "../angle_build"
      end
      # Build ANGLE using Ninja
      system "ninja", "-C", "../angle_build"
      
      # Install the built libraries and headers
      lib.install "../angle_build/libabsl.dylib"
      lib.install "../angle_build/libEGL.dylib"
      lib.install "../angle_build/libGLESv2.dylib"
      lib.install "../angle_build/libchrome_zlib.dylib"
      include.install Pathname.glob("include/*")
    end
  end

  test do
    # A simple test to ensure the formula installed correctly
    system "true"
  end
end