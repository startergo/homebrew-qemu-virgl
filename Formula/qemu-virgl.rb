class NoSubmoduleGitDownloadStrategy < GitDownloadStrategy
  def submodules?; false; end
end

class QemuVirgl < Formula
  desc "Emulator for x86 and PowerPC with VirGL acceleration support"
  homepage "https://www.qemu.org/"
  url "https://gitlab.com/qemu-project/qemu.git", 
      tag: "v10.1.2",
      revision: "ccaea6b2656ec6eab966585f7b16438208f98de7",
      using: NoSubmoduleGitDownloadStrategy
  sha256 "72f41f3708496b45186ca6b6d13982044b04848ecda4aef3f6211699eb4ea1b6"
  version "10.1.2"
  license "GPL-2.0-only"

  livecheck do
    url "https://www.qemu.org/download/"
    regex(/href=.*?qemu[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  depends_on "libtool" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "python@3.13" => :build

  depends_on "coreutils"
  depends_on "dtc"
  depends_on "glib"
  depends_on "gnutls"
  depends_on "jpeg"
  depends_on "startergo/qemu-virgl/libangle"
  depends_on "startergo/qemu-virgl/libepoxy-angle"
  depends_on "startergo/qemu-virgl/virglrenderer"
  depends_on "libpng"
  depends_on "libssh"
  depends_on "libusb"
  depends_on "lzo"
  depends_on "ncurses"
  depends_on "nettle"
  depends_on "pixman"
  depends_on "snappy"
  depends_on "spice-protocol"
  depends_on "vde"

  resource "tomli" do
    url "https://files.pythonhosted.org/packages/c0/3f/d7af728f075fb08564c5949a9c95e44352e23dee646869fa104a3b2060a3/tomli-2.0.1.tar.gz"
    sha256 "de526c12914f0c550d15924c62d72abc48d6fe7364aa87328337a31007fe8a4f"
  end

  resource "test-image" do
    url "https://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/distributions/1.2/official/FD12FLOPPY.zip"
    sha256 "81237c7b42dc0ffc8b32a2f5734e3480a3f9a470c50c14a9c4576a2561a35807"
  end

  patch :p1 do
    url "https://raw.githubusercontent.com/startergo/homebrew-qemu-virgl/refs/heads/testing/Patches/qemu-v07.diff"
    sha256 "d0da295f24ece630f82e685ffa571ce02f11d31f8311942bc0b50d1430f3323a"
  end

  def install
    # Setup Python environment
    ENV["LIBTOOL"] = "glibtool"
    
    python3 = Formula["python@3.13"].opt_bin/"python3.13"
    ENV["PYTHON"] = python3

    venv_path = buildpath/"venv"
    system python3, "-m", "venv", venv_path
    venv_python = venv_path/"bin/python"
    
    resource("tomli").stage do
      system venv_python, "-m", "pip", "install", "."
    end

    ENV["PYTHON"] = venv_python
    ENV.prepend_path "PYTHONPATH", venv_path/"lib/python3.13/site-packages"

    # Set library paths
    angle_prefix = Formula["startergo/qemu-virgl/libangle"].opt_prefix
    epoxy_prefix = Formula["startergo/qemu-virgl/libepoxy-angle"].opt_prefix
    virgl_prefix = Formula["startergo/qemu-virgl/virglrenderer"].opt_prefix
    spice_prefix = Formula["spice-protocol"].opt_prefix    

    # Build configuration
    args = %W[
      --prefix=#{prefix}
      --cc=#{ENV.cc}
      --host-cc=#{ENV.cc}
      --disable-bsd-user
      --disable-guest-agent
      --disable-sdl
      --disable-gtk
      --enable-cocoa
      --enable-opengl
      --enable-virglrenderer
      --enable-curses
      --enable-libssh
      --enable-vde
      --enable-fdt=system
      --enable-debug
      --enable-debug-info
      --enable-trace-backends=log,simple
      --enable-malloc=system
      --extra-cflags=-I#{angle_prefix}/include
      --extra-cflags=-I#{epoxy_prefix}/include
      --extra-cflags=-I#{virgl_prefix}/include
      --extra-cflags=-I#{spice_prefix}/include/spice-1
      --extra-cflags=-DNCURSES_WIDECHAR=1
      --extra-ldflags=-L#{angle_prefix}/lib
      --extra-ldflags=-L#{epoxy_prefix}/lib
      --extra-ldflags=-L#{virgl_prefix}/lib
      --extra-ldflags=-L#{spice_prefix}/lib
      --extra-ldflags=-Wl,-rpath,#{angle_prefix}/lib
      --extra-ldflags=-Wl,-rpath,#{epoxy_prefix}/lib
      --extra-ldflags=-Wl,-rpath,#{virgl_prefix}/lib
      --extra-ldflags=-Wl,-rpath,#{spice_prefix}/lib
    ]

    # Add smbd path
    args << "--smbd=#{HOMEBREW_PREFIX}/sbin/samba-dot-org-smbd"

    system "./configure", *args
    system "make", "V=1"
    system "make", "install"
    
    # Create helper script for running QEMU with correct library paths
    (bin/"qemu-virgl").write <<~EOS
      #!/bin/bash
      export DYLD_FALLBACK_LIBRARY_PATH="#{angle_prefix}/lib:#{epoxy_prefix}/lib:#{virgl_prefix}/lib:#{spice_prefix}/lib:$DYLD_FALLBACK_LIBRARY_PATH"
      export ANGLE_DEFAULT_PLATFORM="metal"
      
      # Uncomment for debugging
      # export VIRGL_DEBUG=all
      # export MESA_DEBUG=1
      
      exec "#{bin}/qemu-system-x86_64" "$@"
    EOS
    chmod 0755, bin/"qemu-virgl"
  end

  def caveats
    <<~EOS
      To run QEMU with VirGL acceleration, use:
        qemu-virgl -machine q35,accel=hvf -cpu host -m 4G \\
          -device virtio-gpu-pci,virgl=on -display cocoa,gl=on [other options]
          
      For detailed usage examples, see:
      https://github.com/startergo/homebrew-qemu-virgl
    EOS
  end

  test do
    expected = "QEMU Project"
    
    # Test basic system emulators
    %w[aarch64 x86_64].each do |arch|
      assert_match expected, shell_output("#{bin}/qemu-system-#{arch} --version")
    end

    # Test disk image tools
    resource("test-image").stage testpath
    assert_match "file format: raw", shell_output("#{bin}/qemu-img info FLOPPY.img")

    # Test VirGL helper script
    system "#{bin}/qemu-virgl", "-accel", "help"
  end
end