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

  depends_on "python@3.13" => :build

  def install
    # Path to the cached depot_tools directory
    cached_depot_tools_path = HOMEBREW_CACHE/"libangle--depot_tools--git"

    # Check if the cached depot_tools directory exists
    if !cached_depot_tools_path.directory?
      odie "Cached depot_tools directory not found: #{cached_depot_tools_path}"
    end

    # Copy the cached depot_tools directory to the buildpath
    depot_tools_path = buildpath/"angle/third_party/depot_tools"
    cp_r "#{cached_depot_tools_path}/.", depot_tools_path
    ENV.prepend_path "PATH", depot_tools_path

    # Use Python 3.13
    ENV.prepend_path "PATH", Formula["python@3.13"].opt_bin

    # Check if vpython exists in the expected directory
    vpython_path = "#{depot_tools_path}/vpython"
    unless File.exist?(vpython_path)
      odie "vpython not found in #{vpython_path}"
    end

    # Ensure cipd and vpython are executable
    system "chmod", "+x", vpython_path
    system "chmod", "+x", "#{depot_tools_path}/cipd"

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

      # Ensure cipd setup
      system "bash", "#{depot_tools_path}/cipd_bin_setup.sh"

      # Create a custom .ensure file
      custom_ensure_file = buildpath/"custom.ensure"
      File.open(custom_ensure_file, "w") do |file|
        file.write <<~EOS
          # Ensure the CIPD client is up-to-date.
          $ParanoidMode CheckPresence

          # Ensure the latest CIPD client is installed.
          infra/tools/cipd/#{CIPD_VERSION}
        EOS
      end

      # Use the custom .ensure file during gclient sync
      ENV["GCLIENT_CIPD_ENSURE_FILE"] = custom_ensure_file

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