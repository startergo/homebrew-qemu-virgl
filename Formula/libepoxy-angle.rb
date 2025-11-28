class LibepoxyAngle < Formula
  desc "Library for handling OpenGL function pointer management"
  homepage "https://github.com/anholt/libepoxy"
  url "https://github.com/anholt/libepoxy.git", 
      revision: "e98617e62e74a835d4e403cd270afaf296afe839",
      using: :git
  version "2025.03.08.1"
  license "MIT"

  bottle do
    root_url "https://github.com/startergo/homebrew-qemu-virgl/releases/download/v20251126.022915"
    sha256 cellar: :any, arm64_sequoia: "bb510af5190232adcf4ce2b1712e8a199c25ecf2755d7f3176216e48bb3bd368"
    sha256 cellar: :any, sequoia:       "08ce22b0bc5d9eb45979a2817e470ec5564dab7362fde28978c11ef727afa81b"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "python@3.13" => :build
  depends_on "startergo/qemu-virgl/libangle"

  # Waiting for upstreaming of https://github.com/akihikodaki/libepoxy/tree/macos
  patch :p1 do
    url "https://raw.githubusercontent.com/startergo/homebrew-qemu-virgl/refs/heads/master/Patches/libepoxy-v03.diff"
    sha256 "24abc33e17b37a1fa28925c52b93d9c07e8ec5bb488edda2b86492be979c1fc4"
  end

  def install
    mkdir "build" do
      system "meson", *std_meson_args,
             "-Dc_args=-I#{Formula["startergo/qemu-virgl/libangle"].opt_prefix}/include",
             "-Dc_link_args=-L#{Formula["startergo/qemu-virgl/libangle"].opt_prefix}/lib",
             "-Degl=yes", "-Dx11=false",
             ".."
      system "ninja", "-v"
      system "ninja", "install", "-v"
    end
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <epoxy/gl.h>
      #include <OpenGL/CGLContext.h>
      #include <OpenGL/CGLTypes.h>
      #include <OpenGL/OpenGL.h>
      int main() {
          CGLPixelFormatAttribute attribs[] = {0};
          CGLPixelFormatObj pix;
          int npix;
          CGLContextObj ctx;
          CGLChoosePixelFormat((const CGLPixelFormatAttribute *)attribs, &pix, &npix);
          CGLCreateContext(pix, NULL, &ctx);
          glClear(GL_COLOR_BUFFER_BIT);
          CGLReleasePixelFormat(pix);
          CGLReleaseContext(ctx);
          return 0;
      }
    EOS
    system ENV.cc, "test.c", "-L#{lib}", "-I#{include}/epoxy", "-lepoxy", "-framework", "OpenGL", "-o", "test"
    system "ls", "-lh", "test"
    system "file", "test"
    system "./test"
  end
end