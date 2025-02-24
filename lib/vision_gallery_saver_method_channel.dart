import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'vision_gallery_saver_platform_interface.dart';

/// An implementation of [VisionGallerySaverPlatform] that uses method channels.
class MethodChannelVisionGallerySaver extends VisionGallerySaverPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('vision_gallery_saver');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<Map<String, dynamic>> saveImage(
    Uint8List imageBytes, {
    int quality = 80,
    String? name,
    bool isReturnImagePathOfIOS = false,
  }) async {
    final result = await methodChannel.invokeMethod('saveImageToGallery', {
      'imageBytes': imageBytes,
      'quality': quality,
      'name': name,
      'isReturnImagePathOfIOS': isReturnImagePathOfIOS,
    });
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<Map<String, dynamic>> saveFile(
    String file, {
    String? name,
    bool isReturnPathOfIOS = false,
  }) async {
    final result = await methodChannel.invokeMethod('saveFileToGallery', {
      'file': file,
      'name': name,
      'isReturnPathOfIOS': isReturnPathOfIOS,
    });
    return Map<String, dynamic>.from(result);
  }
  
}
