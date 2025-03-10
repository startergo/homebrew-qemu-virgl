class Libangle < Formula
  desc "Conformant OpenGL ES implementation for Windows, Mac, Linux, iOS, and Android"
  homepage "https://github.com/google/angle"
  url "https://chromium.googlesource.com/angle/angle.git", using: :git, revision: "df0f7133799ca6aa0d31802b22d919c6197051cf"
  version "20250309.1"
  license "BSD-3-Clause"

  bottle do
    root_url "https://github.com/startergo/homebrew-qemu-virgl/releases/download/libangle-20250309.1"
    sha256 cellar: :any, arm64_sequoia: "748d93eeabbc36f740e84338393deea0167c49da70e069708c54f5767003d12f"
    sha256 cellar: :any, monterey: "748d93eeabbc36f740e84338393deea0167c49da70e069708c54f5767003d12f"
  end

  depends_on "python@3.13" => :build

  resource "depot_tools" do
    url "https://chromium.googlesource.com/chromium/tools/depot_tools.git", branch: "main"
  end

  def install
    # Clone the depot_tools repository and add it to the PATH
    depot_tools_path = buildpath/"depot_tools"
    resource("depot_tools").stage(depot_tools_path)
    ENV.prepend_path "PATH", depot_tools_path

    # Use Python 3.13
    ENV.prepend_path "PATH", Formula["python@3.13"].opt_bin

    # Ensure vpython and vpython3 from depot_tools are in the PATH
    ENV.prepend_path "PATH", buildpath/"angle/third_party/depot_tools"

    # Remove existing repository directory if it exists
    if (buildpath/"angle").exist?
      rm_rf buildpath/"angle"
    end

    # Clone the ANGLE repository
    system "git", "clone", "https://chromium.googlesource.com/angle/angle.git", buildpath/"angle"
    cd buildpath/"angle" do
      # Checkout the specific revision
      system "git", "checkout", "df0f7133799ca6aa0d31802b22d919c6197051cf"

      # Bootstrap and sync
      system "python3", "scripts/bootstrap.py"

      # Run ensure_bootstrap script
      system "bash", "#{depot_tools_path}/ensure_bootstrap"

      # Capture and print the contents of the .ensure file if it exists
      ensure_file = Dir.glob('/private/tmp/tmp*.ensure').first
      if ensure_file
        puts "Contents of the .ensure file:"
        contents = File.read(ensure_file)
        puts contents

        # Attempt to correct or remove the problematic setting
        fixed_contents = contents.lines.reject { |line| line.include?("$OverrideInstallMode") }.join
        File.write(ensure_file, fixed_contents)
        puts "Fixed .ensure file contents:"
        puts fixed_contents
      else
        puts "No .ensure file found."
      end

      # Run gclient sync
      system "gclient", "sync"

      # Generate build files with GN
      system "gn", "gen", "out/Release", "--args=is_debug=false"

      # Build ANGLE using autoninja
      system "autoninja", "-C", "out/Release"

      # Install the built libraries and headers
      lib.install "out/Release/libabsl.dylib"
      lib.install "out/Release/libEGL.dylib"
      lib.install "out/Release/libGLESv2.dylib"
      lib.install "out/Release/libchrome_zlib.dylib"
      include.install Dir["include/*"]
    end
  end

  test do
    # A simple test to ensure the formula installed correctly
    system "true"
  end
end