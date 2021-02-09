import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:camera/camera.dart';

// C function signatures
typedef _version_func = ffi.Pointer<Utf8> Function();
typedef _detect_squares_func = ffi.Void Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

// Dart function signatures
typedef _VersionFunc = ffi.Pointer<Utf8> Function();
typedef _DetectSquaresFunc = void Function(
    ffi.cv::Mat, ffi.Pointer<Utf8>);

// Getting a library that holds needed symbols
ffi.DynamicLibrary _lib = Platform.isAndroid
    ? ffi.DynamicLibrary.open('libnative_opencv.so')
    : ffi.DynamicLibrary.process();

// Looking for the functions
final _VersionFunc _version =
    _lib.lookup<ffi.NativeFunction<_version_func>>('version').asFunction();
final _DetectSquaresFunc _detectSquares = _lib
    .lookup<ffi.NativeFunction<_detect_squares_func>>('detect_squares')
    .asFunction();

String opencvVersion() {
  return Utf8.fromUtf8(_version());
}

void detectSquares(DetectSquaresArguments args) {
  _detectSquares(Utf8.toUtf8(args.inputPath), Utf8.toUtf8(args.outputPath));
}

class DetectSquaresArguments {
  final CameraImage img;

  DetectSquaresArguments(this.img);
}
