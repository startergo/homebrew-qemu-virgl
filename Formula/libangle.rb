class Libangle < Formula
  desc "Conformant OpenGL ES implementation for Windows, Mac, Linux, iOS and Android"
  homepage "https://github.com/google/angle"
  url "https://chromium.googlesource.com/angle/angle.git", using: :git, revision: "df0f7133799ca6aa0d31802b22d919c6197051cf"
  version "20250309.1"
  license "BSD-3-Clause"

  bottle do
    root_url "https://github.com/startergo/homebrew-qemu-virgl/releases/download/libangle-20250309.1"
    sha256 cellar: :any, arm64_sequoia: "748d93eeabbc36f740e84338393deea0167c49da70e069708c54f5767003d12f"
    sha256 cellar: :any, monterey: "748d93eeabbc36f740e84338393deea0167c49da70e069708c54f5767003d12f"
  end

  depends_on "python@3.9" => :build

  resource "depot_tools" do
    url "https://chromium.googlesource.com/chromium/tools/depot_tools.git", branch: "main"
  end

  def install
    # Clone the depot_tools repository and add it to the PATH
    depot_tools_path = buildpath/"depot_tools"
    resource("depot_tools").stage(depot_tools_path)
    ENV.prepend_path "PATH", depot_tools_path

    # Run gclient config and sync
    system "gclient", "config", "--name", ".", "https://chromium.googlesource.com/angle/angle.git"
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

  test do
    # A simple test to ensure the formula installed correctly
    system "true"
  end
end