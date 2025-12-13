# Assets Folder

This folder contains images and icons used in the Flutter app.

## Folder Structure

```
assets/
├── images/     # General images (photos, illustrations, etc.)
└── icons/      # Icon files
```

## How to Add Your Image

1. **Save your image file** (PNG, JPG, or SVG) to either:
   - `assets/images/` for general images
   - `assets/icons/` for icon files

2. **The image is automatically included** - `pubspec.yaml` is already configured!

3. **Use it in your code:**
   ```dart
   Image.asset('assets/images/your_image.png')
   ```

## App Launcher Icon Setup

To use your image as the app icon (home screen icon):

1. Save your image as `assets/images/app_icon.png` (1024x1024px recommended)

2. Uncomment the `flutter_launcher_icons` section in `pubspec.yaml`:
   ```yaml
   flutter_launcher_icons:
     android: true
     ios: true
     image_path: "assets/images/app_icon.png"
   ```

3. Run:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

This will automatically generate all required icon sizes for Android and iOS!

## Image Requirements

- **Format**: PNG (recommended), JPG, or SVG
- **App Icon Size**: 1024x1024px (square)
- **Other Images**: Any size, but consider performance for large images

