import 'package:flutter/foundation.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'vision_gallery_saver_method_channel.dart';

abstract class VisionGallerySaverPlatform extends PlatformInterface {
  /// Constructs a VisionGallerySaverPlatform.
  VisionGallerySaverPlatform() : super(token: _token);

  static final Object _token = Object();

  static VisionGallerySaverPlatform _instance =
      MethodChannelVisionGallerySaver();

  /// The default instance of [VisionGallerySaverPlatform] to use.
  ///
  /// Defaults to [MethodChannelVisionGallerySaver].
  static VisionGallerySaverPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VisionGallerySaverPlatform] when
  /// they register themselves.
  static set instance(VisionGallerySaverPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Save image to gallery
  ///
  /// [imageBytes] The image data to save
  /// [quality] The image quality (1-100)
  /// [name] Optional custom filename
  /// [isReturnImagePathOfIOS] Whether to return the file path on iOS
  /// [skipIfExists] Skip saving if file with same name exists
  /// [androidRelativePath] Custom subfolder path for Android
  Future<Map<String, dynamic>> saveImage(
    Uint8List imageBytes, {
    int quality = 80,
    String? name,
    bool isReturnImagePathOfIOS = false,
    bool skipIfExists = false,
    String? androidRelativePath,
  }) {
    throw UnimplementedError('saveImage() has not been implemented.');
  }

  /// Save file to gallery
  ///
  /// [file] Path to the file to save
  /// [name] Optional custom filename
  /// [isReturnPathOfIOS] Whether to return the file path on iOS
  /// [skipIfExists] Skip saving if file with same name exists
  /// [androidRelativePath] Custom subfolder path for Android
  Future<Map<String, dynamic>> saveFile(
    String file, {
    String? name,
    bool isReturnPathOfIOS = false,
    bool skipIfExists = false,
    String? androidRelativePath,
  }) {
    throw UnimplementedError('saveFile() has not been implemented.');
  }
}
