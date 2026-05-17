#!/bin/bash
# Download Limine bootloader binaries for Vib-OS
set -e

LIMINE_VERSION="8.6.0"
LIMINE_DIR="tools/limine"
LIMINE_URL="https://github.com/limine-bootloader/limine/releases/download/v${LIMINE_VERSION}/limine-${LIMINE_VERSION}.tar.xz"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[LIMINE-DOWNLOAD]${NC} $1"
}

# Create tools directory
mkdir -p tools

# Check if Limine already exists
if [ -f "${LIMINE_DIR}/limine" ]; then
    log "Limine already exists in ${LIMINE_DIR}, skipping download."
    exit 0
fi

log "Downloading Limine v${LIMINE_VERSION}..."
curl -L "${LIMINE_URL}" -o limine.tar.xz

log "Extracting Limine..."
mkdir -p "${LIMINE_DIR}"
tar -xf limine.tar.xz -C "${LIMINE_DIR}" --strip-components=1
rm limine.tar.xz

log "Building Limine tools (native)..."
cd "${LIMINE_DIR}"
./configure --enable-all
make

log "Limine downloaded and built successfully in ${LIMINE_DIR}"
