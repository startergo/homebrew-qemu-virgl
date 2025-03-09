class Libangle < Formula
  desc "ANGLE - Almost Native Graphics Layer Engine"
  homepage "https://angleproject.org/"
  # Use the tarball archive from googlesource.com (main branch)
  url "https://chromium.googlesource.com/angle/angle/+archive/refs/heads/main.tar.gz"
  sha256 "bf2977405d80b6ebf75cb71908ac883c7b4da6307806c3800795a9a0eaa88940"
  license "BSD-3-Clause"

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "python@3.11" => :build

  def install
    # Extract the tarball
    system "tar", "xvf", "main.tar.gz"

    # Create the build directory
    mkdir "build" do
      # Generate the build files
      if Hardware::CPU.arm?
        system "gn", "gen", "--args=use_custom_libcxx=false target_cpu=\"arm64\" treat_warnings_as_errors=false", "../"
      else
        system "gn", "gen", "--args=use_custom_libcxx=false treat_warnings_as_errors=false", "../"
      end

      # Build the project
      system "ninja", "-C", "."

      # Install the libraries
      lib.install "libabsl.dylib"
      lib.install "libEGL.dylib"
      lib.install "libGLESv2.dylib"
      lib.install "libchrome_zlib.dylib"

      # Install the headers
      include.install Pathname.glob("../include/*")
    end
  end

  test do
    # A simple test to verify that the library was installed.
    # This can be updated based on the actual installation output.
    system "#{bin}/angle_info", "--version"
  end
end