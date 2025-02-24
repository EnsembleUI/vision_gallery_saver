# vision_gallery_saver

A Flutter plugin for saving images and videos to the gallery on iOS and Android platforms.

[![pub package](https://img.shields.io/pub/v/vision_gallery_saver.svg)](https://pub.dev/packages/vision_gallery_saver)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- 🖼️ Save images from widgets to gallery
- 🌐 Save images from network URLs
- 📹 Save videos from local files or URLs
- 🎨 Support for custom quality settings
- 📝 Custom file naming
- ✨ Support for PNG, JPG, GIF formats
- 📱 Works on both iOS and Android

## Getting Started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  vision_gallery_saver: ^1.0.0
```

### Platform Setup

#### iOS
Add the following keys to your Info.plist file:

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs access to save photos and videos to your gallery.</string>
```

#### Android
For Android 10 (API level 29) and above, add this to your AndroidManifest.xml:

```xml
<manifest ...>
    <application
        android:requestLegacyExternalStorage="true"
        ...>
    </application>
</manifest>
```

## Usage

### Save a Widget as Image

```dart
// Using GlobalKey with RepaintBoundary
final GlobalKey _globalKey = GlobalKey();

// Inside your widget tree
RepaintBoundary(
  key: _globalKey,
  child: YourWidget(),
)

// Save the widget
RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
ui.Image image = await boundary.toImage();
ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
if (byteData != null) {
  final result = await VisionGallerySaver.saveImage(
    byteData.buffer.asUint8List(),
    quality: 100,
    name: "my_image"
  );
  print(result);
}
```

### Save Network Image

```dart
var response = await Dio().get(
    "https://example.com/image.jpg",
    options: Options(responseType: ResponseType.bytes));
final result = await VisionGallerySaver.saveImage(
    Uint8List.fromList(response.data),
    quality: 100,
    name: "network_image"
);
```

### Save Video File

```dart
final result = await VisionGallerySaver.saveFile(
    "/path/to/video.mp4",
    name: "my_video"
);
```

## Example App

Check out the [example](example) folder for a complete demo app showcasing all features.

## API Reference

### VisionGallerySaver.saveImage()

```dart
static Future<Map<dynamic, dynamic>> saveImage(
  Uint8List imageBytes, {
  int quality = 80,
  String? name,
  bool isReturnImagePathOfIOS = false
})
```

### VisionGallerySaver.saveFile()

```dart
static Future<Map<dynamic, dynamic>> saveFile(
  String file, {
  String? name,
  bool isReturnPathOfIOS = false
})
```

## Return Value Format

Methods return a Map with the following structure:
```dart
{
  "isSuccess": true/false,
  "filePath": "path/to/saved/file",  // Optional
  "errorMessage": "error message"     // If isSuccess is false
}
```

## Contributing

Contributions are welcome! Please read our [contributing guidelines](CONTRIBUTING.md) to get started.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.