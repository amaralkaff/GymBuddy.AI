import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:test_1/models/exercise_completion_model.dart';
import 'package:test_1/models/push_up_model.dart';
import 'package:test_1/models/sit_up_model.dart';
import 'package:test_1/painters/pose_painter.dart';
import 'package:test_1/utils/utils.dart' as utils;
import '../widgets/exercise_stats_widget.dart';

class ExerciseStatsWidget extends StatelessWidget {
  final String exerciseType;
  final int reps;
  static const int maxTime = 30; // 30 seconds workout

  const ExerciseStatsWidget({
    Key? key,
    required this.exerciseType,
    required this.reps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            exerciseType,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<int>(
            stream: Stream.periodic(
              const Duration(seconds: 1),
              (x) => maxTime - x - 1,
            ).take(maxTime),
            builder: (context, snapshot) {
              final timeLeft = snapshot.data ?? maxTime;
              
              // Handle exercise completion
              if (timeLeft <= 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _handleExerciseCompletion(context);
                });
              }

              return Text(
                '${(timeLeft ~/ 60).toString().padLeft(2, '0')}:${(timeLeft % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Reps: $reps',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _handleExerciseCompletion(BuildContext context) {
    // Mark exercise as completed
    context.read<ExerciseCompletion>().markExerciseComplete(exerciseType);
    
    // Reset appropriate counter
    if (exerciseType == 'Push-up Counter') {
      context.read<PushUpCounter>().resetCounter();
    } else if (exerciseType == 'Sit-up Counter') {
      context.read<SitUpCounter>().resetCounter();
    }

    // Navigate back to splash screen
    Navigator.of(context).popUntil((route) => route.isFirst);
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
    required this.exerciseTitle, // Add this parameter
  });

  final CustomPaint? customPaint;
  final PosePainter? posePainter;
  final Function(InputImage inputImage) onImage;
  final VoidCallback? onCameraFeedReady;
  final VoidCallback? onDetectorViewModeChanged;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;
  final CameraLensDirection initialCameraLensDirection;
  final String exerciseTitle; // Add this parameter

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  static List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = -1;
  double _currentZoomLevel = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;
  bool _changingCameraLens = false;

  // Timer variables
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

  // Timer functions
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

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _seconds = 0;
      _isTimerRunning = false;
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
        _startTimer(); // Start timer when pose detection begins
      }
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
        print("Angle: ${rtaAngle.toStringAsFixed(2)}");
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
          left: 0,
          right: 0,
          child: RepaintBoundary(
            child: ExerciseStatsWidget(
              exerciseType: widget.exerciseTitle,
              reps: widget.exerciseTitle == 'Push-up Counter'
                  ? context.select((PushUpCounter c) => c.counter)
                  : context.select((SitUpCounter c) => c.counter),
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

  Widget _timerWidget() {
    return Positioned(
      top: 50,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            const Text(
              'Time',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _formatTime(_seconds),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _isTimerRunning ? _pauseTimer : _startTimer,
                  child: Icon(
                    _isTimerRunning ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _resetTimer,
                  child: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterWidget() {
    final bloc = BlocProvider.of<PushUpCounter>(context);
    return Positioned(
      left: 0,
      top: 50,
      right: 0,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            const Text(
              "Counter",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Container(
              width: 70,
              decoration: BoxDecoration(
                color: Colors.black54,
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 4.0,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Text(
                "${bloc.counter}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 30.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... rest of the existing code remains the same ...

  @override
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

  Widget _zoomControl() => Positioned(
        bottom: 16,
        left: 0,
        right: 0,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 250,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Slider(
                    value: _currentZoomLevel,
                    min: _minAvailableZoom,
                    max: _maxAvailableZoom,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white30,
                    onChanged: (value) async {
                      setState(() {
                        _currentZoomLevel = value;
                      });
                      await _controller?.setZoomLevel(value);
                    },
                  ),
                ),
                Container(
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        '${_currentZoomLevel.toStringAsFixed(1)}x',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _exposureControl() => Positioned(
        top: 40,
        right: 8,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 250,
          ),
          child: Column(children: [
            Container(
              width: 55,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    '${_currentExposureOffset.toStringAsFixed(1)}x',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: SizedBox(
                  height: 30,
                  child: Slider(
                    value: _currentExposureOffset,
                    min: _minAvailableExposureOffset,
                    max: _maxAvailableExposureOffset,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white30,
                    onChanged: (value) async {
                      setState(() {
                        _currentExposureOffset = value;
                      });
                      await _controller?.setExposureOffset(value);
                    },
                  ),
                ),
              ),
            )
          ]),
        ),
      );

  Future<void> _startLiveFeed() async {
  final camera = _cameras[_cameraIndex];
  _controller = CameraController(
    camera,
    ResolutionPreset.medium, // Changed from high to medium for better performance
    enableAudio: false,
    imageFormatGroup: Platform.isAndroid
        ? ImageFormatGroup.nv21
        : ImageFormatGroup.bgra8888,
  );

  try {
    await _controller!.initialize();
    if (!mounted) return;

    _currentZoomLevel = await _controller!.getMinZoomLevel();
    _minAvailableZoom = _currentZoomLevel;
    _maxAvailableZoom = await _controller!.getMaxZoomLevel();
    
    _currentExposureOffset = 0.0;
    _minAvailableExposureOffset = await _controller!.getMinExposureOffset();
    _maxAvailableExposureOffset = await _controller!.getMaxExposureOffset();

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

    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/google_mlkit_commons/android/src/main/java/com/google_mlkit_commons/InputImageConverter.java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/google_mlkit_commons/ios/Classes/MLKVisionImage%2BFlutterPlugin.m
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/example/lib/vision_detector_views/painters/coordinates_translator.dart
    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    // print(
    //     'lensDirection: ${camera.lensDirection}, sensorOrientation: $sensorOrientation, ${_controller?.value.deviceOrientation} ${_controller?.value.lockedCaptureOrientation} ${_controller?.value.isCaptureOrientationLocked}');
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      // print('rotationCompensation: $rotationCompensation');
    }
    if (rotation == null) return null;
    // print('final rotation: $rotation');

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }
}