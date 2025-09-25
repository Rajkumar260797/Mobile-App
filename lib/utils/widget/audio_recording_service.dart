import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AudioRecordingService {
  static final AudioRecordingService _instance = AudioRecordingService._internal();
  factory AudioRecordingService() => _instance;
  AudioRecordingService._internal();

  final String recorderId = 'default';
  final record = RecordPlatform.instance;

  bool isRecording = false;
  bool isPaused = false;
  String? lastRecordingPath;
  final List<String> _recordingPaths = [];
  final TimerService timerService = TimerService();

  /// Start recording with a unique filename
  Future<void> startRecording() async {
    await record.create(recorderId);
    const config = RecordConfig(encoder: AudioEncoder.aacLc);

    final dir = await getExternalStorageDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir!.path}/recording_$timestamp.m4a';

    await record.start(recorderId, config, path: path);

    isRecording = true;
    isPaused = false;
    lastRecordingPath = path;
    _recordingPaths.add(path);

    timerService.startTimer();
    const platform = MethodChannel('com.example.audioapp/record');
    if (Platform.isAndroid) {
      await platform.invokeMethod('startService');
    }
  }

  /// Pause current recording
  Future<void> pauseRecording() async {
    await record.pause(recorderId);
    isPaused = true;
    print("🔴 Recording paused");
    timerService.pauseTimer();
  }

  Future<void> resumeRecording() async {
    await record.resume(recorderId);
    isPaused = false;
    print("🟢 Recording resumed");

    // Pass the current paused duration to the TimerService so that it resumes from that point
    timerService.resumeTimer();
  }


  /// Stop and dispose the recorder
  Future<void> stopRecording() async {
    await record.stop(recorderId);
    await record.dispose(recorderId);
    isRecording = false;
    isPaused = false;

    const platform = MethodChannel('com.example.audioapp/record');
    if (Platform.isAndroid) {
      await platform.invokeMethod('stopService');
    }
    timerService.stopTimer();
  }

  /// Get all saved recording file paths
  List<String> getAllRecordingPaths() => _recordingPaths;

  /// Clear all saved paths (after upload)
  void resetRecordings() {
    lastRecordingPath = null;
    isRecording = false;
    isPaused = false;
    _recordingPaths.clear();
  }

  bool get isRecordingActive => isRecording && !isPaused;
}



class TimerService {
  final _timerController = StreamController<Duration>.broadcast();
  Timer? _timer;
  Duration _currentDuration = Duration.zero;
  Duration _pausedDuration = Duration.zero;

  // Stream to listen to the timer updates
  Stream<Duration> get timerStream => _timerController.stream;

  // Start the timer
  void startTimer() {
    _pausedDuration = Duration.zero; // Reset paused duration when starting a new timer
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _currentDuration = Duration(seconds: timer.tick) + _pausedDuration;
      _timerController.add(_currentDuration);
    });
  }

  // Resume the timer from the paused duration
  void resumeTimer() {
    _timer?.cancel(); // Ensure any existing timer is stopped
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _currentDuration = Duration(seconds: timer.tick) + _pausedDuration;
      _timerController.add(_currentDuration);
    });
  }

  // Pause the timer and store the current duration
  void pauseTimer() {
    _timer?.cancel();
    _pausedDuration = _currentDuration;  // Save the current timer duration
  }

  // Stop the timer
  void stopTimer() {
    _timer?.cancel();
    _currentDuration = Duration.zero;
    _pausedDuration = Duration.zero;  // Reset both when stopping
    _timerController.add(_currentDuration);  // Reset timer on stop
  }

  // Dispose of the StreamController when done
  void dispose() {
    _timer?.cancel();
    _timerController.close();
  }
}