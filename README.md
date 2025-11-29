# 3D accelerated qemu on MacOS

![ubuntu](https://user-images.githubusercontent.com/6728841/111193747-90da1a00-85cb-11eb-9517-36c1a19c19be.gif)

## What is it for

If you own a Mac (x86 or ARM) and want to have a full Linux desktop for development or testing, you'll find that having a responsive desktop is a nice thing. The graphical acceleration is possible thanks to [the work](https://gist.github.com/akihikodaki/87df4149e7ca87f18dc56807ec5a1bc5) of [Akihiko Odaki](https://github.com/akihikodaki). I've only packaged it into an easily-installable brew repository while the changes are not yet merged into upstream.

Features:

- Support for both ARM and X86 acceleration with Hypervisor.framework (works without root or kernel extensions)
- Support for OpenGL acceleration in the guest (both X11 and Wayland)
- Works on large screens (5k+)
- Dynamically changing guest resolution on window resize
- Properly handle sound output when plugging/unplugging headphones

## Installation

### Prerequisites

1. **Xcode**:
   
#### Install Xcode from the Mac App Store
#### After installation, open Xcode to accept the license agreement

```sh  
sudo xcodebuild -license accept
```
Note: The Command Line Tools alone are not sufficient; full Xcode is required for building QEMU and its dependencies.

2. **Homebrew**:
If you haven't installed Homebrew yet:
```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Installation Steps

1. Add the tap and install QEMU with GPU acceleration:
```sh
brew tap startergo/qemu-virgl
brew install startergo/qemu-virgl/qemu-virgl
```

The formula will automatically install all required dependencies including:
- libangle (Apple's Metal backend for OpenGL)
- libepoxy-angle (OpenGL dispatch library)
- virglrenderer (OpenGL virtualization library)
- spice-server (for clipboard sharing and enhanced guest integration)

> ℹ️ **Note**: Pre-built bottles are available for faster installation. If bottles are not available for your macOS version, Homebrew will build from source (15-30 minutes).

> ⚠️ **Important**: During installation, you may see a warning about libepoxy symlink conflicts. This is expected and can be safely ignored. The installation will complete successfully, and qemu-virgl will use the correct custom libepoxy-angle library. If the installation appears to fail at the linking step, run:
> ```sh
> brew link --overwrite --force startergo/qemu-virgl/qemu-virgl
> ```

### Verifying Installation

To verify the installation was successful:

#### Verify QEMU installation
```sh
qemu-system-aarch64 --version  # Should show QEMU version
```

#### Verify virglrenderer installation:
```sh   
which virgl_test_server       
```
Should show /opt/homebrew/bin/virgl_test_server

### Optional: Quickemu for Easy VM Management

If you prefer a simpler interface for creating and managing VMs, you can install `quickemu-virgl`, which is a patched version of [Quickemu](https://github.com/quickemu-project/quickemu) that uses qemu-virgl for GPU acceleration:

```sh
brew install startergo/qemu-virgl/quickemu-virgl
```

Quickemu provides convenient commands for:
- Downloading and setting up VMs for various operating systems (`quickget`)
- Managing VM configurations with simple config files
- Running VMs with optimized settings (`quickemu`)

**Example usage:**
```sh
# Download a Fedora VM configuration
quickget fedora 41

# Run the VM with GPU acceleration (automatically uses qemu-virgl)
quickemu --vm fedora-41.conf
```

> **Note**: quickemu-virgl conflicts with the standard `quickemu` package. If you have the standard quickemu installed, uninstall it first: `brew uninstall quickemu`

The quickemu-virgl wrapper automatically uses the GPU-accelerated QEMU binaries from qemu-virgl, giving you the best of both worlds: easy VM management and hardware-accelerated graphics.

#### Optional: Quickgui - Graphical Interface for Quickemu

If you prefer a graphical interface, you can build [Quickgui](https://github.com/quickemu-project/quickgui), which provides a GUI for managing VMs with quickemu.

**Prerequisites:**
- Flutter SDK
- Xcode with macOS development tools
- CocoaPods

**Building Quickgui:**
```sh
# Install Flutter and CocoaPods first
brew install flutter
brew install cocoapods

# Clone and build Quickgui
git clone https://github.com/quickemu-project/quickgui.git
cd quickgui
flutter pub get
flutter config --enable-macos-desktop
flutter build macos --release
```

**Running Quickgui:**
```sh
# Launch the application
open build/macos/Build/Products/Release/quickgui.app

# Or run the binary directly
./build/macos/Build/Products/Release/quickgui.app/Contents/MacOS/quickgui
```

After building, you can copy `quickgui.app` to your Applications folder and launch it through Spotlight. Quickgui will automatically detect and use your quickemu-virgl installation with GPU acceleration.

### Usage
Qemu has many command line options and emulated devices, with specific configurations based on your CPU type (Intel/Apple Silicon).

For the best experience, maximize the qemu window when it starts. To release the mouse, press Ctrl-Alt-g.

### Usage - Apple Silicon Macs

Important: Use `virtio-gpu-gl-pci` command line option instead of `virtio-gpu-pci` for GPU acceleration

First, create a disk image you'll run your Linux installation from (tune image size as needed):

```sh
qemu-img create -f qcow2 hdd.qcow2 64G
```

This command creates a qcow2 disk image named `hdd.qcow2` with a maximum size of 64 GB. The qcow2 format only uses disk space as needed (thin provisioning), so it starts small and grows dynamically. You can adjust the size as needed.

> 💡 **Tip**: Use `qcow2` format for space efficiency (grows as needed) or `raw` format for better performance.

Download an ARM based Fedora image:

```sh
curl -LO https://dl01.fedoraproject.org/pub/fedora/linux/releases/41/Silverblue/aarch64/iso/Fedora-Silverblue-ostree-aarch64-41-1.4.iso
```
Copy the firmware:

```sh
cp $(dirname $(which qemu-img))/../share/qemu/edk2-aarch64-code.fd .
cp $(dirname $(which qemu-img))/../share/qemu/edk2-arm-vars.fd .
```

#### Verify that OpenGL acceleration is working
```sh
sudo qemu-system-aarch64 \
  -machine virt,accel=hvf \
  -cpu cortex-a72 -smp 2 -m 1G \
  -device virtio-gpu-gl-pci \
  -display cocoa,gl=es \
  -nodefaults \
  -device VGA,vgamem_mb=64 \
  -monitor stdio
```
When the QEMU monitor appears (shown by the `(qemu)` prompt), type `info qtree` and press Enter. Look for these entries in the output:
- `dev: virtio-gpu-gl-pci` - Shows the PCI device is configured
- `dev: virtio-gpu-gl-device` - Shows the VirtIO GPU device with OpenGL support

This confirms that your OpenGL acceleration is working correctly through the ANGLE/Metal path. Type `quit` to exit QEMU.

Install the system from the ISO image:

```sh
sudo qemu-system-aarch64 \
  -machine virt,accel=hvf \
  -cpu cortex-a72 -smp 2 -m 4G \
  -device intel-hda -device hda-output \
  -device qemu-xhci \
  -device virtio-gpu-gl-pci,xres=1920,yres=1080 \
  -device usb-kbd \
  -device usb-tablet \
  -device virtio-net-pci,netdev=net \
  -device virtio-mouse-pci \
  -display cocoa,gl=es \
  -netdev vmnet-shared,id=net \
  -drive "if=pflash,format=raw,file=./edk2-aarch64-code.fd,readonly=on" \
  -drive "if=pflash,format=raw,file=./edk2-arm-vars.fd,discard=on" \
  -drive "if=virtio,format=qcow2,file=./hdd.qcow2,discard=on" \
  -chardev qemu-vdagent,id=spice,name=vdagent,clipboard=on \
  -device virtio-serial-pci \
  -device virtserialport,chardev=spice,name=com.redhat.spice.0 \
  -cdrom Fedora-Silverblue-ostree-aarch64-41-1.4.iso \
  -boot d 
```
This command will start a QEMU virtual machine with the following options:
- `-machine virt,accel=hvf`: Use the virt machine type with Hypervisor.framework acceleration.
- `-cpu cortex-a72`: Use the Cortex-A72 CPU model.
- `-smp 2`: Allocate 2 CPU cores.
- `-m 4G`: Allocate 4 GB of RAM.
- `-device intel-hda -device hda-output`: Use Intel HDA sound device.
- `-device qemu-xhci`: Use QEMU's XHCI USB controller.
- `-device virtio-gpu-gl-pci`: Use the VirtIO GPU with OpenGL acceleration.
- `-device usb-kbd`: Use a USB keyboard device.
- `-device virtio-net-pci,netdev=net`: Use the VirtIO network device.
- `-device virtio-mouse-pci`: Use the VirtIO mouse device.
- `-display cocoa,gl=es`: Use the Cocoa display backend for macOS with OpenGL ES.
- `-netdev vmnet-shared,id=net`: Use shared networking with vmnet.
- `-drive "if=pflash,format=raw,file=./edk2-aarch64-code.fd,readonly=on"`: Use the QEMU EFI firmware as a read-only drive.
- `-drive "if=pflash,format=raw,file=./edk2-arm-vars.fd,discard=on"`: Use the QEMU EFI variables as a discardable drive.
- `-drive "if=virtio,format=raw,file=./hdd.raw,discard=on"`: Use the created disk image as a discardable virtual hard drive.
- `-chardev qemu-vdagent,id=spice,name=vdagent,clipboard=on`: Creates a SPICE agent character device with clipboard sharing enabled
- `device virtio-serial-pci`: Adds a virtio-serial PCI controller for communication
- `-device virtserialport,chardev=spice,name=com.redhat.spice.0`: Connects the SPICE agent to the virtio-serial bus. Note: Inside your Linux guest, you'll need to install the SPICE guest agent if not installed by default.
- `-cdrom Fedora-Silverblue-ostree-aarch64-41-1.4.iso`: Use the Fedora ARM ISO as a CD-ROM.
- `-boot d`: Boot from the CD-ROM.

Run the system without the CD image to boot into the primary partition:
```sh
sudo qemu-system-aarch64 \
  -machine virt,accel=hvf \
  -cpu cortex-a72 -smp 2 -m 4G \
  -device intel-hda -device hda-output \
  -device qemu-xhci \
  -device virtio-gpu-gl-pci,xres=1920,yres=1080 \
  -device usb-kbd \
  -device usb-tablet \
  -device virtio-net-pci,netdev=net \
  -device virtio-mouse-pci \
  -display cocoa,gl=es \
  -netdev vmnet-shared,id=net \
  -drive "if=pflash,format=raw,file=./edk2-aarch64-code.fd,readonly=on" \
  -drive "if=pflash,format=raw,file=./edk2-arm-vars.fd,discard=on" \
  -drive "if=virtio,format=qcow2,file=./hdd.qcow2,discard=on" \
  -chardev qemu-vdagent,id=spice,name=vdagent,clipboard=on \
  -device virtio-serial-pci \
  -device virtserialport,chardev=spice,name=com.redhat.spice.0
```
This command is similar to the previous one but without the `-cdrom` and `-boot d` options, allowing you to boot directly from the installed system on the disk image.

#### Verifying GPU Acceleration in Fedora

Once your Fedora system has booted, you can verify that GPU acceleration is working properly by installing and running Mesa utilities:

```bash
# Create and enter a toolbox
toolbox create
toolbox enter

# Now you can use dnf inside the toolbox
sudo dnf install mesa-demos glx-utils glmark2

# Check OpenGL renderer and direct rendering
glxinfo | grep -E "OpenGL renderer|direct rendering"

# Expected output:
# direct rendering: Yes
# OpenGL renderer string: virgl (ANGLE (Apple, Apple M4 Pro, OpenGL 4.1 Metal - 89.4))

# Run a simple OpenGL test
glxgears
```

**Clipboard Sharing:**

Clipboard sharing between macOS and Fedora works automatically! Fedora Silverblue includes `spice-vdagent` pre-installed and running, so you can immediately copy and paste text between your Mac and the VM.

For other Fedora editions (Workstation, Server, etc.), if clipboard sharing doesn't work, install the SPICE guest agent:

```bash
sudo dnf install spice-vdagent
sudo systemctl enable --now spice-vdagentd
```

You can verify the agent is running with:
```bash
systemctl status spice-vdagentd
```

**Known Limitations:**

- **Moving between Retina and non-Retina displays**: When you move the VM window between displays with different pixel densities (e.g., Retina to 1080p), the display may automatically adjust resolution but render incorrectly - typically shrinking to the bottom-left corner. This is a known issue with QEMU's virtio-gpu and the macOS Cocoa display backend not properly coordinating resolution changes across different display densities.
  
  **Workarounds:**
  - Keep the VM window on one display (either Retina or 1080p)
  - Restart the VM after moving to the target display
  - Disable automatic resolution adjustment in GNOME Settings → Displays (set a fixed resolution that works on both displays)

- **EFI/GRUB bootloader resolution**: During boot, the EFI firmware and GRUB bootloader run at a fixed low resolution before the OS loads. The resolution parameters (`xres=1920,yres=1080`) only take effect once the desktop environment starts.

### Usage - Intel Macs
Important: Use virtio-gpu-gl-pci command line option instead of virtio-gpu-pci for GPU acceleration
First, create a disk image you'll run your Linux installation from (tune image size as needed):

```sh
qemu-img create -f qcow2 hdd.qcow2 64G
```
Download an x86 based Fedora image:

```sh
curl -LO https://download.fedoraproject.org/pub/fedora/linux/releases/40/Workstation/x86_64/iso/Fedora-Workstation-Live-x86_64-40-1.2.iso
```
Copy the firmware:

```sh
cp $(dirname $(which qemu-img))/../share/qemu/edk2-x86_64-code.fd .
cp $(dirname $(which qemu-img))/../share/qemu/edk2-vars.fd .
```

Install the system from the ISO image:
```sh
sudo qemu-system-x86_64 \
  -M q35 \
  -cpu host \
  -smp 4 \
  -m 8G \
  -bios ./edk2-x86_64-code.fd \
  -drive file=hdd.qcow2,if=virtio,format=qcow2 \
  -netdev vmnet-shared,id=net0 \
  -device virtio-net-pci,netdev=net0 \
  -vga virtio-gpu-gl-pci \
  -display cocoa,gl=es \
  -usb -device usb-tablet \
  -cdrom Fedora-Workstation-Live-x86_64-40-1.2.iso \
  -boot d \
  -chardev qemu-vdagent,id=spice,name=vdagent,clipboard=on \
  -device virtio-serial-pci \
  -device virtserialport,chardev=spice,name=com.redhat.spice.0
```
This command will start a QEMU virtual machine with the following options:
- `-M q35`: Use the Q35 machine type.
- `-cpu host`: Use the host CPU model.
- `-smp 4`: Allocate 4 CPU cores.
- `-m 8G`: Allocate 8 GB of RAM.
- `-bios ./edk2-x86_64-code.fd`: Use the QEMU EFI firmware.
- `-drive file=hdd.raw,if=virtio,format=raw`: Use the created disk image as a virtual hard drive.
- `-netdev vmnet-shared,id=net0`: Use shared networking with vmnet.
- `-device virtio-net-pci,netdev=net0`: Use the VirtIO network device.
- `-vga virtio-gpu-gl-pci`: Use the VirtIO GPU with OpenGL acceleration.
- `-display cocoa,gl=es`: Use the Cocoa display backend for macOS with OpenGL ES.
- `-usb -device usb-tablet`: Use a USB tablet device for better mouse handling.
- `-chardev qemu-vdagent,id=spice,name=vdagent,clipboard=on`: Enable clipboard sharing with the host.
- `-device virtio-serial-pci`: Use the VirtIO serial device.
- `-device virtserialport,chardev=spice,name=com.redhat.spice.0`: Use the VirtIO serial port for SPICE.

### Troubleshooting

If you encounter installation issues:

1. Ensure Xcode is properly installed:
   ```sh
   xcode-select -p  # Should point to full Xcode path, not Command Line Tools
   ```

2. Check Homebrew's health:
   ```sh
   brew doctor
   brew update && brew upgrade
   ```

3. Try a verbose installation:
   ```sh
   HOMEBREW_NO_AUTO_UPDATE=1 brew install -v qemu-virgl
   ```

4. If you see build errors, try cleaning and retrying:
   ```sh
   brew cleanup
   brew uninstall qemu-virgl
   brew install qemu-virgl
   ```

### Common Issues

1. **libepoxy symlink conflicts**:
   If installation fails with symlink conflicts, this is due to spice-server dependencies installing standard libepoxy alongside our custom libepoxy-angle. Run:
   ```sh
   brew link --overwrite --force startergo/qemu-virgl/qemu-virgl
   ```
   This will properly link qemu-virgl to use the correct custom libraries.

2. **Missing libEGL.dylib error**:
   If you see: "Couldn't open libEGL.dylib", this indicates a problem with library linking. Try reinstalling:
   ```sh
   brew reinstall startergo/qemu-virgl/qemu-virgl
   ```

3. **Network Issues**:
   - If running with vmnet-shared fails, make sure your user has proper permissions
   - You might need to grant permissions in System Settings > Privacy & Security > Network

4. **For Best Performance**:
   - Use `-smp` matching your CPU core count (use `sysctl -n hw.ncpu` to see available cores)
   - Increase memory (`-m`) to 8G or more if available on your system
   - For better performance on newer Macs, try increasing CPU and RAM settings

5. **Memory Limitation Errors**:
   If you see "Addressing limited to 32 bits" errors, remove the `highmem=off` option or reduce your VM memory allocation.

6. **Network Backend Errors**:
   QEMU on macOS requires the `vmnet` backend. Do not use `-netdev user` as it may not be compiled into the binary.
