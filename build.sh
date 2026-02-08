#!/usr/bin/env bash
set -e

# Flutter web build for Cloudflare Pages
# Cloudflare's image doesn't include Flutter, so we install it here.
# Build output: build/web/
# In Cloudflare Pages: set "Build output directory" to build/web

FLUTTER_DIR="${FLUTTER_DIR:-$HOME/flutter}"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"

echo "==> Installing Flutter SDK..."
if [ ! -d "$FLUTTER_DIR/bin" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_CHANNEL" "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

echo "==> Flutter version"
flutter --version

echo "==> Enabling web"
flutter config --enable-web

echo "==> Flutter pub get"
flutter pub get

echo "==> Flutter build web"
flutter build web --release

echo "==> Build complete. Output in build/web/"
