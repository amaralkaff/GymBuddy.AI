# Workout AI App Analysis

## Project Overview
This is a Flutter application that uses machine learning (specifically Google's ML Kit) to detect and count exercises (push-ups and sit-ups) through the device's camera. The app features real-time pose detection, exercise counting, and a timer functionality.

## Key Components

### 1. Main Architecture
- Uses Flutter Bloc for state management
- Implements ML Kit for pose detection
- Features a camera-based UI with real-time feedback
- Supports both portrait and landscape orientations

### 2. Core Features
- Push-up detection and counting
- Sit-up detection and counting
- Real-time pose visualization
- Exercise timer
- Camera controls (zoom, exposure, lens switching)
- Gallery support for image analysis

### 3. Key Files Structure

#### Views
- `splash_screen.dart`: Main entry point showing available workouts
- `detector_view.dart`: Base view for pose detection
- `camera_view.dart`: Camera handling and UI
- `pose_detection_view.dart`: Push-up specific detection
- `sit_up_detector_view.dart`: Sit-up specific detection

#### Models
- `push_up_model.dart`: State management for push-ups
- `sit_up_model.dart`: State management for sit-ups

#### Utils
- `utils.dart`: General utilities and angle calculations
- `sit_up_utils.dart`: Sit-up specific calculations
- `coordinates_translator.dart`: Camera coordinate translation

#### Painters
- `pose_painter.dart`: Visualization of detected poses

## Technical Implementation Details

### 1. Exercise Detection Logic
- Uses angle calculations between body landmarks
- Push-ups: Monitors elbow angle
- Sit-ups: Tracks torso angle relative to legs
- States: neutral → init → complete

### 2. ML Kit Integration
- Uses PoseDetector for real-time pose detection
- Processes camera feed frame by frame
- Extracts landmarks for key body points
- Translates coordinates for proper visualization

### 3. State Management
- Uses BLoC pattern with two main states:
  - PushUpCounter: Manages push-up states and count
  - SitUpCounter: Manages sit-up states and count

### 4. UI Components
- Splash screen with workout cards
- Real-time pose visualization
- Counter display
- Timer with controls
- Camera controls (zoom, exposure, flip)

## Key Features Implementation

### Exercise Detection Process
1. Camera feed is processed frame by frame
2. ML Kit detects pose landmarks
3. Utils calculate angles between relevant points
4. State machine determines exercise state
5. Counter updates based on completed repetitions

### Camera Handling
- Supports both front and back cameras
- Handles different device orientations
- Provides zoom and exposure controls
- Includes gallery integration for static images

### User Interface
- Clean, modern design with cards
- Real-time feedback with pose overlay
- Exercise counter and timer
- Intuitive navigation and controls

## Performance Considerations
- Uses ResolutionPreset.high for optimal performance
- Implements busy flags to prevent frame processing overlap
- Handles device orientation changes efficiently
- Manages camera resources properly

## Security and Permissions
- Requires camera permissions
- All processing done on-device
- No data storage or external transmission

## Extensibility
The architecture allows for easy addition of:
- New exercise types
- Additional pose detection features
- Enhanced analytics
- Different UI themes or layouts