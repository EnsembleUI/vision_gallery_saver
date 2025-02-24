import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:vision_gallery_saver/vision_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  debugPrint('App starting...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avengers Gallery Saver',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey _globalKey = GlobalKey();
  String _lastSavedPath = '';

  @override
  void initState() {
    super.initState();
    debugPrint('MyHomePage initialized');
  }

  void _showSaveResult(Map<dynamic, dynamic> result) {
    debugPrint('Save result received: $result');

    if (result['isSuccess']) {
      String? filePath = result['filePath'];
      debugPrint('File saved at path: $filePath');

      if (filePath != null && filePath.isNotEmpty) {
        setState(() {
          _lastSavedPath = filePath;
        });

        if (Platform.isAndroid) {
          String galleryPath = '/storage/emulated/0/Pictures';
          debugPrint('Android gallery path: $galleryPath');
        }

        if (Platform.isIOS) {
          debugPrint('File saved to iOS Photos app');
        }
      }
    } else {
      debugPrint('Save failed: ${result['errorMessage']}');
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            result['isSuccess'] ? 'Saved successfully!' : 'Failed to save')));
  }

  _saveShieldImage() async {
    debugPrint('Starting to save shield image...');
    try {
      RenderRepaintBoundary boundary =
          _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      debugPrint('Got render boundary');

      ui.Image image = await boundary.toImage();
      debugPrint('Converted boundary to image');

      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      debugPrint('Converted image to byte data. Null? ${byteData == null}');

      if (byteData != null) {
        final filename =
            "captain_america_shield_${DateTime.now().millisecondsSinceEpoch}";
        debugPrint('Saving shield with filename: $filename');

        final result = await VisionGallerySaver.saveImage(
          byteData.buffer.asUint8List(),
          quality: 100,
          name: filename,
          isReturnImagePathOfIOS: true,
        );
        debugPrint('Shield save result: $result');
        _showSaveResult(result);
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving shield: $e');
      debugPrint('Stack trace: $stackTrace');
      _showSaveResult({'isSuccess': false, 'errorMessage': e.toString()});
    }
  }

  _saveIronManImage() async {
    debugPrint('Starting to download Iron Man image...');
    try {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Downloading Iron Man image...")));

      debugPrint('Fetching from URL: https://i.imgur.com/XcDD7mg.jpeg');
      var response = await Dio().get("https://i.imgur.com/XcDD7mg.jpeg",
          options: Options(responseType: ResponseType.bytes));
      debugPrint('Image downloaded, size: ${response.data.length} bytes');

      final filename = "iron_man_${DateTime.now().millisecondsSinceEpoch}";
      debugPrint('Saving with filename: $filename');

      final result = await VisionGallerySaver.saveImage(
        Uint8List.fromList(response.data),
        quality: 100,
        name: filename,
        isReturnImagePathOfIOS: true,
      );
      debugPrint('Iron Man save result: $result');
      _showSaveResult(result);
    } catch (e, stackTrace) {
      debugPrint('Error saving Iron Man image: $e');
      debugPrint('Stack trace: $stackTrace');
      _showSaveResult({'isSuccess': false, 'errorMessage': e.toString()});
    }
  }

  _saveThorGif() async {
    debugPrint('Starting to download Thor image...');
    try {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Downloading Thor image...")));

      var appDocDir = await getTemporaryDirectory();
      String savePath = "${appDocDir.path}/thor.gif";
      debugPrint('Temporary save path: $savePath');

      String fileUrl = "https://i.imgur.com/yeg063e.jpeg";
      debugPrint('Downloading from URL: $fileUrl');

      await Dio().download(fileUrl, savePath);
      debugPrint('File downloaded to temp location');

      final filename = "thor_${DateTime.now().millisecondsSinceEpoch}";
      final result = await VisionGallerySaver.saveFile(
        savePath,
        name: filename,
        isReturnPathOfIOS: true,
      );
      debugPrint('Thor save result: $result');
      _showSaveResult(result);

      // Clean up temp file
      try {
        File(savePath).deleteSync();
        debugPrint('Temporary file cleaned up successfully');
      } catch (e) {
        debugPrint('Error cleaning up temp file: $e');
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving Thor image: $e');
      debugPrint('Stack trace: $stackTrace');
      _showSaveResult({'isSuccess': false, 'errorMessage': e.toString()});
    }
  }

  _saveEndgameTrailer() async {
    debugPrint('Starting to download Endgame trailer...');
    try {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Downloading Endgame trailer...")));

      var appDocDir = await getTemporaryDirectory();
      String savePath = "${appDocDir.path}/endgame.mp4";
      debugPrint('Temporary save path: $savePath');

      String fileUrl = "https://i.imgur.com/68NpINq.mp4";
      debugPrint('Downloading from URL: $fileUrl');

      await Dio().download(fileUrl, savePath, onReceiveProgress: (count, total) {
        if (total != -1) {
          final progress = (count / total * 100).toStringAsFixed(0);
          debugPrint('Download progress: $progress%');
        }
      });
      debugPrint('Video downloaded to temp location');

      final filename = "endgame_${DateTime.now().millisecondsSinceEpoch}";
      final result = await VisionGallerySaver.saveFile(
        savePath,
        name: filename,
        isReturnPathOfIOS: true,
      );
      debugPrint('Endgame trailer save result: $result');
      _showSaveResult(result);

      // Clean up temp file
      try {
        File(savePath).deleteSync();
        debugPrint('Temporary file cleaned up successfully');
      } catch (e) {
        debugPrint('Error cleaning up temp file: $e');
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving Endgame trailer: $e');
      debugPrint('Stack trace: $stackTrace');
      _showSaveResult({'isSuccess': false, 'errorMessage': e.toString()});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Avengers Gallery Saver"),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 20),
            RepaintBoundary(
              key: _globalKey,
              child: Container(
                alignment: Alignment.center,
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.red, Colors.white, Colors.blue],
                    stops: [0.2, 0.5, 0.8],
                  ),
                ),
                child: const Icon(Icons.shield, size: 150, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveShieldImage,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(250, 50),
              ),
              child: const Text("Save Captain's Shield"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveIronManImage,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(250, 50),
              ),
              child: const Text("Save Iron Man Image"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveThorGif,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(250, 50),
              ),
              child: const Text("Save Thor Image"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveEndgameTrailer,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(250, 50),
              ),
              child: const Text("Save Endgame Trailer"),
            ),
            if (_lastSavedPath.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Last saved at:\n$_lastSavedPath",
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}