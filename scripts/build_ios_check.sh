#!/usr/bin/env bash
set -euo pipefail

# ATLAS — iOS & iPadOS Deployment Check & Archive Script (Milestone 9)
# Validates iOS configuration, CocoaPods deployment targets (iOS 15.0+),
# and provides reproducible commands for Xcode building and signing on macOS.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== ATLAS iOS / iPadOS Build Verification ==="
cd "$ROOT_DIR"

# 1. Inspect Podfile & Swift Bridges
echo "Step 1: Checking iOS Podfile configuration..."
if [ -f "ios/Podfile" ]; then
    if grep -q "platform :ios, '15.0'" ios/Podfile; then
        echo "  [PASS] Podfile deployment target is set to iOS 15.0+."
    else
        echo "  [WARN] Podfile does not explicitly specify platform :ios, '15.0'."
    fi
else
    echo "  [FAIL] ios/Podfile not found!"
    exit 1
fi

echo "Step 2: Checking native PencilKit Swift sources..."
if [ -f "ios/Runner/PencilKit/AtlasPencilKitPlugin.swift" ] && [ -f "ios/Runner/AppDelegate.swift" ]; then
    echo "  [PASS] AtlasPencilKitPlugin.swift and AppDelegate.swift present."
else
    echo "  [FAIL] Missing iOS native source files in ios/Runner/"
    exit 1
fi

# 2. Host Operating System Check
OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then
    echo "Step 3: macOS detected. Executing local Xcode verification build..."

    # Check Xcode command-line tools
    if ! command -v xcodebuild >/dev/null 2>&1; then
        echo "  [FAIL] xcodebuild not found. Install Xcode Command Line Tools via 'xcode-select --install'."
        exit 1
    fi

    echo "  Xcode version: $(xcodebuild -version | tr '\n' ' ')"

    # Clean and fetch pods
    flutter pub get
    cd ios
    pod install --repo-update
    cd "$ROOT_DIR"

    # Build iOS unsigned bundle
    echo "  Building Flutter iOS release bundle (no codesign)..."
    flutter build ios --no-codesign --release

    # Xcodebuild archive command
    echo "  Archiving with xcodebuild..."
    xcodebuild -workspace ios/Runner.xcworkspace \
               -scheme Runner \
               -configuration Release \
               -destination "generic/platform=iOS" \
               -archivePath build/ios/archive/Atlas.xcarchive \
               clean archive \
               CODE_SIGNING_ALLOWED=NO

    echo "=== iOS verification archive completed at build/ios/archive/Atlas.xcarchive ==="
    echo "To export signed IPA for App Store / Ad Hoc distribution:"
    echo "  xcodebuild -exportArchive \\"
    echo "             -archivePath build/ios/archive/Atlas.xcarchive \\"
    echo "             -exportPath build/ios/ipa \\"
    echo "             -exportOptionsPlist ios/ExportOptions.plist"
else
    echo "Step 3: Host OS is $OS (Linux). Cross-compiling Darwin Mach-O / Xcode binaries requires macOS."
    echo ""
    echo "=== REPRODUCIBLE macOS XCODE BUILD INSTRUCTIONS ==="
    echo "On your macOS build agent or developer workstation:"
    echo ""
    echo "  1. Clone repository & install dependencies:"
    echo "     git clone <repo-url> atlas && cd atlas"
    echo "     flutter pub get"
    echo ""
    echo "  2. Install CocoaPods dependencies:"
    echo "     cd ios && pod install && cd .."
    echo ""
    echo "  3. Build unsigned Flutter release bundle:"
    echo "     flutter build ios --no-codesign --release"
    echo ""
    echo "  4. Build Xcode Release Archive:"
    echo "     xcodebuild -workspace ios/Runner.xcworkspace \\"
    echo "                -scheme Runner \\"
    echo "                -configuration Release \\"
    echo "                -destination 'generic/platform=iOS' \\"
    echo "                -archivePath build/ios/archive/Atlas.xcarchive \\"
    echo "                archive"
    echo ""
    echo "  5. Export Signed .ipa with ExportOptions.plist:"
    echo "     xcodebuild -exportArchive \\"
    echo "                -archivePath build/ios/archive/Atlas.xcarchive \\"
    echo "                -exportPath build/ios/ipa \\"
    echo "                -exportOptionsPlist ios/ExportOptions.plist"
    echo ""
    echo "Configuration check passed successfully on Linux."
fi
