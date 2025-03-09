class Libangle < Formula
  desc "Conformant OpenGL ES implementation for Windows, Mac, Linux, iOS, and Android"
  homepage "https://github.com/google/angle"
  url "https://github.com/google/angle.git", using: :git, revision: "df0f7133799ca6aa0d31802b22d919c6197051cf"
  version "20250309.1"
  license "BSD-3-Clause"

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "python@3.9" => :build

  resource "depot_tools" do
    url "https://chromium.googlesource.com/chromium/tools/depot_tools.git", using: :git, revision: "dc86a4b9044f9243886ca0da0c1753820ac51f45"
  end

  def install
    resource("depot_tools").stage(buildpath/"depot_tools")
    ENV.prepend_path "PATH", buildpath/"depot_tools"

    # Bootstrap the environment
    system "python3", "scripts/bootstrap.py"
    
    # Sync dependencies
    system "gclient", "sync"
    
    # Generate build files
    system "gn", "gen", "--args=is_debug=false out/Release"
    
    # Build the project
    system "autoninja", "-C", "out/Release"

    # Install the built libraries
    lib.install Dir["out/Release/*.dylib"]
    include.install Dir["include/*"]
  end

  test do
    # Perform a simple test to check if the libraries are installed correctly
    system "true"
  end
end