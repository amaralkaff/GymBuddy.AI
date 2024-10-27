// lib/utils/sit_up_utils.dart

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/sit_up_model.dart';

double calculateTorsoAngle(
  PoseLandmark shoulder,
  PoseLandmark hip,
  PoseLandmark knee,
) {
  try {
    final radians = math.atan2(
      knee.y - hip.y,
      knee.x - hip.x,
    ) -
    math.atan2(
      shoulder.y - hip.y,
      shoulder.x - hip.x,
    );
    
    double degrees = radians * 180.0 / math.pi;
    degrees = degrees.abs();
    if (degrees > 180.0) {
      degrees = 360.0 - degrees;
    }
    return degrees;
  } catch (e) {
    print('Error calculating torso angle: $e');
    return 0.0;
  }
}

SitUpState? isSitUp(double torsoAngle, SitUpState current) {
  // More lenient angle thresholds
  const minLyingAngle = 140.0;    // Nearly flat
  const maxRaisedAngle = 80.0;    // Upper body raised
  
  try {
    if (current == SitUpState.neutral && torsoAngle > minLyingAngle) {
      return SitUpState.init;       // Person is lying down
    } else if (current == SitUpState.init && torsoAngle < maxRaisedAngle) {
      return SitUpState.complete;   // Person has lifted up
    }
    return null;
  } catch (e) {
    print('Error determining sit-up state: $e');
    return null;
  }
}