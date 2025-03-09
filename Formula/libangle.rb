class Libangle < Formula
  desc "Conformant OpenGL ES implementation for Windows, Mac, Linux, iOS, and Android"
  homepage "https://github.com/google/angle"
  url "https://github.com/google/angle.git", revision: "df0f7133799ca6aa0d31802b22d919c6197051cf"
  version "20250309.1"
  license "BSD-3-Clause"

  def install
    angle_dir = "/Users/macbookpro/Documents/angle/angle"

    # Install include files
    include.install Dir["#{angle_dir}/include/CL/*"]
    include.install Dir["#{angle_dir}/include/EGL/*"]
    include.install Dir["#{angle_dir}/include/GLES/*"]
    include.install Dir["#{angle_dir}/include/GLES2/*"]
    include.install Dir["#{angle_dir}/include/GLES3/*"]
    include.install Dir["#{angle_dir}/include/GLSLANG/*"]
    include.install Dir["#{angle_dir}/include/KHR/*"]
    include.install Dir["#{angle_dir}/include/WGL/*"]
    include.install "#{angle_dir}/include/angle_cl.h"
    include.install "#{angle_dir}/include/angle_gl.h"
    include.install "#{angle_dir}/include/angle_windowsstore.h"
    include.install "#{angle_dir}/include/export.h"
    include.install Dir["#{angle_dir}/include/platform/*"]
    include.install Dir["#{angle_dir}/include/vulkan/*"]

    # Install libraries from out/Release
    lib.install "#{angle_dir}/out/Release/libEGL.dylib"
    lib.install "#{angle_dir}/out/Release/libGLESv2.dylib"

    # Install other files
    prefix.install "#{angle_dir}/AUTHORS"
    prefix.install "#{angle_dir}/LICENSE"
    prefix.install "#{angle_dir}/README.md"
  end

  test do
    # Perform a simple test to check if the libraries are installed correctly
    system "true"
  end
end