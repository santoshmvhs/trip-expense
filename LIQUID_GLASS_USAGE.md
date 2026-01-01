# Liquid Glass Effect Usage Guide

The liquid glass effect provides an iOS-style frosted glass appearance with blur and transparency. It's automatically enabled on iOS devices and can be enabled on other platforms.

## Available Widgets

### 1. LiquidGlassCard
A card widget with glass effect, perfect for list items and content cards.

```dart
import 'package:trip/widgets/liquid_glass_card.dart';

LiquidGlassCard(
  onTap: () {
    // Handle tap
  },
  borderRadius: 20,
  blurIntensity: 12,
  padding: const EdgeInsets.all(16),
  child: Column(
    children: [
      Text('Your content here'),
    ],
  ),
)
```

### 2. LiquidGlassContainer
A simpler container version for basic glass effects.

```dart
LiquidGlassContainer(
  padding: const EdgeInsets.all(16),
  borderRadius: 16,
  blurIntensity: 8,
  child: Text('Glass container'),
)
```

### 3. LiquidGlassAppBar
An AppBar with glass effect.

```dart
LiquidGlassAppBar(
  title: Text('My App'),
  actions: [IconButton(...)],
)
```

## Parameters

### LiquidGlassCard & LiquidGlassContainer
- `child` (required): The widget to display inside
- `padding`: Internal padding
- `margin`: External margin
- `width` / `height`: Optional size constraints
- `borderRadius`: Corner radius (default: 20.0 for Card, 16.0 for Container)
- `blurIntensity`: Blur amount (default: 10.0 for Card, 8.0 for Container)
- `backgroundColor`: Custom background color (auto-detected if null)
- `borderColor`: Custom border color (auto-detected if null)
- `borderWidth`: Border thickness (default: 1.0)
- `shadows`: Custom box shadows
- `onTap`: Optional tap handler
- `enableGlassEffect`: Force enable/disable glass effect (default: true, auto-enabled on iOS)

## Examples

### Basic Card
```dart
LiquidGlassCard(
  child: ListTile(
    leading: Icon(Icons.group),
    title: Text('Group Name'),
    subtitle: Text('Description'),
  ),
)
```

### Custom Styled Card
```dart
LiquidGlassCard(
  borderRadius: 24,
  blurIntensity: 15,
  backgroundColor: Colors.white.withOpacity(0.1),
  borderColor: Colors.white.withOpacity(0.2),
  padding: const EdgeInsets.all(20),
  child: YourContent(),
)
```

### Container with Glass Effect
```dart
LiquidGlassContainer(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: Row(
    children: [
      Icon(Icons.info),
      SizedBox(width: 8),
      Text('Info message'),
    ],
  ),
)
```

## Platform Behavior

- **iOS**: Glass effect is automatically enabled
- **Other platforms**: Glass effect is enabled by default but can be disabled
- Set `enableGlassEffect: false` to disable the blur effect while keeping the styling

## Performance Notes

- The blur effect uses `BackdropFilter` which can be performance-intensive
- Use sparingly on screens with many items
- Consider using `LiquidGlassContainer` for simpler cases as it has lower blur intensity by default

