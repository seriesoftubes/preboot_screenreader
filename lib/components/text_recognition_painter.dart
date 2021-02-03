import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';

// Paints rectangles around all the text in the image.
class TextRecognitionPainter extends CustomPainter {
  TextRecognitionPainter(this.absoluteImageSize, this.visionText);

  final Size absoluteImageSize;
  final VisionText visionText;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    Rect scaleRect(TextContainer container) {
      return Rect.fromLTRB(
        // The bottom of the bounding box on the image is the left on potrait screen
        size.width - container.boundingBox.bottom * scaleX,
        // The left of the bounding box on the image is the top on potrait screen
        container.boundingBox.left * scaleY,
        // The top of the bounding box on the image is the right on potrait screen
        size.width - container.boundingBox.top * scaleX,
        // The right of the bounding box on the image is the bottom on potrait screen
        container.boundingBox.right * scaleY,
      );
    }

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (TextBlock block in visionText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement element in line.elements) {
          paint.color = Colors.green;
          canvas.drawRect(scaleRect(element), paint);
        }

        paint.color = Colors.yellow;
        canvas.drawRect(scaleRect(line), paint);
      }

      paint.color = Colors.red;
      canvas.drawRect(scaleRect(block), paint);
    }
  }

  @override
  bool shouldRepaint(TextRecognitionPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.visionText != visionText;
  }
}
