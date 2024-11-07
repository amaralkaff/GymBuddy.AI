import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/push_up_model.dart';

Future<String> getAssetPath(String asset) async {
  final path = await getLocalPath(asset);
  await Directory(dirname(path)).create(recursive: true);
  final file = File(path);
  if (!await file.exists()) {
    final byteData = await rootBundle.load(asset);
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  }
  return file.path;
}

Future<String> getLocalPath(String path) async {
  return '${(await getApplicationSupportDirectory()).path}/$path';
}

double angle(
      PoseLandmark firstLandmark,
      PoseLandmark midLandmark,
      PoseLandmark lastLandmark
  ) {
      final radians =
          math.atan2(lastLandmark.y - midLandmark.y,
                    lastLandmark.x - midLandmark.x) -
            math.atan2(firstLandmark.y - midLandmark.y,
                    firstLandmark.x - midLandmark.x);
      double degrees = radians * 180.0 / math.pi;
      degrees = degrees.abs(); // Angle should never be negative
      if (degrees > 180.0) {
          degrees = 360.0 - degrees; // Always get the acute representation of the angle
      }
      return degrees;
  }

PushUpState? isPushUp(double angleElbow, PushUpState current) {
  const umbralElbow = 60.0;
  const umbralELbowExt = 160.0;
  if (current == PushUpState.neutral && angleElbow > umbralELbowExt && angleElbow < 180.0) {
    return PushUpState.init;
  } else if (current == PushUpState.init && angleElbow < umbralElbow && angleElbow > 40.0)
    return PushUpState.complete;
  return null;
}
