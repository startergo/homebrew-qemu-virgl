class Libangle < Formula
  desc "Conformant OpenGL ES implementation for Windows, Mac, Linux, iOS and Android"
  homepage "https://github.com/google/angle"
  url "https://github.com/google/angle.git", using: :git, revision: "df0f7133799ca6aa0d31802b22d919c6197051cf"
  version "2025.03.08.1"
  license "BSD-3-Clause"

  bottle do
    root_url "https://github.com/startergo/homebrew-qemu-virgl/releases/download/v20250309.1/angle-20250309.1.tar.gz"
    sha256 cellar: :any, arm64_sequoia: "39b00a7e145df3678aa4d498293e2d4800f6d887bac04b081c024c50af4b24cb"
  end

  depends_on "ninja" => :build
  depends_on "python@3.9" => :build
  depends_on "go" => :build

  def install
    # Path to the cached depot_tools directory
    cached_depot_tools_path = HOMEBREW_CACHE/"libangle--depot_tools--git"

    # Download depot_tools if not cached
    if !cached_depot_tools_path.directory?
      system "git", "clone", "https://chromium.googlesource.com/chromium/tools/depot_tools.git", cached_depot_tools_path
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

    # Check if gn binary version is correct
    gn_version_output = `#{gn_path} --version`
    if gn_version_output.include?("gn.py: Could not find checkout in any parent of the current path")
      # If not correct, delete and recompile gn from source
      File.delete(gn_path) if File.exist?(gn_path)
      gn_build_path = buildpath/"gn"
      system "git", "clone", "https://gn.googlesource.com/gn", gn_build_path
      cd gn_build_path do
        # Check if the repository is already fully cloned
        if `git rev-parse --is-shallow-repository`.chomp == "true"
          system "git", "fetch", "--unshallow"
        end
        system "python3", "build/gen.py"
        system "autoninja", "-j", "2", "-C", "out"
        bin.install "out/gn"
      end
    end

    # Remove bundled Python setup and use Homebrew Python for virtual environment
    ENV.prepend_path "PATH", Formula["python@3.9"].opt_bin

    # Set VPYTHON_BYPASS to use system Python directly
    ENV["VPYTHON_BYPASS"] = "manually managed python not supported by chrome operations"

    # Debugging: Print environment variables and limits
    system "echo 'Environment variables:'"
    system "env"
    system "echo 'Current limits:'"
    system "ulimit -a"

    # Create a virtual environment for Python dependencies
    venv_path = buildpath/"venv"
    system "python3", "-m", "venv", venv_path
    ENV.prepend_path "PATH", venv_path/"bin"

    # Create a symbolic link for python to resolve to python3
    ln_sf "#{venv_path}/bin/python3", "#{venv_path}/bin/python"

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

    # Increase file descriptor limit
    system "ulimit", "-n", "4096"

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
      system "python", "scripts/bootstrap.py"

      # Ensure cipd setup
      system "bash", "#{cached_depot_tools_path}/cipd_bin_setup.sh"

      # Increase file descriptor limit
      system "ulimit", "-n", "4096"

      # Generate build files with GN
      system "gn", "gen", "out/Release", "--args=is_debug=false"

      # Build ANGLE using autoninja
      system "autoninja", "-j", "2", "-C", "out/Release"

      # Install the build libraries and headers
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