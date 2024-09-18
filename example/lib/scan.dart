import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:document_edge/document_edge.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:document_edge_example/cropping_preview.dart';

import 'camera_view.dart';
import 'image_view.dart';

class Scan extends StatefulWidget {
  const Scan({Key? key}) : super(key: key);

  @override
  _ScanState createState() => _ScanState();
}

class _ScanState extends State<Scan> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  String? imagePath;
  String? croppedImagePath;
  EdgeDetectionResult? edgeDetectionResult;

  @override
  void initState() {
    super.initState();
    checkForCameras().then((value) {
      _initializeController();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          _getMainWidget(),
          _getBottomBar(),
        ],
      ),
    );
  }

  Widget _getMainWidget() {
    if (croppedImagePath != null) {
      return ImageView(imagePath: croppedImagePath!);
    }

    if (imagePath == null && edgeDetectionResult == null) {
      return controller == null
          ? Container()
          : CameraView(controller: controller!);
    }

    return ImagePreview(
      imagePath: imagePath!,
      edgeDetectionResult: edgeDetectionResult,
    );
  }

  Future<void> checkForCameras() async {
    cameras = await availableCameras();
  }

  void _initializeController() {
    checkForCameras();
    if (cameras!.isEmpty) {
      log('No cameras detected');
      return;
    }

    controller = CameraController(cameras![0], ResolutionPreset.veryHigh,
        enableAudio: false);
    controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Widget _getButtonRow() {
    if (imagePath != null) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: FloatingActionButton(
          child: const Icon(Icons.check),
          onPressed: () async {
            if (croppedImagePath == null) {
              return await _processImage(imagePath!, edgeDetectionResult!);
            }

            setState(() {
              imagePath = null;
              edgeDetectionResult = null;
              croppedImagePath = null;
            });
          },
        ),
      );
    }

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      FloatingActionButton(
        foregroundColor: Colors.white,
        child: const Icon(Icons.camera_alt),
        onPressed: onTakePictureButtonPressed,
      ),
      const SizedBox(width: 16),
      FloatingActionButton(
        foregroundColor: Colors.white,
        child: const Icon(Icons.image),
        onPressed: _onGalleryButtonPressed,
      ),
    ]);
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<String> takePicture() async {
    if (!controller!.value.isInitialized) {
      log('Error: select a camera first.');
      return "";
    }

    final Directory extDir = await getTemporaryDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    // final String filePath = '$dirPath/${timestamp()}.jpg';

    if (controller!.value.isTakingPicture) {
      return "";
    }

    XFile xfile;

    try {
      xfile = await controller!.takePicture();
    } on CameraException catch (e) {
      log(e.toString());
      return "";
    }
    return xfile.path;
  }

  Future _detectEdges(String filePath) async {
    if (!mounted) {
      return;
    }

    setState(() {
      imagePath = filePath;
    });

    EdgeDetectionResult result = await EdgeDetector().detectEdges(filePath);

    setState(() {
      edgeDetectionResult = result;
    });
  }

  Future _processImage(
      String filePath, EdgeDetectionResult edgeDetectionResult) async {
    if (!mounted) {
      return;
    }

    double rotation = 0;
    bool result = await EdgeDetector()
        .processImage(filePath, edgeDetectionResult, rotation);

    if (result == false) {
      return;
    }

    setState(() {
      imageCache.clearLiveImages();
      imageCache.clear();
      croppedImagePath = imagePath;
    });
  }

  void onTakePictureButtonPressed() async {
    String filePath = await takePicture();

    log('Picture saved to $filePath');

    if (filePath.isNotEmpty) {
      await _detectEdges(filePath);
    }
  }

  void _onGalleryButtonPressed() async {
    ImagePicker picker = ImagePicker();
    XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    final filePath = pickedFile!.path;

    log('Picture saved to $filePath');

    _detectEdges(filePath);
  }

  Padding _getBottomBar() {
    return Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child:
            Align(alignment: Alignment.bottomCenter, child: _getButtonRow()));
  }
}
