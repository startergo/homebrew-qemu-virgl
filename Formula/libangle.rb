class Libangle < Formula
  desc "A conformant OpenGL ES implementation for Windows, Mac, Linux, iOS, and Android."
  homepage "https://chromium.googlesource.com/angle/angle"
  url "https://github.com/startergo/homebrew-qemu-virgl/releases/download/v20250309.1/angle-20250309.1.tar.gz"
  sha256 "748d93eeabbc36f740e84338393deea0167c49da70e069708c54f5767003d12f"
  license "BSD-3-Clause"

  bottle do
    root_url "https://github.com/startergo/homebrew-qemu-virgl/releases/download/v20250309.1"
    sha256 cellar: :any, arm64_sequoia: "748d93eeabbc36f740e84338393deea0167c49da70e069708c54f5767003d12f"
    sha256 cellar: :any, monterey: "748d93eeabbc36f740e84338393deea0167c49da70e069708c54f5767003d12f"
  end

  depends_on "cmake" => :build

  def install
    mkdir "build" do
      system "cmake", "..", *std_cmake_args, "-DANGLE_ENABLE_VULKAN=OFF"
      system "make", "install"
    end
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <EGL/egl.h>
      int main() {
        EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
        return display == EGL_NO_DISPLAY;
      }
    EOS
    system ENV.cxx, "test.cpp", "-L#{lib}", "-lEGL", "-o", "test"
    system "./test"
  end
end