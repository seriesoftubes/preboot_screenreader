import 'dart:ffi';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

class Classifier {
  // name of the model file
  String _modelFile = 'assets/screen_classifier/screen_model.tflite';
  String _labelFile = 'assets/screen_classifier/labels.txt';

  Classifier() {
    // Load model when the classifier is initialized.
    _loadModel();
  }

  void _loadModel() {
    try {
      Tflite.loadModel(
          model: _modelFile,
          labels: _labelFile,
          numThreads: 1, // defaults to 1
          isAsset:
              true, // defaults to true, set to false to load resources outside assets
          useGpuDelegate:
              false // defaults to false, set to true to use GPU delegate
          );
    } catch (e) {
      print(e);
    }
  }

  Future<String> classify(CameraImage img) async {
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

      double probability = 1 / (1 + exp(-1 * recognition[0]["confidence"]));
      print('RECOGNITION: $recognition PROBABILITY: $probability');

      // Check if probability is at least 90%
      if (probability >= 0.9) {
        return recognition[0]["label"];
      } else {
        return "None";
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}
