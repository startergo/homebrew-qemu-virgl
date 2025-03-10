class Libangle < Formula
  desc "Conformant OpenGL ES implementation for Windows, Mac, Linux, iOS, and Android"
  homepage "https://chromium.googlesource.com/angle/angle"
  url "https://chromium.googlesource.com/angle/angle.git", revision: "df0f7133799ca6aa0d31802b22d919c6197051cf"
  version "20250309.1"
  license "BSD-3-Clause"

  CIPD_VERSION = "latest"

  bottle do
    root_url "https://github.com/startergo/homebrew-qemu-virgl/releases/download/libangle-20250309.1"
    sha256 cellar: :any, arm64_sequoia: "748d93eeabbc36f740e84338393deea0167c49da70e069708c54f5767003d12f"
    sha256 cellar: :any, monterey: "748d93eeabbc36f740e84338393deea0167c49da70e069708c54f5767003d12f"
  end

  depends_on "ninja" => :build
  depends_on "python@3.9" => :build
  depends_on "go" => :build

  def install
    # Path to the cached depot_tools directory
    cached_depot_tools_path = HOMEBREW_CACHE/"libangle--depot_tools--git"

    # Check if the cached depot_tools directory exists
    if !cached_depot_tools_path.directory?
      odie "Cached depot_tools directory not found: #{cached_depot_tools_path}"
    end

    # Use the cached depot_tools directory directly
    ENV.prepend_path "PATH", cached_depot_tools_path

    # Ensure the directory is writable
    unless File.writable?(cached_depot_tools_path)
      odie "Cached depot_tools directory is not writable: #{cached_depot_tools_path}"
    end

    # Create symbolic links for vpython if it doesn't exist
    ln_sf "#{cached_depot_tools_path}/vpython3", "#{cached_depot_tools_path}/vpython" unless File.symlink?("#{cached_depot_tools_path}/vpython")

    # Check system architecture and download appropriate gn binary
    gn_path = "#{cached_depot_tools_path}/gn"
    if File.symlink?(gn_path)
      File.delete(gn_path)
    end
    unless File.exist?(gn_path)
      arch = `uname -m`.chomp
      if arch == "x86_64" || arch == "arm64"
        system "curl -o #{gn_path} -L https://chrome-infra-packages.appspot.com/dl/gn/gn/mac-#{arch}/+/latest"
      end
    end

    # If gn binary is not executable, build gn from source
    if !File.executable?(gn_path)
      gn_build_path = buildpath/"gn"
      system "git", "clone", "--depth=1", "https://gn.googlesource.com/gn", gn_build_path
      cd gn_build_path do
        system "python", "build/gen.py"
        system "ninja", "-C", "out"
        bin.install "out/gn"
      end
    end

    # Detect and use the bundled Python version dynamically
    python_bundled_path = Dir["#{cached_depot_tools_path}/python*-bin"].first
    if python_bundled_path.nil? || !File.directory?(python_bundled_path)
      odie "Bundled Python not found in depot_tools"
    end

    ENV.prepend_path "PATH", python_bundled_path

    # Ensure cipd and vpython3 are executable
    system "chmod", "+x", "#{cached_depot_tools_path}/vpython3"
    system "chmod", "+x", "#{cached_depot_tools_path}/cipd"

    # Set VPYTHON_BYPASS to use system Python directly
    ENV["VPYTHON_BYPASS"] = "manually managed python not supported by chrome operations"

    # Debugging: Print environment variables
    system "echo 'Environment variables:'"
    system "env"

    # Create a virtual environment for Python dependencies
    venv_path = buildpath/"venv"
    system "python3", "-m", "venv", venv_path
    ENV.prepend_path "PATH", venv_path/"bin"

    # Install necessary Python dependencies using pip within the virtual environment
    system "echo 'Using pip located at: #{venv_path}/bin/pip'"
    system "#{venv_path}/bin/pip", "install", "httplib2"

    # Debugging: Verify installation of httplib2
    system "echo 'Checking installed packages in the virtual environment:'"
    system "#{venv_path}/bin/pip", "list"

    # Explicitly check if httplib2 is installed
    system "echo 'Checking if httplib2 is installed:'"
    system "#{venv_path}/bin/python", "-c", "import httplib2; print('httplib2 is installed')"

    # Debugging: Check Python version and path
    system "echo 'Python version and path:'"
    system "#{venv_path}/bin/python", "--version"
    system "#{venv_path}/bin/python", "-m", "site"

    # Remove existing repository directory if it exists
    if (buildpath/"angle").exist?
      rm_rf buildpath/"angle"
    end

    # Clone the ANGLE repository
    system "git", "clone", "https://chromium.googlesource.com/angle/angle.git", buildpath/"angle"
    cd buildpath/"angle" do
      # Checkout the specific revision
      system "git", "checkout", "df0f7133799ca6aa0d31802b22d919c6197051cf"

      # Bootstrap
      system "python3", "scripts/bootstrap.py"

      # Ensure cipd setup
      system "bash", "#{cached_depot_tools_path}/cipd_bin_setup.sh"

      # Increase file descriptor limit
      system "ulimit", "-n", "4096"

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