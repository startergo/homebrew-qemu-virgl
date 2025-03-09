class Libangle < Formula
  desc "ANGLE - Almost Native Graphics Layer Engine"
  homepage "https://angleproject.org/"
  url "https://chromium.googlesource.com/angle/angle/+archive/refs/heads/main.tar.gz"
  sha256 "3a8c08be8e91adf590d603aed6976c6c9c515ea549dcc01a93b413b514aa59d1"
  version "main"
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
    current_dir_contents = `ls -l`
    ohai "Contents of the current directory after extraction:\n#{current_dir_contents}"

    # Check for extracted files
    extracted_files = Dir.glob("*")
    if extracted_files.empty?
      odie "Tarball extraction failed! No files extracted."
    end

    # Ensure the correct PATH is used
    ENV.prepend_path "PATH", "/Users/macbookpro/depot_tools"

    # Create the build directory
    mkdir "build" do
      # Generate the build files
      gn_args = "--args=use_custom_libcxx=false treat_warnings_as_errors=false"
      gn_args += ' target_cpu="arm64"' if Hardware::CPU.arm?
      ohai "Running gn gen with arguments: #{gn_args}"

      # Specify the output directory for gn
      gn_output = `gn gen out/Default #{gn_args} 2>&1`
      puts gn_output
      raise "gn gen failed!" unless $?.success?

      # Build the project
      ohai "Running ninja build"
      ninja_output = `ninja -C out/Default 2>&1`
      puts ninja_output
      raise "ninja build failed!" unless $?.success?

      # Install the libraries
      lib.install "out/Default/libabsl.dylib"
      lib.install "out/Default/libEGL.dylib"
      lib.install "out/Default/libGLESv2.dylib"
      lib.install "out/Default/libchrome_zlib.dylib"

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