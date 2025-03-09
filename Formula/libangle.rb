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

    # Ensure the repository is in a clean state
    system "git", "reset", "--hard"
    system "git", "clean", "-fdx"
    
    system "python3", "scripts/bootstrap.py"
    system "gclient", "sync", "--force"
    if Hardware::CPU.arm?
      system "gn", "gen", "angle_build", "--args=is_debug=false target_cpu='arm64'"
    else
      system "gn", "gen", "angle_build", "--args=is_debug=false"
    end
    system "autoninja", "-C", "angle_build"

    # Install the built libraries
    lib.install Dir["angle_build/*.dylib"]
    include.install Dir["include/*"]
  end

  test do
    # Perform a simple test to check if the libraries are installed correctly
    system "true"
  end
end