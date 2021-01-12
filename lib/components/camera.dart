import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'package:tflite/tflite.dart';

import 'package:preboot_screenreader/components/classifier.dart';

class CameraFeed extends StatefulWidget {
  @override
  _CameraFeedState createState() => _CameraFeedState();
}

class _CameraFeedState extends State<CameraFeed> {
  Classifier _classifier;
  CameraController cameraController;
  List cameras;
  int selectedCameraIndex;
  bool isDetecting = false;

  Future initCamera(CameraDescription cameraDescription) async {
    if (cameraController != null) {
      await cameraController.dispose();
    }

    cameraController =
        CameraController(cameraDescription, ResolutionPreset.high);

    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    if (cameraController.value.hasError) {
      print('Camera Error ${cameraController.value.errorDescription}');
    }

    try {
      await cameraController.initialize();
    } catch (e) {
      print('Error ${e.code} \nError message: ${e.description}');
    }

    if (mounted) {
      setState(() {});

      cameraController.startImageStream((CameraImage img) {
        if (!isDetecting) {
          isDetecting = true;
          //imglib.Image img = convertCameraImage(camImg);
          //_classifier.classify(img);
          print('PREDICTING...');
          Tflite.runModelOnFrame(
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
                  asynch: true // defaults to true
                  )
              .then((recognition) {
            print('RECOGNITION:');
            print(recognition);
          });
          isDetecting = false;
        }
      });
    }
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
    // TODO: implement initState
    super.initState();
    // Initialize classifier
    _classifier = Classifier();
    // Check whether camera is available
    availableCameras().then((value) {
      cameras = value;
      if (cameras.length > 0) {
        setState(() {
          selectedCameraIndex = 0;
        });
        initCamera(cameras[selectedCameraIndex]).then((value) {});
      } else {
        print('No camera available');
      }
    }).catchError((e) {
      print('Error : ${e.code}');
    });
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
}
