import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'sensor_web_stub.dart'
    if (dart.library.html) 'sensor_web.dart' as sensor_platform;

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  StreamSubscription? _accelSub;
  final StreamController<double> _leanAngleController = StreamController<double>.broadcast();
  final StreamController<double> _gForceController = StreamController<double>.broadcast();

  Stream<double> get leanAngleStream => _leanAngleController.stream;
  Stream<double> get gForceStream => _gForceController.stream;

  double _currentAngle = 0.0;
  bool _isListening = false;

  Future<bool> requestPermissionAndStart() async {
    if (kIsWeb) {
      await sensor_platform.requestWebPermission();
      sensor_platform.initWebSensors(
        onAngle: (angle) {
          _currentAngle = angle;
          _leanAngleController.add(angle);
        },
        onGForce: (g) {
          _gForceController.add(g);
        },
      );
    }

    if (_isListening) return true;
    _isListening = true;

    try {
      _accelSub = accelerometerEventStream().listen((AccelerometerEvent event) {
        final double rawAngle = -math.atan2(event.x, math.sqrt(event.y * event.y + event.z * event.z)) * (180 / math.pi);
        final double smoothed = (_currentAngle * 0.7) + (rawAngle * 0.3);
        final double totalAccel = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        final double g = (totalAccel / 9.80665).clamp(0.0, 3.5);

        _currentAngle = smoothed;
        _leanAngleController.add(smoothed);
        _gForceController.add(g);
      });
    } catch (_) {}

    return true;
  }

  void stop() {
    _accelSub?.cancel();
    _isListening = false;
  }
}
