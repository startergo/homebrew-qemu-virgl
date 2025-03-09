class Libangle < Formula
  desc "ANGLE - Almost Native Graphics Layer Engine"
  homepage "https://angleproject.org/"
  url "https://chromium.googlesource.com/angle/angle/+archive/refs/heads/main.tar.gz"
  version "main"
  license "BSD-3-Clause"

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "python@3.11" => :build

  resource "bootstrap_script" do
    url "https://example.com/bootstrap.sh"
    sha256 "placeholder_for_actual_sha256"
  end

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

    # Create a custom script to handle gclient sync and gn gen
    (buildpath/"bootstrap.sh").write <<~EOS
      #!/bin/bash
      set -e
      echo "Running gclient sync -D"
      gclient sync -D
      echo "Running gn gen with args: --args=is_debug=false target_cpu=\\\"arm64\\\""
      gn gen out/Default --args="is_debug=false target_cpu=\\\"arm64\\\""
    EOS
    chmod "+x", buildpath/"bootstrap.sh"

    # Run the custom script
    system "./bootstrap.sh"

    # Build the project
    ohai "Running ninja build"
    system "ninja", "-C", "out/Default"

    # Install the libraries
    lib.install Dir["out/Default/lib*.dylib"]

    # Install the headers
    include.install Dir["include/*"]
  end

  test do
    # A simple test to verify that the library was installed.
    # This can be updated based on the actual binary or libraries installed.
    system "#{bin}/angle_info", "--version"
  end
end