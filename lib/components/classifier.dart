import 'dart:math';

import 'package:image/image.dart' as image_lib;

// Import tflite_flutter
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class Classifier {
  // name of the model file
  final _modelFile = 'screen_classifier/screen_model.tflite';

  // TensorFlow Lite Interpreter object
  Interpreter _interpreter;

  // Labels
  List<String> _labels;

  // ImageProcessor
  ImageProcessor imageProcessor;

  // OutputShapes
  List<List<int>> _outputShapes;

  // OutputTypes
  List<TfLiteType> _outputTypes;

  // Number of results
  static const int numResults = 2;

  Classifier() {
    // Load model when the classifier is initialized.
    _loadModel();
    _loadLabel();
  }

  Future<void> _loadModel() async {
    try {
      // Creating the interpreter using Interpreter.fromAsset
      _interpreter = await Interpreter.fromAsset(_modelFile);
      print('Interpreter loaded successfully');
      _interpreter.allocateTensors();
      final outputTensors = _interpreter.getOutputTensors();
      print(outputTensors);
      _outputShapes = [];
      _outputTypes = [];
      for (final tensor in outputTensors) {
        _outputShapes.add(tensor.shape);
        _outputTypes.add(tensor.type);
      }
      print(_outputShapes);
    } catch (e) {
      print('Error loading model: ' + e.toString());
    }
  }

  Future<void> _loadLabel() async {
    _labels = ['BIOS_SCREEN', 'BOOT_SCREEN'];
    print('Labels loaded successfully');
  }

  void classify(image_lib.Image img) {
    // Initialization code
    // Create an ImageProcessor with all ops required. For more ops, please
    // refer to the ImageProcessor Ops section in this README.
    print('Classifying...');
    imageProcessor = ImageProcessorBuilder()
        .add(ResizeOp(180, 180, ResizeMethod.NEAREST_NEIGHBOUR))
        .build();

    // Create a TensorImage object from an Image
    TensorImage tensorImage = TensorImage.fromImage(img);

    // Preprocess the image.
    // The image for image will be resized to (180, 180)
    tensorImage = imageProcessor.process(tensorImage);

    print('aaaaaaaaaaaaaaaaa');
    // TensorBuffers for output tensors
    final outputLocations = TensorBufferFloat(_outputShapes[0]);
    final outputClasses = TensorBufferFloat(_outputShapes[1]);
    print(outputClasses);
    final outputScores = TensorBufferFloat(_outputShapes[2]);
    print(outputScores);
    final numLocations = TensorBufferFloat(_outputShapes[3]);

    print('bbbbb');
    // runForMultipleInputs inputs and outputs
    final inputs = [tensorImage.buffer];
    final outputs = {
      0: outputLocations.buffer,
      1: outputClasses.buffer,
      2: outputScores.buffer,
      3: numLocations.buffer,
    };

    print('Running Interpreter');
    // Run Interpreter
    _interpreter.runForMultipleInputs(inputs, outputs);

    print('Interpreter run');

    final resultCount = min(numResults, numLocations.getIntValue(0));

    const labelOffset = 1;

    for (var i = 0; i < resultCount; i++) {
      final score = outputScores.getDoubleValue(i);
      final labelIndex = outputClasses.getIntValue(i) + labelOffset;
      final label = _labels.elementAt(labelIndex);
      print(score);
      print(label);
      print('aaaa');
    }

    /*TensorLabel tensorLabel = TensorLabel.fromList(
        labels, probabilityProcessor.process(probabilityBuffer));

    Map<String, double> doubleMap = tensorLabel.getMapWithFloatValue();*/
  }
}
