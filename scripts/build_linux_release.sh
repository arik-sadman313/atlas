#!/usr/bin/env bash
set -euo pipefail

# ATLAS — Linux Desktop Release Packaging Script (Milestone 9)
# Compiles release build, strips debug symbols, and creates a relocatable .tar.gz bundle.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
BUNDLE_DIR="$ROOT_DIR/build/linux/x64/release/bundle"
ARCHIVE_NAME="atlas-linux-x64.tar.gz"

echo "=== Building ATLAS Linux Desktop Release ==="
cd "$ROOT_DIR"

# 1. Compile Flutter Linux Release binary
echo "Step 1: Running flutter build linux --release..."
flutter build linux --release

if [ ! -d "$BUNDLE_DIR" ]; then
    echo "Error: Release bundle not found at $BUNDLE_DIR"
    exit 1
fi

# 2. Strip debug symbols for smaller binary size and faster load times
echo "Step 2: Stripping unneeded debug symbols from executable and shared objects..."
if command -v strip >/dev/null 2>&1; then
    strip --strip-unneeded "$BUNDLE_DIR/atlas" || true
    if [ -d "$BUNDLE_DIR/lib" ]; then
        find "$BUNDLE_DIR/lib" -name "*.so" -exec strip --strip-unneeded {} + 2>/dev/null || true
    fi
    echo "Symbols stripped successfully."
else
    echo "Warning: 'strip' command not found, skipping symbol stripping."
fi

# 3. Create Distribution Staging Directory
STAGE_DIR="$ROOT_DIR/build/linux_staging/atlas"
rm -rf "$ROOT_DIR/build/linux_staging"
mkdir -p "$STAGE_DIR"
mkdir -p "$DIST_DIR"

echo "Step 3: Staging distribution bundle..."
# Copy compiled bundle (binary, lib/, data/)
cp -r "$BUNDLE_DIR"/* "$STAGE_DIR/"

# Copy desktop entry & icons
mkdir -p "$STAGE_DIR/share/applications"
mkdir -p "$STAGE_DIR/share/icons"
cp "$ROOT_DIR/linux/packaging/io.github.atlas_app.desktop" "$STAGE_DIR/share/applications/"
cp -r "$ROOT_DIR/linux/packaging/icons/hicolor" "$STAGE_DIR/share/icons/"

# Create install.sh helper script
cat << 'EOF' > "$STAGE_DIR/install.sh"
#!/usr/bin/env bash
set -euo pipefail

# ATLAS User-Space Installation Script
INSTALL_PREFIX="${HOME}/.local"
APP_DIR="${INSTALL_PREFIX}/share/atlas"
BIN_DIR="${INSTALL_PREFIX}/bin"
DESKTOP_DIR="${INSTALL_PREFIX}/share/applications"
ICONS_DIR="${INSTALL_PREFIX}/share/icons"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing ATLAS to ${APP_DIR}..."
mkdir -p "${APP_DIR}"
mkdir -p "${BIN_DIR}"
mkdir -p "${DESKTOP_DIR}"
mkdir -p "${ICONS_DIR}"

# Copy application files
cp -r "${SCRIPT_DIR}"/atlas "${APP_DIR}/"
cp -r "${SCRIPT_DIR}"/lib "${APP_DIR}/"
cp -r "${SCRIPT_DIR}"/data "${APP_DIR}/"

# Copy icons
if [ -d "${SCRIPT_DIR}/share/icons/hicolor" ]; then
    cp -r "${SCRIPT_DIR}/share/icons/hicolor" "${ICONS_DIR}/"
fi

# Copy and configure desktop entry
if [ -f "${SCRIPT_DIR}/share/applications/io.github.atlas_app.desktop" ]; then
    sed "s|Exec=atlas|Exec=${BIN_DIR}/atlas|g" \
        "${SCRIPT_DIR}/share/applications/io.github.atlas_app.desktop" \
        > "${DESKTOP_DIR}/io.github.atlas_app.desktop"
    chmod +x "${DESKTOP_DIR}/io.github.atlas_app.desktop"
fi

# Create symlink in user bin
ln -sf "${APP_DIR}/atlas" "${BIN_DIR}/atlas"

# Update desktop and mime databases if utilities exist
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${DESKTOP_DIR}" || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "${ICONS_DIR}/hicolor" || true
fi

echo "=== ATLAS Installation Complete! ==="
echo "You can launch ATLAS from your application menu or run 'atlas' in terminal."
EOF
chmod +x "$STAGE_DIR/install.sh"

# 4. Generate Relocatable .tar.gz
echo "Step 4: Compressing package into $DIST_DIR/$ARCHIVE_NAME..."
tar -czf "$DIST_DIR/$ARCHIVE_NAME" -C "$ROOT_DIR/build/linux_staging" atlas

echo "=== Release Packaging Successful! ==="
ls -lh "$DIST_DIR/$ARCHIVE_NAME"
