class LibepoxyAngle < Formula
  desc "Library for handling OpenGL function pointer management"
  homepage "https://github.com/anholt/libepoxy"
  url "https://github.com/startergo/libepoxy/tree/macos"
  version "20240603.1"
  license "MIT"

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "python@3.9" => :build
  depends_on "startergo/qemu-virgl/libangle"

  # waiting for upstreaming of https://github.com/akihikodaki/libepoxy/tree/macos
  
  def install
    mkdir "build" do
      system "meson", *std_meson_args, "-Dc_args=-I#{Formula["libangle"].opt_prefix}/include",
             "-Dc_link_args=-L#{Formula["libangle"].opt_prefix}/lib", "-Degl=yes", "-Dx11=false",
             "-Dfallback-libdir=#{HOMEBREW_PREFIX}/lib", ".."
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
      int main()
      {
          CGLPixelFormatAttribute attribs[] = {0};
          CGLPixelFormatObj pix;
          int npix;
          CGLContextObj ctx;

          CGLChoosePixelFormat( attribs, &pix, &npix );
          CGLCreateContext(pix, (void*)0, &ctx);

          glClear(GL_COLOR_BUFFER_BIT);
          CGLReleasePixelFormat(pix);
          CGLReleaseContext(pix);
          return 0;
      }
    EOS
    system ENV.cc, "test.c", "-L#{lib}", "-lepoxy", "-framework", "OpenGL", "-o", "test"
    system "ls", "-lh", "test"
    system "file", "test"
    system "./test"
  end
end
