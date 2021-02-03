import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

class TextRecognition {
  TextRecognizer textRecognizer;
  FirebaseVisionImage visionImage;
  VisionText visionText;

  TextRecognition() {
    textRecognizer = FirebaseVision.instance.textRecognizer();
  }

  Future<VisionText> recognizeText(CameraImage img) async {
    visionImage = FirebaseVisionImage.fromBytes(
        img.planes[0].bytes,
        FirebaseVisionImageMetadata(
          rawFormat: img.format.raw,
          size: Size(img.width.toDouble(), img.height.toDouble()),
          planeData: img.planes.map((plane) {
            return FirebaseVisionImagePlaneMetadata(
              bytesPerRow: plane.bytesPerRow,
              width: plane.width,
              height: plane.height,
            );
          }).toList(),
        ));
    visionText = await textRecognizer.processImage(visionImage);
    return visionText;
  }

  Future close() async {
    await textRecognizer.close();
  }
}
