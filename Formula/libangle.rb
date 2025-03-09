\class Libangle < Formula
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
  # Get the path of the cached tarball
  tarball_path = cached_download
  ohai "Using cached download: #{tarball_path}"

  # List the contents of the tarball
  ohai "Contents of the tarball:"
  system "tar", "tvf", tarball_path

  # Extract the tarball
  ohai "Extracting tarball: #{tarball_path}"
  system "tar", "xvf", tarball_path

  # List the contents of the current directory after extraction
  ohai "Contents of the current directory after extraction:"
  system "ls", "-l"

  # Verify if the extraction was successful
  extracted_dir = Dir.glob("*").find { |f| File.directory?(f) && f.include?("angle") }
  unless extracted_dir
    odie "Tarball extraction failed! No directory found containing 'angle'"
  end
  ohai "Extraction successful, found directory: #{extracted_dir}"

  # Create the build directory
  mkdir "build" do
    # Generate the build files
    gn_args = "--args=use_custom_libcxx=false treat_warnings_as_errors=false"
    gn_args += ' target_cpu="arm64"' if Hardware::CPU.arm?
    ohai "Running gn gen with arguments: #{gn_args}"
    system "gn", "gen", gn_args, "../" do |status, output|
      puts output
      raise "gn gen failed!" unless status.success?
    end

    # Build the project
    ohai "Running ninja build"
    system "ninja", "-C", "." do |status, output|
      puts output
      raise "ninja build failed!" unless status.success?
    end

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