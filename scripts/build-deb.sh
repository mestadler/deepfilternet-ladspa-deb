#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)/deepfilternet-src"
OUTPUT_DIR="$(cd "$(dirname "$0")/.." && pwd)/output"
PKG_NAME="libdeep-filter-ladspa"
PKG_VERSION="0.5.7-1"
ARCH="amd64"

echo "==> Building $PKG_NAME $PKG_VERSION ($ARCH)"

if [ ! -d "$SRC_DIR" ]; then
    echo "ERROR: Source directory not found at $SRC_DIR"
    exit 1
fi

# Ensure .so is built
if [ ! -f "$SRC_DIR/target/release/libdeep_filter_ladspa.so" ]; then
    echo "==> Building ladspa crate (this may take a while)..."
    cd "$SRC_DIR"
    cargo build --release -p deep-filter-ladspa
fi

# Create package directory structure
PKG_DIR=$(mktemp -d)
trap 'rm -rf "$PKG_DIR"' EXIT

DEB_DIR="$PKG_DIR/${PKG_NAME}_${PKG_VERSION}_${ARCH}"
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/lib/ladspa"

# Install the LADSPA plugin
cp "$SRC_DIR/target/release/libdeep_filter_ladspa.so" \
   "$DEB_DIR/usr/lib/ladspa/libdeep_filter_ladspa.so"
chmod 644 "$DEB_DIR/usr/lib/ladspa/libdeep_filter_ladspa.so"

# Generate checksums
find "$DEB_DIR" -type f ! -path '*/DEBIAN/*' -exec md5sum {} \; \
    | sed "s|$DEB_DIR||" > "$DEB_DIR/DEBIAN/md5sums"

# Generate control file
cat > "$DEB_DIR/DEBIAN/control" << CONTROL
Package: $PKG_NAME
Version: $PKG_VERSION
Architecture: $ARCH
Maintainer: Martin <martin@sansnom.uk>
Section: sound
Priority: optional
Depends: libc6 (>= 2.31)
Recommends: easyeffects (>= 7.0.0)
Description: DeepFilterNet LADSPA plugin for real-time noise reduction
 Provides a neural network-based noise suppression LADSPA plugin that
 can be used with Easy Effects to remove background noise from audio
 in real-time while preserving speech clarity.
 .
 DeepFilterNet uses deep learning to distinguish between speech and
 background noise with remarkable accuracy, making it particularly
 effective for removing complex, dynamic background sounds like
 keyboard typing, fan noise, or ambient chatter.
CONTROL

# Build the .deb
mkdir -p "$OUTPUT_DIR"
cd "$PKG_DIR"
fakeroot dpkg-deb --build "${PKG_NAME}_${PKG_VERSION}_${ARCH}" "$OUTPUT_DIR/"

echo ""
echo "==> Build complete!"
dpkg-deb --info "$OUTPUT_DIR/${PKG_NAME}_${PKG_VERSION}_${ARCH}.deb" 2>/dev/null \
    || dpkg --info "$OUTPUT_DIR/${PKG_NAME}_${PKG_VERSION}_${ARCH}.deb"
echo ""
ls -lh "$OUTPUT_DIR/${PKG_NAME}_${PKG_VERSION}_${ARCH}.deb"
