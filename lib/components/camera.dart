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

  Future initCamera(CameraDescription cameraDescription) async {
    if (cameraController != null) {
      await cameraController.dispose();
    }

    cameraController =
        CameraController(cameraDescription, ResolutionPreset.medium);

    // cameraController.addListener(() {
    //   if (mounted) {
    //     setState(() {});
    //   }
    // });

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

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
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

    //imglib.Image img = convertCameraImage(camImg);
    // await _classifier.classify(img);
    print('PREDICTING...');
    try {
      final recognition = await Tflite.runModelOnFrame(
        bytesList: img.planes.map((plane) {
          return plane.bytes;
        }).toList(), // required
        imageHeight: img.height,
        imageWidth: img.width,
        imageMean: 127.5, // defaults to 127.5
        imageStd: 127.5, // defaults to 127.5
        rotation: 90, // defaults to 90, Android only
        numResults: 1, // defaults to 5
        threshold: 0.1, // defaults to 0.1
        asynch: true, // defaults to true
      );
      print('RECOGNITION: $recognition');
    } catch (e) {
      print('erro $e');
    }

    isDetecting = false;
  }
}
