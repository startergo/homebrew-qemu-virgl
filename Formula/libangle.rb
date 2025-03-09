class Libangle < Formula
  desc "ANGLE - Almost Native Graphics Layer Engine"
  homepage "https://angleproject.org/"
  url "https://chromium.googlesource.com/angle/angle/+archive/refs/heads/main.tar.gz"
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

    # Run gclient sync -D
    ohai "Running gclient sync -D"
    system "gclient", "sync", "-D"

    # Create the output directory for gn
    build_dir = File.join(Dir.pwd, "out/Default")
    mkdir_p build_dir

    # Generate the build files
    gn_args = 'is_debug=false target_cpu="arm64"'
    ohai "Running gn gen with arguments: #{gn_args}"
    system "gn", "gen", build_dir, "--args=#{gn_args}"

    # Build the project
    ohai "Running ninja build"
    system "ninja", "-C", build_dir

    # Install the libraries
    lib.install Dir["#{build_dir}/lib*.dylib"]

    # Install the headers
    include.install Dir["include/*"]
  end

  test do
    # A simple test to verify that the library was installed.
    # This can be updated based on the actual binary or libraries installed.
    system "#{bin}/angle_info", "--version"
  end
end