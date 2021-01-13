import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

import 'classifier.dart';

class CameraFeed extends StatefulWidget {
  @override
  _CameraFeedState createState() => _CameraFeedState();
}

class _CameraFeedState extends State<CameraFeed> {
  Classifier _classifier;
  CameraController cameraController;
  bool isDetecting = false;
  String _prediction;

  Future initCamera(CameraDescription cameraDescription) async {
    if (cameraController != null) {
      await cameraController.dispose();
    }

    cameraController =
        CameraController(cameraDescription, ResolutionPreset.medium);

    if (cameraController.value.hasError) {
      print('Camera Error ${cameraController.value.errorDescription}');
    }

    try {
      await cameraController.initialize();
    } catch (e) {
      print('Error ${e.code} \nError message: ${e.description}');
    }

    if (!mounted) return;
    cameraController.startImageStream(_onImageAvailable);

    setState(() {});
  }

  // Display camera preview
  Widget cameraPreview() {
    if (cameraController == null || !cameraController.value.isInitialized) {
      return Text(
        'Loading',
        style: TextStyle(
            color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
      );
    }

    return AspectRatio(
      aspectRatio: cameraController.value.aspectRatio,
      child: CameraPreview(cameraController),
    );
  }

  // Display prediction text
  Widget predictionText() {
    return Text(
      'Screen class: $_prediction',
      style: TextStyle(
          color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
    );
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
    if (cameraController != null) {
      cameraController.stopImageStream();
      cameraController.dispose();
      cameraController = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        child: Stack(children: <Widget>[
          Align(
            alignment: Alignment.center,
            child: cameraPreview(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: predictionText(),
          ),
        ]),
      ),
    );
  }

  /// Initializes the camera views choosing the first camera available.
  void _init() async {
    _classifier = Classifier(); // loads the model.
    try {
      final cameras = await availableCameras();
      if (cameras?.isNotEmpty ?? false) {
        await initCamera(cameras.first);
      } else {
        print('No camera available');
      }
    } catch (e) {
      print('Error : ${e.code}');
    }
  }

  void _onImageAvailable(CameraImage img) async {
    if (isDetecting) return;
    isDetecting = true;

    var prediction = await _classifier.classify(img);

    setState(() {
      _prediction = prediction;
    });

    isDetecting = false;
  }
}
