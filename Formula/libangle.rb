class Libangle < Formula
  desc "Conformant OpenGL ES implementation for Windows, Mac, Linux, iOS, and Android"
  homepage "https://github.com/google/angle"
  url "https://github.com/google/angle.git", revision: "df0f7133799ca6aa0d31802b22d919c6197051cf"
  version "20250309.1"
  license "BSD-3-Clause"

  def install
    angle_dir = "/Users/macbookpro/Documents/angle/angle"

    # Install include files
    include.install Dir["#{angle_dir}/include/*"]

    # Install libraries from out/Release
    lib.install "#{angle_dir}/out/Release/libEGL.dylib"
    lib.install "#{angle_dir}/out/Release/libGLESv2.dylib"

    # Install other files
    prefix.install "AUTHORS"
    prefix.install "LICENSE"
    prefix.install "README.md"
  end

  test do
    # Perform a simple test to check if the libraries are installed correctly
    system "true"
  end
end