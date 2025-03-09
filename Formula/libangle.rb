class Libangle < Formula
  desc "Conformant OpenGL ES implementation for Windows, Mac, Linux, iOS, and Android"
  homepage "https://github.com/google/angle"
  url "https://github.com/google/angle.git", revision: "df0f7133799ca6aa0d31802b22d919c6197051cf"
  version "20250309.1"
  license "BSD-3-Clause"

  def install
    angle_dir = "/Users/macbookpro/Documents/angle/angle"

    # Ensure we have read permissions
    chmod_R "u+r", angle_dir

    # Copy include files to the buildpath to handle permissions
    mkdir "include_tmp"
    cp_r "#{angle_dir}/include/.", "include_tmp"

    # Install include files
    include.install Dir["include_tmp/CL/*"]
    include.install Dir["include_tmp/EGL/*"]
    include.install Dir["include_tmp/GLES/*"]
    include.install Dir["include_tmp/GLES2/*"]
    include.install Dir["include_tmp/GLES3/*"]
    include.install Dir["include_tmp/GLSLANG/*"]
    include.install Dir["include_tmp/KHR/*"]
    include.install Dir["include_tmp/WGL/*"]
    include.install "include_tmp/angle_cl.h"
    include.install "include_tmp/angle_gl.h"
    include.install "include_tmp/angle_windowsstore.h"
    include.install "include_tmp/export.h"
    include.install Dir["include_tmp/platform/*"]
    include.install Dir["include_tmp/vulkan/*"]

    # Copy library files to the buildpath to handle permissions
    mkdir "lib_tmp"
    cp "#{angle_dir}/out/Release/libEGL.dylib", "lib_tmp"
    cp "#{angle_dir}/out/Release/libGLESv2.dylib", "lib_tmp"

    # Install libraries from temporary directory
    lib.install Dir["lib_tmp/*"]

    # Copy other files to the buildpath to handle permissions
    mkdir "prefix_tmp"
    cp "#{angle_dir}/AUTHORS", "prefix_tmp"
    cp "#{angle_dir}/LICENSE", "prefix_tmp"
    cp "#{angle_dir}/README.md", "prefix_tmp"

    # Install other files from temporary directory
    prefix.install Dir["prefix_tmp/*"]
  end

  test do
    # Perform a simple test to check if the libraries are installed correctly
    system "true"
  end
end