// lib/views/sit_up_detector_view.dart

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../painters/pose_painter.dart';
import '../models/sit_up_model.dart';
import '../models/exercise_timer_model.dart';
import '../utils/sit_up_utils.dart';
import 'detector_view.dart';

class SitUpDetectorView extends StatefulWidget {
  static const String title = 'Sit-up Counter'; // Add this constant
  
  const SitUpDetectorView({super.key});

  @override
  State<SitUpDetectorView> createState() => _SitUpDetectorViewState();
}

class _SitUpDetectorViewState extends State<SitUpDetectorView> {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(),
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExerciseTimerCubit(context, SitUpDetectorView.title),
      child: BlocListener<ExerciseTimerCubit, ExerciseTimerState>(
        listener: (context, state) {
          if (state.status == TimerStatus.completed) {
            Navigator.of(context).popUntil((route) => route.isFirst);
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
        ),
      ),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    
    _isBusy = true;
    setState(() {
      _text = '';
    });

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

        // Only process if we have valid poses
        if (poses.isNotEmpty) {
          final pose = poses.first;
          final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
          final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
          final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

          if (rightShoulder != null && rightHip != null && rightKnee != null) {
            final torsoAngle = calculateTorsoAngle(
              rightShoulder,
              rightHip,
              rightKnee,
            );

            if (mounted) {
              final bloc = context.read<SitUpCounter>();
              final sitUpState = isSitUp(torsoAngle, bloc.state);

              if (sitUpState != null) {
                if (sitUpState == SitUpState.init) {
                  bloc.setSitUpState(sitUpState);
                } else if (sitUpState == SitUpState.complete) {
                  bloc.incrementCounter();
                  bloc.setSitUpState(SitUpState.neutral);
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
      // Handle errors gracefully
      debugPrint('Error in pose detection: $e');
      if (mounted) {
        setState(() {
          _text = 'Error processing image';
        });
      }
    } finally {
      _isBusy = false;
      if (mounted) {
        setState(() {});
      }
    }
  }
}