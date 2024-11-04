// lib/views/sit_up_detector_view.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../painters/pose_painter.dart';
import '../models/sit_up_model.dart';
import '../models/exercise_timer_model.dart';
import '../utils/sit_up_utils.dart';
import '../widgets/situp_completion_dialog.dart';
import 'detector_view.dart';

class SitUpDetectorView extends StatefulWidget {
  static const String title = 'Sit-up Counter';

  const SitUpDetectorView({super.key});

  @override
  State<SitUpDetectorView> createState() => _SitUpDetectorViewState();
}

class _SitUpDetectorViewState extends State<SitUpDetectorView> {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
    ),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  PosePainter? _posePainter;
  var _cameraLensDirection = CameraLensDirection.back;

  @override
  void dispose() {
    _canProcess = false;
    _poseDetector.close();
    super.dispose();
  }

  void _showCompletionDialog(BuildContext context, int reps) {
    if (reps == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete at least one sit-up'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: SitUpCompletionDialog(
          exerciseType: 'Sit-up',
          reps: reps,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExerciseTimerCubit(context, SitUpDetectorView.title),
      child: BlocListener<ExerciseTimerCubit, ExerciseTimerState>(
        listener: (context, state) {
          if (state.status == TimerStatus.completed) {
            final reps = context.read<SitUpCounter>().counter;
            _showCompletionDialog(context, reps);
          }
        },
        child: DetectorView(
          title: SitUpDetectorView.title,
          customPaint: _customPaint,
          text: _text,
          onImage: _processImage,
          posePainter: _posePainter,
          initialCameraLensDirection: _cameraLensDirection,
          onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
          exerciseTitle: SitUpDetectorView
              .title, // Using the existing exerciseTitle parameter
        ),
      ),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess || _isBusy) return;

    _isBusy = true;
    setState(() => _text = '');

    try {
      final poses = await _poseDetector.processImage(inputImage);

      if (inputImage.metadata?.size != null &&
          inputImage.metadata?.rotation != null) {
        final painter = PosePainter(
          poses,
          inputImage.metadata!.size,
          inputImage.metadata!.rotation,
          _cameraLensDirection,
        );

        if (poses.isNotEmpty) {
          final pose = poses.first;
          final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
          final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
          final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

          // Additional landmarks for better accuracy
          final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
          final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
          final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];

          if (rightShoulder != null &&
              rightHip != null &&
              rightKnee != null &&
              leftShoulder != null &&
              leftHip != null &&
              leftKnee != null) {
            // Calculate average angles from both sides for better accuracy
            final rightTorsoAngle = calculateTorsoAngle(
              rightShoulder,
              rightHip,
              rightKnee,
            );

            final leftTorsoAngle = calculateTorsoAngle(
              leftShoulder,
              leftHip,
              leftKnee,
            );

            final averageAngle = (rightTorsoAngle + leftTorsoAngle) / 2;

            if (mounted) {
              final bloc = context.read<SitUpCounter>();
              final sitUpState = isSitUp(averageAngle, bloc.state);

              if (sitUpState != null) {
                if (sitUpState == SitUpState.init) {
                  bloc.setSitUpState(sitUpState);
                } else if (sitUpState == SitUpState.complete) {
                  bloc.incrementCounter();
                  bloc.setSitUpState(SitUpState.neutral);

                  // Provide haptic feedback for completed rep
                  HapticFeedback.mediumImpact();
                }
              }
            }
          }
        }

        if (mounted) {
          setState(() {
            _customPaint = CustomPaint(painter: painter);
            _posePainter = painter;
          });
        }
      }
    } catch (e) {
      debugPrint('Error in pose detection: $e');
      if (mounted) {
        setState(() => _text = 'Error processing image');
      }
    } finally {
      _isBusy = false;
      if (mounted) {
        setState(() {});
      }
    }
  }
}
