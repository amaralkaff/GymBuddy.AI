// lib/views/pose_detection_view.dart

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../painters/pose_painter.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'detector_view.dart';

class PoseDetectorView extends StatefulWidget {
  static const String exerciseTitle = 'Push-up Counter';
  
  const PoseDetectorView({super.key});

  @override
  State<StatefulWidget> createState() => _PoseDetectorViewState();
}

class _PoseDetectorViewState extends State<PoseDetectorView> {
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
    return DetectorView(
      title: PoseDetectorView.exerciseTitle,
      customPaint: _customPaint,
      text: _text,
      onImage: _processImage,
      posePainter: _posePainter,
      initialCameraLensDirection: _cameraLensDirection,
      onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
      exerciseTitle: PoseDetectorView.exerciseTitle,
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess || _isBusy) return;
    _isBusy = true;

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
        
        _customPaint = CustomPaint(painter: painter);
        _posePainter = painter;
      }
    } catch (e) {
      debugPrint('Error detecting pose: $e');
    } finally {
      _isBusy = false;
      if (mounted) setState(() {});
    }
  }
}