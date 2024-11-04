import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:workout_ai/models/exercise_completion_model.dart';
import 'package:workout_ai/models/exercise_stats_model.dart';
import 'package:workout_ai/models/push_up_model.dart';
import 'package:workout_ai/models/sit_up_model.dart';
import 'package:workout_ai/painters/pose_painter.dart';
import 'package:workout_ai/services/pushup_service.dart';
import 'package:workout_ai/utils/sit_up_utils.dart';
import 'package:workout_ai/utils/utils.dart' as utils;
import 'package:workout_ai/widgets/workout_completion_dialog.dart';
import 'dart:developer' as developer;

class ExerciseStatsWidget extends StatelessWidget {
  final String exerciseType;
  final int reps;

  const ExerciseStatsWidget({
    super.key,
    required this.exerciseType,
    required this.reps,
  });

  Future<void> _submitWorkout(BuildContext context) async {
    if (exerciseType == 'Push-up Counter') {
      try {
        final pushupService = PushupService();

        // Test submission first
        await pushupService.testSubmitPushups();

        final result = await pushupService.submitPushups(
          pushUps: reps,
        );

        if (context.mounted) {
          context.read<ExerciseStatsModel>().updateStats(
                exerciseType: exerciseType,
                repCount: reps,
                caloriesPerRep: double.tryParse(
                    result['Kalori_yang_terbakar_per_push_up'] ?? '0'),
                totalCalories: double.tryParse(
                    result['Total_kalori_yang_terbakar'] ?? '0'),
              );

          context.read<ExerciseCompletion>().markExerciseComplete(exerciseType);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit workout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fitness_center, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Reps: $reps',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 120,
            child: ElevatedButton(
              onPressed: () => _submitWorkout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

class CameraView extends StatefulWidget {
  const CameraView({
    super.key,
    required this.customPaint,
    required this.onImage,
    required this.posePainter,
    this.onCameraFeedReady,
    this.onDetectorViewModeChanged,
    this.onCameraLensDirectionChanged,
    this.initialCameraLensDirection = CameraLensDirection.back,
    required this.exerciseTitle,
  });

  final CustomPaint? customPaint;
  final PosePainter? posePainter;
  final Function(InputImage inputImage) onImage;
  final VoidCallback? onCameraFeedReady;
  final VoidCallback? onDetectorViewModeChanged;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;
  final CameraLensDirection initialCameraLensDirection;
  final String exerciseTitle;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  static List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = -1;

  bool _changingCameraLens = false;

  Timer? _timer;
  int _seconds = 0;
  bool _isTimerRunning = false;

  PoseLandmark? p1;
  PoseLandmark? p2;
  PoseLandmark? p3;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == widget.initialCameraLensDirection) {
        _cameraIndex = i;
        break;
      }
    }
    if (_cameraIndex != -1) {
      _startLiveFeed();
    }
  }

  void _startTimer() {
    setState(() {
      _isTimerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void didUpdateWidget(covariant CameraView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.customPaint != oldWidget.customPaint) {
      if (widget.customPaint == null) return;
      if (!_isTimerRunning) {
        _startTimer();
      }

      if (widget.exerciseTitle == 'Push-up Counter') {
        _handlePushUpDetection();
      } else {
        _handleSitUpDetection();
      }
    }
  }

  void _handlePushUpDetection() {
    final bloc = BlocProvider.of<PushUpCounter>(context);
    for (final pose in widget.posePainter!.poses) {
      PoseLandmark getPoseLandmark(PoseLandmarkType type1) {
        final PoseLandmark joint1 = pose.landmarks[type1]!;
        return joint1;
      }

      p1 = getPoseLandmark(PoseLandmarkType.rightShoulder);
      p2 = getPoseLandmark(PoseLandmarkType.rightElbow);
      p3 = getPoseLandmark(PoseLandmarkType.rightWrist);
    }
    if (p1 != null && p2 != null && p3 != null) {
      final rtaAngle = utils.angle(p1!, p2!, p3!);
      final rta = utils.isPushUp(rtaAngle, bloc.state);
      developer.log("Angle: ${rtaAngle.toStringAsFixed(2)}");
      if (rta != null) {
        if (rta == PushUpState.init) {
          bloc.setPushUpState(rta);
        } else if (rta == PushUpState.complete) {
          bloc.incrementCounter();
          bloc.setPushUpState(PushUpState.neutral);
        }
      }
    }
  }

  void _handleSitUpDetection() {
    final bloc = BlocProvider.of<SitUpCounter>(context);
    for (final pose in widget.posePainter!.poses) {
      if (pose.landmarks.isEmpty) continue;

      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
      final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
      final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

      if (rightShoulder != null && rightHip != null && rightKnee != null) {
        final torsoAngle = calculateTorsoAngle(
          rightShoulder,
          rightHip,
          rightKnee,
        );

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

  @override
  void dispose() {
    _timer?.cancel();
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _liveFeedBody());
  }

  Widget _liveFeedBody() {
    if (_cameras.isEmpty) return Container();
    if (_controller == null) return Container();
    if (_controller?.value.isInitialized == false) return Container();

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          RepaintBoundary(
            child: Center(
              child: _changingCameraLens
                  ? const Center(
                      child: Text('Changing camera lens'),
                    )
                  : CameraPreview(
                      _controller!,
                      child: RepaintBoundary(child: widget.customPaint),
                    ),
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: RepaintBoundary(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fitness_center, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Reps: ${widget.exerciseTitle == 'Push-up Counter' ? context.select((PushUpCounter c) => c.counter) : context.select((SitUpCounter c) => c.counter)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 120,
                      child: ElevatedButton(
                        onPressed: () {
                          final count =
                              widget.exerciseTitle == 'Push-up Counter'
                                  ? context.read<PushUpCounter>().counter
                                  : context.read<SitUpCounter>().counter;

                          if (count == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Complete at least one repetition'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => Center(
                              child: WorkoutCompletionDialog(
                                exerciseType: widget.exerciseTitle,
                                reps: count,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isTimerRunning)
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatTime(_seconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          _backButton(),
          _switchLiveCameraToggle(),
          _detectionViewModeToggle(),
        ],
      ),
    );
  }

  Widget _backButton() => Positioned(
        top: 40,
        left: 8,
        child: SizedBox(
          height: 50.0,
          width: 50.0,
          child: FloatingActionButton(
            heroTag: Object(),
            onPressed: () {
              if (widget.exerciseTitle == 'Push-up Counter') {
                context.read<PushUpCounter>().resetCounter();
              } else {
                context.read<SitUpCounter>().resetCounter();
              }
              Navigator.of(context).pop();
            },
            backgroundColor: Colors.black54,
            child: const Icon(
              Icons.arrow_back_ios_outlined,
              size: 20,
            ),
          ),
        ),
      );

  Widget _detectionViewModeToggle() => Positioned(
        bottom: 8,
        left: 8,
        child: SizedBox(
          height: 50.0,
          width: 50.0,
          child: FloatingActionButton(
            heroTag: Object(),
            onPressed: widget.onDetectorViewModeChanged,
            backgroundColor: Colors.black54,
            child: const Icon(
              Icons.photo_library_outlined,
              size: 25,
            ),
          ),
        ),
      );

  Widget _switchLiveCameraToggle() => Positioned(
        bottom: 8,
        right: 8,
        child: SizedBox(
          height: 50.0,
          width: 50.0,
          child: FloatingActionButton(
            heroTag: Object(),
            onPressed: _switchLiveCamera,
            backgroundColor: Colors.black54,
            child: Icon(
              Platform.isIOS
                  ? Icons.flip_camera_ios_outlined
                  : Icons.flip_camera_android_outlined,
              size: 25,
            ),
          ),
        ),
      );

  Future<void> _startLiveFeed() async {
    final camera = _cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;

      await _controller!.startImageStream(_processCameraImage);

      if (widget.onCameraFeedReady != null) {
        widget.onCameraFeedReady!();
      }
      if (widget.onCameraLensDirectionChanged != null) {
        widget.onCameraLensDirectionChanged!(camera.lensDirection);
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error starting camera feed: $e');
    }
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  Future _switchLiveCamera() async {
    setState(() => _changingCameraLens = true);
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;

    await _stopLiveFeed();
    await _startLiveFeed();
    setState(() => _changingCameraLens = false);
  }

  void _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    widget.onImage(inputImage);
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }
}
