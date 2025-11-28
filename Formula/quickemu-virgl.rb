class QuickemuVirgl < Formula
  desc "Quickly create and run optimised virtual machines with GPU acceleration"
  homepage "https://github.com/quickemu-project/quickemu"

  livecheck do
    url :stable
  end

  stable do
    # Using startergo fork with ARM64 support and GL ES acceleration until merged upstream
    url "https://github.com/startergo/quickemu/archive/refs/heads/fix-tcg-cpu-flags-macos.tar.gz"
    version "4.9.8-arm64"
  end

  head "https://github.com/startergo/quickemu.git", branch: "fix-tcg-cpu-flags-macos"
  license "MIT"

  depends_on "bash"
  depends_on "cdrtools"
  depends_on "coreutils"
  depends_on "jq"
  depends_on "python3"
  depends_on "startergo/qemu-virgl/qemu-virgl"  # Use qemu-virgl instead of standard qemu
  depends_on "samba"
  depends_on "socat"
  depends_on "swtpm"
  depends_on "usbutils"
  depends_on "zsync"

  conflicts_with "quickemu", because: "both install the same binaries"

  def install
    bin.install "quickemu"
    bin.install "quickget"
    bin.install "quickreport" if File.exist?("quickreport")
  end

  def caveats
    <<~EOS
      quickemu-virgl uses qemu-virgl for GPU acceleration via ANGLE/Metal.
      
      For best performance with GPU acceleration, ensure your VM configurations use:
        - virtio-gpu-gl-pci device for ARM VMs
        - virtio-gpu-gl-pci for x86 VMs
        - Display backend: -display cocoa,gl=es
      
      quickemu will automatically use the GPU-accelerated QEMU binaries from qemu-virgl.
    EOS
  end

  test do
    system bin/"quickemu", "--version"
  end
end
