Here's the complete README.md file for your version 2.0.0 release:

```markdown
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
- 🗂️ Custom subfolder organization (Android)
- ⏭️ Skip saving if file already exists
- ✨ Support for multiple file formats
- 📱 Works on both iOS and Android

## Supported Platforms & Versions

- **Android:** 5.0 (API level 21) and above
- **iOS:** 9.0 and above

## Supported File Types

### Images
- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)
- HEIC (.heic) - iOS only
- WebP (.webp) - Android only
- BMP (.bmp)

### Videos
- MP4 (.mp4)
- MOV (.mov)
- 3GP (.3gp)
- MKV (.mkv) - Android only
- AVI (.avi) - Android only
- WebM (.webm) - Android only

## Getting Started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  vision_gallery_saver: ^2.0.0
```

### Required Permissions

#### iOS
Add the following keys to your Info.plist file:

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs access to save photos and videos to your gallery.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to check if files exist in your gallery.</string>
```

#### Android
Add these permissions to your AndroidManifest.xml:

```xml
<!-- For Android 9 (API 28) and below -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<!-- For Android 13 (API 33) and above -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
```

For Android 10 (API level 29) and above, add this to your application tag:

```xml
<application
    android:requestLegacyExternalStorage="true"
    ...>
</application>
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
    name: "my_image",
    skipIfExists: true,
    androidRelativePath: "Pictures/MyApp/Screenshots"
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
    name: "network_image",
    skipIfExists: false,
    androidRelativePath: "Pictures/MyApp/Downloads"
);
```

### Save Video File

```dart
final result = await VisionGallerySaver.saveFile(
    "/path/to/video.mp4",
    name: "my_video",
    skipIfExists: true,
    androidRelativePath: "Movies/MyApp"
);
```

## Example App

Check out the [example](example) folder for a complete demo app showcasing all features.

## API Reference

### VisionGallerySaver.saveImage()

```dart
static Future<Map<String, dynamic>> saveImage(
  Uint8List imageBytes, {
  int quality = 80,
  String? name,
  bool isReturnImagePathOfIOS = false,
  bool skipIfExists = false,
  String? androidRelativePath,
})
```

### VisionGallerySaver.saveFile()

```dart
static Future<Map<String, dynamic>> saveFile(
  String file, {
  String? name,
  bool isReturnPathOfIOS = false,
  bool skipIfExists = false,
  String? androidRelativePath,
})
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `imageBytes` | `Uint8List` | The image data to save |
| `file` | `String` | The path to the file to save |
| `quality` | `int` | JPEG compression quality (1-100) |
| `name` | `String?` | Custom filename for the saved file |
| `isReturnImagePathOfIOS` | `bool` | Whether to return the image path on iOS (for saveImage) |
| `isReturnPathOfIOS` | `bool` | Whether to return the file path on iOS (for saveFile) |
| `skipIfExists` | `bool` | Skip saving if a file with the same name already exists |
| `androidRelativePath` | `String?` | Custom subfolder path in gallery (Android only) |

### Return Value Format

Methods return a Map with the following structure:
```dart
{
  "isSuccess": true/false,
  "filePath": "path/to/saved/file",           // Path to the new file (if saved)
  "errorMessage": "error message",            // If isSuccess is false
  "foundExistingFile": true/false,            // If skipIfExists is true and file exists
  "existingFilePath": "path/to/existing/file" // If foundExistingFile is true
}
```

## Advanced Usage

### Custom Subfolder Organization (Android only)

For Android, you can organize saved files in custom subfolders within standard directories:

```dart
// Save to Pictures/MyApp/ProfilePhotos
await VisionGallerySaver.saveImage(
  imageBytes,
  androidRelativePath: "Pictures/MyApp/ProfilePhotos"
);

// Save to Movies/MyApp/Tutorials
await VisionGallerySaver.saveFile(
  videoPath,
  androidRelativePath: "Movies/MyApp/Tutorials"
);
```

### Skip Duplicate Files

To avoid saving duplicate files with the same name:

```dart
final result = await VisionGallerySaver.saveImage(
  imageBytes,
  name: "unique_image_name",
  skipIfExists: true
);

if (result['foundExistingFile'] == true) {
  print("File already exists at: ${result['existingFilePath']}");
} else {
  print("New file saved at: ${result['filePath']}");
}
```

## Troubleshooting

### Common Issues

1. **File not saved on Android 10+**: Make sure to add `android:requestLegacyExternalStorage="true"` to your application tag.

2. **Permission Denied**: Ensure you've added all required permissions to your manifest or Info.plist.

3. **File not appearing in gallery**: On Android, make sure the MIME type is correctly detected based on file extension.

4. **Return path is null on iOS**: The `isReturnImagePathOfIOS` and `isReturnPathOfIOS` parameters must be set to true.

### Debug Mode

Add debug prints to track operation progress:

```dart
final result = await VisionGallerySaver.saveImage(imageBytes, quality: 100, name: "test_image");
print("Save result: $result");
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
```
