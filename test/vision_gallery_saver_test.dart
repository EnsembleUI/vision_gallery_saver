import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vision_gallery_saver/vision_gallery_saver.dart';
import 'package:vision_gallery_saver/vision_gallery_saver_platform_interface.dart';
import 'package:vision_gallery_saver/vision_gallery_saver_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockVisionGallerySaverPlatform
    with MockPlatformInterfaceMixin
    implements VisionGallerySaverPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<Map<String, dynamic>> saveFile(String file,
      {String? name, bool isReturnPathOfIOS = false}) {
    // TODO: implement saveFile
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> saveImage(Uint8List imageBytes,
      {int quality = 80, String? name, bool isReturnImagePathOfIOS = false}) {
    // TODO: implement saveImage
    throw UnimplementedError();
  }
}

void main() {
  final VisionGallerySaverPlatform initialPlatform =
      VisionGallerySaverPlatform.instance;

  test('$MethodChannelVisionGallerySaver is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelVisionGallerySaver>());
  });

  test('getPlatformVersion', () async {
    VisionGallerySaver visionGallerySaverPlugin = VisionGallerySaver();
    MockVisionGallerySaverPlatform fakePlatform =
        MockVisionGallerySaverPlatform();
    VisionGallerySaverPlatform.instance = fakePlatform;

    expect(await visionGallerySaverPlugin.getPlatformVersion(), '42');
  });
}
