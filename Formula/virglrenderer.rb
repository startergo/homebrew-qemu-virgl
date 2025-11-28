# Formula created by startergo on 2025-03-12 13:25:22 UTC
class Virglrenderer < Formula
  desc "VirGL virtual OpenGL renderer"
  homepage "https://gitlab.freedesktop.org/virgl/virglrenderer"
  
  url "https://gitlab.freedesktop.org/virgl/virglrenderer.git",
      tag: "1.2.0",
      revision: "500b41d5c8638f9b80dd558f4044f3301c7457a4",
      using: :git
  sha256 "6fd0d7393c4594c8e3859dc37ce65d2bcdf89f2bcfbe5ec5b2e895ef3ca7e6a5"
  version "1.2.0"
  license "MIT"

  bottle do
    root_url "https://github.com/startergo/homebrew-qemu-virgl/releases/download/v20251126.022915"
    sha256 cellar: :any, arm64_sequoia: "9c0efc823a7312296737d10b72367d20ae0af890d7669d9d3fc99bec53271f6f"
    sha256 cellar: :any, sequoia:       "c5df414fed64269efa8205c301a5eff71417c32f64deabf715ebeee590e8af7b"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "cmake" => :build
  depends_on "python@3.13" => :build
  depends_on "startergo/qemu-virgl/libangle"
  depends_on "startergo/qemu-virgl/libepoxy-angle"
  depends_on "spice-protocol"

  patch :p1 do
    url "https://raw.githubusercontent.com/startergo/homebrew-qemu-virgl/refs/heads/master/Patches/virglrenderer-v05.diff"
    sha256 "3f76066d3b5c9146108c6723b374497b79492dbbaf9936525e9dfb4fc7003d6c"
  end

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/54/ed/79a089b6be93607fa5cdaedf301d7dfb23af5f25c398d5ead2525b063e17/pyyaml-6.0.2.tar.gz"
    sha256 "d584d9ec91ad65861cc08d42e834324ef890a082e591037abe114850ff7bbc3e"
  end

  def install
    # Install Python dependencies in a venv
    python3 = Formula["python@3.13"].opt_bin/"python3.13"
    venv_path = buildpath/"venv"
    system python3, "-m", "venv", venv_path
    venv_python = venv_path/"bin/python"
    
    resource("pyyaml").stage do
      system venv_python, "-m", "pip", "install", "."
    end
    
    ENV["PYTHON"] = venv_python
    ENV.prepend_path "PYTHONPATH", venv_path/"lib/python3.13/site-packages"
    
    # Use absolute paths to be absolutely certain
    epoxy = Formula["startergo/qemu-virgl/libepoxy-angle"]
    angle = Formula["startergo/qemu-virgl/libangle"]
    
    # Set up environment variables for the build
    ENV.prepend_path "PKG_CONFIG_PATH", "#{epoxy.opt_lib}/pkgconfig"
    ENV.append "LDFLAGS", "-L#{angle.opt_lib}"
    ENV.append "CPPFLAGS", "-I#{angle.opt_include}"
    
    # Use the correct platforms option format
    system "meson", "setup", "build",
           "--prefix=#{prefix}",
           "--buildtype=release",
           "-Dplatforms=egl",
           "--pkg-config-path=#{epoxy.opt_lib}/pkgconfig"
    
    system "meson", "compile", "-C", "build"
    system "meson", "install", "-C", "build"
  end

  test do
    system "#{bin}/virgl_test_server", "--help" rescue true
  end
end