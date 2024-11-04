import 'dart:math';

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:vector_math/vector_math.dart' show Vector2, degrees;
import '../models/sit_up_model.dart';

double calculateTorsoAngle(
  PoseLandmark shoulder,
  PoseLandmark hip,
  PoseLandmark knee,
) {
  // Calculate vectors
  final hipToShoulder = Vector2(
    shoulder.x - hip.x,
    shoulder.y - hip.y,
  );

  final hipToKnee = Vector2(
    knee.x - hip.x,
    knee.y - hip.y,
  );

  // Calculate angle between vectors
  double dot = hipToShoulder.dot(hipToKnee);
  double norm = hipToShoulder.length * hipToKnee.length;

  double angle = degrees(acos(dot / norm));

  // Adjust angle based on relative positions
  if (shoulder.y > hip.y) {
    angle = 360 - angle;
  }

  return angle;
}

SitUpState? isSitUp(double angle, SitUpState currentState) {
  const double upThreshold = 75.0; // Angle when torso is upright
  const double downThreshold = 30.0; // Angle when lying down

  switch (currentState) {
    case SitUpState.neutral:
      if (angle <= downThreshold) {
        return SitUpState.init;
      }
      break;
    case SitUpState.init:
      if (angle >= upThreshold) {
        return SitUpState.complete;
      }
      break;
    case SitUpState.complete:
      return SitUpState.neutral;
  }

  return null;
}
