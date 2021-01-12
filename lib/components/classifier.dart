import 'dart:math';

import 'package:tflite/tflite.dart';

class Classifier {
  // name of the model file
  String _modelFile = 'assets/screen_classifier/screen_model.tflite';
  String _labelFile = 'assets/screen_classifier/labels.txt';

  Classifier() {
    // Load model when the classifier is initialized.
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
}
