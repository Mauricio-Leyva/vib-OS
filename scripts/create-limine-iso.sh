#!/bin/bash
# Create a bootable ISO using Limine for Vib-OS
set -e

BUILD_DIR="${1:-build/x86_64}"
IMAGE_DIR="${2:-image}"
KERNEL_NAME="${3:-vibos-x86_64.elf}"
ISO_NAME="vibos-x86_64.iso"

# Paths
LIMINE_DIR="tools/limine"
ISO_ROOT="build/iso_root"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[LIMINE-ISO]${NC} $1"
}

# Ensure tools exist
if [ ! -d "$LIMINE_DIR" ]; then
    log "Error: Limine tools not found in $LIMINE_DIR. Run scripts/download-limine.sh first."
    exit 1
fi

# Create directories
mkdir -p "$IMAGE_DIR"
rm -rf "$ISO_ROOT"
mkdir -p "$ISO_ROOT/boot"
mkdir -p "$ISO_ROOT/EFI/BOOT"
mkdir -p "$ISO_ROOT/limine"

# Copy kernel
KERNEL_PATH="$BUILD_DIR/kernel/$KERNEL_NAME"
if [ ! -f "$KERNEL_PATH" ]; then
    log "Error: Kernel not found at $KERNEL_PATH"
    exit 1
fi
cp "$KERNEL_PATH" "$ISO_ROOT/boot/kernel.elf"
log "Copied kernel: $KERNEL_NAME -> /boot/kernel.elf"

# Create limine.conf
cat > "$ISO_ROOT/limine.conf" << EOF
timeout: 3
/Vib-OS
    protocol: limine
    kernel_path: boot():/boot/kernel.elf
EOF
# Copy to other possible locations
cp "$ISO_ROOT/limine.conf" "$ISO_ROOT/boot/limine.conf"
cp "$ISO_ROOT/limine.conf" "$ISO_ROOT/limine/limine.conf"

log "Created limine.conf"

# Copy Limine binaries
cp "$LIMINE_DIR/bin/limine-bios.sys" "$ISO_ROOT/boot/" 2>/dev/null || cp "$LIMINE_DIR/limine-bios.sys" "$ISO_ROOT/boot/"
cp "$LIMINE_DIR/bin/limine-bios-cd.bin" "$ISO_ROOT/boot/" 2>/dev/null || cp "$LIMINE_DIR/limine-bios-cd.bin" "$ISO_ROOT/boot/"
cp "$LIMINE_DIR/bin/limine-uefi-cd.bin" "$ISO_ROOT/boot/" 2>/dev/null || cp "$LIMINE_DIR/limine-uefi-cd.bin" "$ISO_ROOT/boot/"
cp "$LIMINE_DIR/bin/BOOTX64.EFI" "$ISO_ROOT/EFI/BOOT/" 2>/dev/null || cp "$LIMINE_DIR/BOOTX64.EFI" "$ISO_ROOT/EFI/BOOT/"

log "Copied Limine binaries"

# Create ISO
log "Creating ISO: $IMAGE_DIR/$ISO_NAME"
xorriso -as mkisofs -b boot/limine-bios-cd.bin \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    --efi-boot boot/limine-uefi-cd.bin \
    -efi-boot-part --efi-boot-image --protective-msdos-label \
    "$ISO_ROOT" -o "$IMAGE_DIR/$ISO_NAME"

# Install Limine for hybrid boot
log "Installing Limine bios-install..."
"$LIMINE_DIR/bin/limine" bios-install "$IMAGE_DIR/$ISO_NAME" 2>/dev/null || "$LIMINE_DIR/limine" bios-install "$IMAGE_DIR/$ISO_NAME"

log "ISO created successfully: $IMAGE_DIR/$ISO_NAME"
ls -lh "$IMAGE_DIR/$ISO_NAME"
