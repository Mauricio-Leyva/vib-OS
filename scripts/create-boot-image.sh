#!/bin/bash
# Create bootable disk image for UnixOS
# Creates a GPT-partitioned disk image with EFI and root partitions using Linux tools

set -e

BUILD_DIR="${1:-build}"
IMAGE_DIR="${2:-image}"
ARCH="${3:-arm64}"
IMAGE_NAME="unixos.img"
IMAGE_SIZE="200M"

GREEN='\033[0;32m'
NC='\033[0m'
log() { echo -e "${GREEN}[IMAGE]${NC} $1"; }

mkdir -p "$IMAGE_DIR"
IMAGE_PATH="$IMAGE_DIR/$IMAGE_NAME"

log "Creating disk image: $IMAGE_PATH ($IMAGE_SIZE) for $ARCH"

# Create empty disk image (200MB)
dd if=/dev/zero of="$IMAGE_PATH" bs=1M count=200 2>/dev/null

log "Creating GPT partition table..."
parted -s "$IMAGE_PATH" mklabel gpt mkpart EFI fat32 1MiB 50MiB mkpart ROOT ext4 50MiB 100% set 1 esp on

# Create standalone FAT32 EFI partition image to edit without root privileges
EFI_IMG="$IMAGE_DIR/efi.img"
log "Creating virtual EFI partition..."
dd if=/dev/zero of="$EFI_IMG" bs=1M count=49 2>/dev/null
mformat -i "$EFI_IMG" -F ::
mmd -i "$EFI_IMG" ::/EFI
mmd -i "$EFI_IMG" ::/EFI/BOOT

if [ "$ARCH" = "x86_64" ]; then
    log "Downloading Limine UEFI bootloader..."
    mkdir -p "$BUILD_DIR/limine"
    if [ ! -f "$BUILD_DIR/limine/BOOTX64.EFI" ]; then
        curl -sL "https://raw.githubusercontent.com/limine-bootloader/limine/v5.x-branch-binary/BOOTX64.EFI" -o "$BUILD_DIR/limine/BOOTX64.EFI"
    fi
    mcopy -i "$EFI_IMG" "$BUILD_DIR/limine/BOOTX64.EFI" ::/EFI/BOOT/BOOTX64.EFI
    
    log "Configuring Limine boot file..."
    cat > "$BUILD_DIR/limine.cfg" << 'EOF'
TIMEOUT=3
:Vib-OS x86_64
PROTOCOL=limine
KERNEL_PATH=boot:///unixos.elf
RESOLUTION=1024x768x32
EOF

    mcopy -i "$EFI_IMG" "$BUILD_DIR/limine.cfg" ::/limine.cfg
    mcopy -i "$EFI_IMG" "$BUILD_DIR/kernel/unixos.elf" ::/unixos.elf
    log "Copied Limine and kernel.elf to EFI partition"
else
    # ARM64 BOOT strategy
    log "Configuring ARM64 boot..."
    cat > "$BUILD_DIR/startup.nsh" << 'EOF'
@echo -off
echo UnixOS Boot Loader
echo Loading kernel...
\EFI\BOOT\kernel.elf
EOF
    mcopy -i "$EFI_IMG" "$BUILD_DIR/startup.nsh" ::/EFI/BOOT/startup.nsh
    if [ -f "$BUILD_DIR/kernel/unixos.elf" ]; then
        mcopy -i "$EFI_IMG" "$BUILD_DIR/kernel/unixos.elf" ::/EFI/BOOT/kernel.elf
    fi
    log "Copied kernel for arm64"
fi

# Insert the virtual EFI partition into the main disk image (Offset = 1MiB = 1 block of 1M)
log "Writing EFI partition into main disk image..."
dd if="$EFI_IMG" of="$IMAGE_PATH" bs=1M seek=1 conv=notrunc 2>/dev/null

log "Boot image created successfully!"
ls -lh "$IMAGE_PATH"

echo ""
log "To test in QEMU: make ARCH=$ARCH run-gui"
