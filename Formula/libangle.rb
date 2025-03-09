class Libangle < Formula
  desc "ANGLE - Almost Native Graphics Layer Engine"
  homepage "https://angleproject.org/"
  url "https://chromium.googlesource.com/angle/angle/+archive/refs/heads/main.tar.gz"
  sha256 "3a8c08be8e91adf590d603aed6976c6c9c515ea549dcc01a93b413b514aa59d1"
  version "main"  # Explicitly set the version attribute
  license "BSD-3-Clause"

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "python@3.11" => :build

  def install
    # Download the tarball and save it
    system "curl", "-LO", url

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
    # This can be updated based on the actual binary or libraries installed.
    system "#{bin}/angle_info", "--version"
  end
end