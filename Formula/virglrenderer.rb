class Virglrenderer < Formula
  desc "VirGL virtual OpenGL renderer"
  homepage "https://gitlab.freedesktop.org/virgl/virglrenderer"
  url "https://github.com/akihikodaki/virglrenderer/tree/macos"
  version "20211212.1"
  license "MIT"

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "startergo/qemu-virgl/libangle"
  depends_on "startergo/qemu-virgl/libepoxy-angle"

  # waiting for upstreaming of https://github.com/akihikodaki/virglrenderer/tree/macos

  def install
    mkdir "build" do
      system "meson", *std_meson_args, "-Dc_args=-I#{Formula["libepoxy-angle"].opt_prefix}/include",
             "-Dc_link_args=-L#{Formula["libepoxy-angle"].opt_prefix}/lib", ".."
      system "ninja", "-v"
      system "ninja", "install", "-v"
    end
  end

  test do
    system "true"
  end
end
