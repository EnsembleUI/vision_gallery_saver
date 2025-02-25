import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:vision_gallery_saver/vision_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  debugPrint('Starting Vision Gallery Saver Example App');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vision Gallery Saver',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
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
  bool _saveInProgress = false;

  @override
  void initState() {
    super.initState();
    debugPrint('Vision Gallery Saver HomePage initialized');
  }

  void _showSaveResult(Map<dynamic, dynamic> result) {
    debugPrint('Save result: $result');

    if (result['isSuccess']) {
      String? filePath = result['filePath'] ?? result['existingFilePath'];

      if (filePath != null && filePath.isNotEmpty) {
        setState(() {
          _lastSavedPath = filePath;
        });

        if (result['foundExistingFile'] == true) {
          debugPrint('File already exists at: $filePath');
        } else {
          debugPrint('Successfully saved file to: $filePath');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['foundExistingFile'] == true
                ? 'File already exists: ${filePath.split('/').last}'
                : 'Saved successfully!'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      debugPrint('Save operation failed: ${result['errorMessage']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${result['errorMessage']}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _saveInProgress = false;
    });
  }

  Future<void> _saveShieldImage({bool skipIfExists = false}) async {
    if (_saveInProgress) {
      debugPrint('Save operation already in progress. Ignoring request.');
      return;
    }

    setState(() {
      _saveInProgress = true;
    });

    debugPrint('Starting Shield image save...');
    debugPrint('skipIfExists: $skipIfExists');

    try {
      debugPrint('Rendering RepaintBoundary to image');
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      debugPrint('Converting boundary to high-resolution image (3.0x)');
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      debugPrint('Converting image to PNG byte data');
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        debugPrint('Byte data received, size: ${byteData.lengthInBytes} bytes');
        debugPrint(
            'Saving shield image to gallery with custom subfolder "Pictures/Avengers/Shields"');

        final result = await VisionGallerySaver.saveImage(
          byteData.buffer.asUint8List(),
          quality: 100,
          name: "captain_america_shield",
          isReturnImagePathOfIOS: true,
          skipIfExists: skipIfExists,
          androidRelativePath: "Pictures/Avengers/Shields",
        );

        _showSaveResult(result);
      } else {
        debugPrint('Failed to get byte data from image');
        _showSaveResult({
          'isSuccess': false,
          'errorMessage': 'Failed to convert image to bytes'
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving shield image: $e');
      debugPrint('Stack trace: $stackTrace');
      _showSaveResult({'isSuccess': false, 'errorMessage': e.toString()});
    }
  }

  Future<void> _saveIronManImage() async {
    if (_saveInProgress) {
      debugPrint('Save operation already in progress. Ignoring request.');
      return;
    }

    setState(() {
      _saveInProgress = true;
    });

    debugPrint('Starting Iron Man image download and save...');

    try {
      debugPrint('Downloading Iron Man image from network URL');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Downloading Iron Man image...")));

      debugPrint(
          'Fetching image data from URL: https://i.imgur.com/XcDD7mg.jpeg');
      var response = await Dio().get("https://i.imgur.com/XcDD7mg.jpeg",
          options: Options(responseType: ResponseType.bytes));
      debugPrint('Download complete, received ${response.data.length} bytes');

      debugPrint(
          'Saving Iron Man image to gallery with custom subfolder "Pictures/Avengers/Characters"');
      final result = await VisionGallerySaver.saveImage(
        Uint8List.fromList(response.data),
        quality: 100,
        name: "iron_man",
        isReturnImagePathOfIOS: true,
        skipIfExists: false,
        androidRelativePath: "Pictures/Avengers/Characters",
      );

      _showSaveResult(result);
    } catch (e, stackTrace) {
      debugPrint('Error saving Iron Man image: $e');
      debugPrint('Stack trace: $stackTrace');
      _showSaveResult({'isSuccess': false, 'errorMessage': e.toString()});
    }
  }

  Future<void> _saveThorGif({bool skipIfExists = false}) async {
    if (_saveInProgress) {
      debugPrint('Save operation already in progress. Ignoring request.');
      return;
    }

    setState(() {
      _saveInProgress = true;
    });

    debugPrint('Starting Thor image download and save...');
    debugPrint('skipIfExists: $skipIfExists');

    try {
      debugPrint('Getting temporary directory for download');
      var appDocDir = await getTemporaryDirectory();
      String savePath = "${appDocDir.path}/thor.gif";
      debugPrint('Temp file path: $savePath');

      debugPrint(
          'Downloading Thor image from URL: https://i.imgur.com/yeg063e.jpeg');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Downloading Thor image...")));

      await Dio().download("https://i.imgur.com/yeg063e.jpeg", savePath);
      debugPrint('Download complete, saved to temporary location');

      debugPrint(
          'Saving Thor image to gallery with custom subfolder "Pictures/Avengers/Characters"');
      final result = await VisionGallerySaver.saveFile(
        savePath,
        name: "thor",
        isReturnPathOfIOS: true,
        skipIfExists: skipIfExists,
        androidRelativePath: "Pictures/Avengers/Characters",
      );

      // Clean up temp file
      debugPrint('Deleting temporary file');
      await File(savePath).delete();
      debugPrint('Temporary file deleted');

      _showSaveResult(result);
    } catch (e, stackTrace) {
      debugPrint('Error saving Thor image: $e');
      debugPrint('Stack trace: $stackTrace');
      _showSaveResult({'isSuccess': false, 'errorMessage': e.toString()});
    }
  }

  Future<void> _saveEndgameTrailer() async {
    if (_saveInProgress) {
      debugPrint('Save operation already in progress. Ignoring request.');
      return;
    }

    setState(() {
      _saveInProgress = true;
    });

    debugPrint('Starting Endgame trailer download and save...');

    try {
      debugPrint('Getting temporary directory for download');
      var appDocDir = await getTemporaryDirectory();
      String savePath = "${appDocDir.path}/endgame.mp4";
      debugPrint('Temp file path: $savePath');

      debugPrint(
          'Downloading Endgame trailer from URL: https://i.imgur.com/68NpINq.mp4');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Downloading Endgame trailer...")));

      await Dio().download("https://i.imgur.com/68NpINq.mp4", savePath,
          onReceiveProgress: (received, total) {
        if (total != -1) {
          final progress = (received / total * 100).toStringAsFixed(0);
          debugPrint('Download progress: $progress%');
        }
      });
      debugPrint('Download complete, saved to temporary location');

      debugPrint(
          'Saving Endgame trailer to gallery with custom subfolder "Movies/Avengers/Trailers"');
      final result = await VisionGallerySaver.saveFile(
        savePath,
        name: "endgame_trailer",
        isReturnPathOfIOS: true,
        skipIfExists: false,
        androidRelativePath: "Movies/Avengers/Trailers",
      );

      // Clean up temp file
      debugPrint('Deleting temporary file');
      await File(savePath).delete();
      debugPrint('Temporary file deleted');

      _showSaveResult(result);
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
        title: const Text('Vision Gallery Saver'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular Shield Image
                RepaintBoundary(
                  key: _globalKey,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.blue, Colors.white, Colors.red],
                        stops: [0.2, 0.5, 0.8],
                      ),
                    ),
                    child: const Icon(Icons.shield,
                        size: 150, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),

                // Buttons Section
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    // Shield Buttons
                    ElevatedButton(
                      onPressed: _saveInProgress ? null : _saveShieldImage,
                      child: const Text('Save Shield'),
                    ),
                    ElevatedButton(
                      onPressed: _saveInProgress
                          ? null
                          : () => _saveShieldImage(skipIfExists: true),
                      child: const Text('Save Shield (Skip if Exists)'),
                    ),

                    // Iron Man Button
                    ElevatedButton(
                      onPressed: _saveInProgress ? null : _saveIronManImage,
                      child: const Text('Save Iron Man'),
                    ),

                    // Thor Button
                    ElevatedButton(
                      onPressed: _saveInProgress ? null : _saveThorGif,
                      child: const Text('Save Thor'),
                    ),

                    // Endgame Trailer Button
                    ElevatedButton(
                      onPressed: _saveInProgress ? null : _saveEndgameTrailer,
                      child: const Text('Save Endgame Trailer'),
                    ),
                  ],
                ),

                // Show Loading Indicator
                if (_saveInProgress)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),

                // Show Last Saved Path
                if (_lastSavedPath.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Last saved at:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _lastSavedPath,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
