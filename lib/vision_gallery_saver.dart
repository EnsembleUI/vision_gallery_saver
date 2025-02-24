import 'package:flutter/foundation.dart';
import 'vision_gallery_saver_platform_interface.dart';

/// VisionGallerySaver: A powerful tool for saving media to your device's gallery,
/// inspired by Vision's ability to process and store digital information.
class VisionGallerySaver {
  /// Get the platform version
  Future<String?> getPlatformVersion() {
    return VisionGallerySaverPlatform.instance.getPlatformVersion();
  }

  /// Save image to gallery with Vision's precision
  /// [imageBytes] required: The digital essence of the image (bytes)
  /// [quality] optional: The clarity level (1-100)
  /// [name] optional: The designation for the image
  /// [isReturnImagePathOfIOS] whether to return the image coordinates for iOS
  static Future<Map<String, dynamic>> saveImage(
    Uint8List imageBytes, {
    int quality = 80,
    String? name,
    bool isReturnImagePathOfIOS = false,
  }) {
    return VisionGallerySaverPlatform.instance.saveImage(
      imageBytes,
      quality: quality,
      name: name,
      isReturnImagePathOfIOS: isReturnImagePathOfIOS,
    );
  }

  /// Save file to gallery with Vision's efficiency
  /// [file] The path to your digital asset
  /// [name] optional: The designation for the file
  /// [isReturnPathOfIOS] whether to return the file coordinates for iOS
  static Future<Map<String, dynamic>> saveFile(
    String file, {
    String? name,
    bool isReturnPathOfIOS = false,
  }) {
    return VisionGallerySaverPlatform.instance.saveFile(
      file,
      name: name,
      isReturnPathOfIOS: isReturnPathOfIOS,
    );
  }
}