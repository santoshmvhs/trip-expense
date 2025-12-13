#!/bin/bash
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Install Flutter
echo "Installing Flutter..."
FLUTTER_VERSION="stable"  # Use latest stable version
FLUTTER_SDK_PATH="$HOME/flutter"

if [ ! -d "$FLUTTER_SDK_PATH" ]; then
  git clone --branch stable https://github.com/flutter/flutter.git "$FLUTTER_SDK_PATH"
  cd "$FLUTTER_SDK_PATH"
  git pull
  cd "$SCRIPT_DIR"
fi

export PATH="$FLUTTER_SDK_PATH/bin:$PATH"

# Verify Flutter installation
flutter --version

# Ensure we're in the project directory
cd "$SCRIPT_DIR"
pwd
ls -la

# Get dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Build web
echo "Building Flutter web app..."
flutter build web --release

echo "Build completed successfully!"

