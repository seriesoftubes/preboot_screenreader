import 'dart:ffi';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class NativeOpencv {
  static const MethodChannel _channel = const MethodChannel('native_opencv');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  // Getting a library that holds needed symbols
  final DynamicLibrary nativeAddLib = Platform.isAndroid
      ? DynamicLibrary.open('libnative_opencv.so')
      : DynamicLibrary.process();

  // Looking for the functions
  final List<List<double>> Function(Image img) detect_squares =
      nativeAddLib.lookup <
          NativeFunction<List<List<double>> Function(Image)>('detect_squares')
              .asFunction();
}
