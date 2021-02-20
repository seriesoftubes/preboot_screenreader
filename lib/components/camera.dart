import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as imglib;
import 'package:native_opencv/native_opencv.dart';

import 'classifier.dart';
import 'text_recognition.dart';
import 'text_recognition_painter.dart';
import 'text_to_speech.dart';

class CameraFeed extends StatefulWidget {
  @override
  _CameraFeedState createState() => _CameraFeedState();
}

class _CameraFeedState extends State<CameraFeed> {
  Classifier _classifier;
  TextToSpeech _tts;
  TextRecognition _tr;
  CameraController cameraController;
  Size cameraPreviewSize;
  bool isDetecting = false;
  String _prediction = "None";
  String prediction, lastPrediction;
  VisionText visionText;

  Future initCamera(CameraDescription cameraDescription) async {
    if (cameraController != null) {
      await cameraController.dispose();
    }

    cameraController =
        CameraController(cameraDescription, ResolutionPreset.veryHigh);

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

  // Display text recognition painter preview
  Widget textPainterPreview() {
    CustomPainter painter;
    if (visionText == null) {
      return Container();
    }
    cameraPreviewSize = Size(
      cameraController.value.previewSize.height,
      cameraController.value.previewSize.width,
    );
    painter = TextRecognitionPainter(cameraPreviewSize, visionText);

    return CustomPaint(
      foregroundPainter: painter,
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
    _tts.stop();
    _tr.close();
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
        child: Stack(fit: StackFit.expand, children: <Widget>[
          cameraPreview(),
          textPainterPreview(),
          Align(
            alignment: Alignment.bottomCenter,
            child: predictionText(),
          )
        ]),
      ),
    );
  }

  /// Initializes the camera views choosing the first camera available.
  void _init() async {
    _classifier = Classifier(); // loads the model.
    _tts = TextToSpeech(); // initialize text to speech
    _tr = TextRecognition(); // initialize text recognition
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

    // Classify screen
    prediction = await _classifier.classify(img);

    if (lastPrediction == prediction) {
      if (lastPrediction == "BIOS SCREEN") {
        // Convert CameraImage to Image
        imglib.Image convertedImg = imglib.Image.fromBytes(
          img.width,
          img.height,
          img.planes[0].bytes,
          format: imglib.Format.bgra,
        );
        // Detect Squares
        List<List<double>> rect_coords =
            NativeOpencv().detect_squares(convertedImg);
        // Recognize text
        visionText = await _tr.recognizeText(img);
      }
    } else {
      if (prediction == "BOOT SCREEN") {
        visionText = null;
        _tts.speak("BOOT SCREEN. Press the key to enter BIOS screen.");
      } else if (prediction == "BIOS SCREEN") {
        // Convert CameraImage to Image
        imglib.Image convertedImg = imglib.Image.fromBytes(
          img.width,
          img.height,
          img.planes[0].bytes,
          format: imglib.Format.bgra,
        );
        // Detect Squares
        List<List<double>> rect_coords =
            NativeOpencv().detect_squares(convertedImg);
        // Recognize text
        visionText = await _tr.recognizeText(img);
        // Text to speech
        _tts.speak("BIOS SCREEN");
      } else {
        visionText = null;
      }
    }

    setState(() {
      _prediction = prediction;
    });

    lastPrediction = prediction;

    isDetecting = false;
  }
}
