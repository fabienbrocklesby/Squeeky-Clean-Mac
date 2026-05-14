#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/ReleasePackage"
DERIVED_DATA="$BUILD_DIR/DerivedData"
PRODUCTS_DIR="$DERIVED_DATA/Build/Products/Release"
APP_NAME="Squeeky Clean Mac.app"
ZIP_NAME="Squeeky-Clean-Mac.zip"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

xcodebuild \
  -project "$ROOT_DIR/SqueekyCleanMac.xcodeproj" \
  -scheme SqueekyCleanMac \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
  build

ditto -c -k --keepParent "$PRODUCTS_DIR/$APP_NAME" "$BUILD_DIR/$ZIP_NAME"

echo "$BUILD_DIR/$ZIP_NAME"
