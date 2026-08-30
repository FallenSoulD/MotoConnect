import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../models/user_model.dart';
import '../../models/sos_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/neumorphic_widgets.dart';

class RideRecordingScreen extends StatefulWidget {
  final MotoUser user;
  const RideRecordingScreen({super.key, required this.user});

  @override
  State<RideRecordingScreen> createState() => _RideRecordingScreenState();
}

class _RideRecordingScreenState extends State<RideRecordingScreen> {
  StreamSubscription<Position>? _gpsSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<UserAccelerometerEvent>? _userAccelSub;

  bool _isRecording = true;
  DateTime? _startTime;
  Timer? _timer;
  Duration _duration = Duration.zero;

  // GPS Data
  Position? _lastPosition;
  double _distanceKm = 0.0;
  double _currentSpeedKmh = 0.0;
  double _maxSpeedKmh = 0.0;

  // Lean Angle
  double _currentLeanAngle = 0.0;
  double _maxLeanAngle = 0.0;

  // Crash Detection
  bool _crashWarningActive = false;
  int _crashCountdown = 15;
  Timer? _crashTimer;
  bool _highGForceDetected = false;
  DateTime? _highGForceTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _startTimer();
    _startTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _crashTimer?.cancel();
    _gpsSub?.cancel();
    _accelSub?.cancel();
    _userAccelSub?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRecording) return;
      setState(() {
        _duration = DateTime.now().difference(_startTime!);
      });
      _evaluateCrashCondition();
    });
  }

  void _startTracking() async {
    // GPS
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 2),
    ).listen((Position position) {
      if (!_isRecording) return;
      final speed = (position.speed * 3.6).clamp(0.0, 300.0);
      
      if (_lastPosition != null) {
        final dist = Geolocator.distanceBetween(
          _lastPosition!.latitude, _lastPosition!.longitude,
          position.latitude, position.longitude,
        );
        _distanceKm += (dist / 1000.0);
      }
      _lastPosition = position;
      
      if (speed > _maxSpeedKmh) _maxSpeedKmh = speed;
      
      setState(() {
        _currentSpeedKmh = speed;
      });
    });

    // Accelerometer (For Lean Angle - includes gravity)
    _accelSub = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (!_isRecording) return;
      // Basit yatış açısı hesaplaması (X-Y ekseni üzerinden roll)
      double angle = atan2(event.x, sqrt(event.y * event.y + event.z * event.z)) * 180 / pi;
      double absAngle = angle.abs();
      if (absAngle > _maxLeanAngle && absAngle < 70) {
        // 70 dereceden fazlası genelde telefonun düşmesi vs olabilir
        _maxLeanAngle = absAngle;
      }
      setState(() {
        _currentLeanAngle = absAngle;
      });
    });

    // User Accelerometer (For Crash Detection - without gravity)
    _userAccelSub = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      if (!_isRecording || _crashWarningActive) return;
      
      // Toplam ivme vektörü (G-Force)
      double gForce = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (gForce > 40.0) { // ~4G'den yüksek ani şok
        _highGForceDetected = true;
        _highGForceTime = DateTime.now();
      }
    });
  }

  void _evaluateCrashCondition() {
    if (_crashWarningActive) return;
    if (_highGForceDetected && _highGForceTime != null) {
      final timeSinceGForce = DateTime.now().difference(_highGForceTime!);
      if (timeSinceGForce.inSeconds > 3) {
        // Şoktan 3 saniye sonra hız 5 km/h altındaysa KAZA varsayımı
        if (_currentSpeedKmh < 5.0) {
          _triggerCrashWarning();
        } else {
          // Yanlış alarm, devam et
          _highGForceDetected = false;
        }
      }
    }
  }

  void _triggerCrashWarning() {
    setState(() {
      _crashWarningActive = true;
      _crashCountdown = 15;
    });

    _crashTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_crashCountdown > 0) {
        setState(() => _crashCountdown--);
      } else {
        // Süre doldu, SOS gönder!
        timer.cancel();
        _sendSosAndStop();
      }
    });
  }

  Future<void> _sendSosAndStop() async {
    final alert = MotoSosAlert(
      id: "sos_${DateTime.now().millisecondsSinceEpoch}",
      senderId: widget.user.id,
      senderNickname: widget.user.nickname,
      senderPhoto: widget.user.imageUrls.isNotEmpty ? widget.user.imageUrls.first : "",
      latitude: _lastPosition?.latitude ?? widget.user.latitude ?? 0.0,
      longitude: _lastPosition?.longitude ?? widget.user.longitude ?? 0.0,
      timestamp: DateTime.now(),
      type: 'Kaza / Acil Destek',
      description: "Otomatik kaza algılandı! Sürücü hareketsiz.",
      locationName: "Bilinmeyen Konum",
      isResolved: false,
    );
    await FirestoreService().createSosAlert(alert);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🚨 SOS Alarmı Gönderildi!"), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _cancelCrashWarning() {
    _crashTimer?.cancel();
    setState(() {
      _crashWarningActive = false;
      _highGForceDetected = false;
    });
  }

  void _stopRide() {
    setState(() => _isRecording = false);
    _timer?.cancel();
    
    // Basit bir sürüş özeti dialog'u
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: NeuContainer(
          padding: const EdgeInsets.all(24),
          borderRadius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_motorsports, color: NeuColors.accentOrange, size: 48),
              const SizedBox(height: 16),
              const Text("Sürüş Tamamlandı!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              
              _buildSummaryRow(Icons.timer, "Süre", "${_duration.inMinutes} dk ${_duration.inSeconds % 60} sn"),
              _buildSummaryRow(Icons.route, "Mesafe", "${_distanceKm.toStringAsFixed(2)} km"),
              _buildSummaryRow(Icons.speed, "Maks Hız", "${_maxSpeedKmh.toStringAsFixed(1)} km/h"),
              _buildSummaryRow(Icons.screen_rotation, "Maks Yatış", "${_maxLeanAngle.toStringAsFixed(1)}°"),
              
              const SizedBox(height: 24),
              NeuButton(
                text: "Garaja Dön",
                isPrimary: true,
                onPressed: () {
                  // İstenirse burada Firestore'a Sürüş Geçmişi yazılabilir.
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white54, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white70)),
            ],
          ),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_crashWarningActive) {
      return Scaffold(
        backgroundColor: Colors.red[900],
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 100),
                const SizedBox(height: 20),
                const Text("KAZA MI YAPTIN?", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Sert bir sarsıntı algıladık.", style: TextStyle(color: Colors.white70, fontSize: 18)),
                const SizedBox(height: 40),
                Text("$_crashCountdown", style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text("Süre dolduğunda yakındaki herkese SOS gidecek!", style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 60),
                NeuButton(
                  color: Colors.green,
                  textColor: Colors.white,
                  text: "İYİYİM (İPTAL ET)",
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  onPressed: _cancelCrashWarning,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        title: const Text("Sürüş Kaydediliyor"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: NeuColors.surfaceDark,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              NeuContainer(
                padding: const EdgeInsets.symmetric(vertical: 30),
                borderRadius: 24,
                color: NeuColors.surface,
                child: Center(
                  child: Column(
                    children: [
                      const Text("Geçen Süre", style: TextStyle(color: Colors.white54, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(_duration),
                        style: const TextStyle(color: NeuColors.accentOrange, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(child: _buildMetricCard(Icons.speed, "Anlık Hız", _currentSpeedKmh.toStringAsFixed(0), "km/h")),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMetricCard(Icons.route, "Mesafe", _distanceKm.toStringAsFixed(2), "km")),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildMetricCard(Icons.screen_rotation, "Yatış", _currentLeanAngle.toStringAsFixed(0), "°")),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMetricCard(Icons.flag, "Max Hız", _maxSpeedKmh.toStringAsFixed(0), "km/h")),
                ],
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                child: NeuButton(
                  color: Colors.redAccent,
                  textColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  borderRadius: 20,
                  onPressed: _stopRide,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stop_circle_outlined, size: 28),
                      SizedBox(width: 12),
                      Text("SÜRÜŞÜ BİTİR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(IconData icon, String title, String value, String unit) {
    return NeuContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      depth: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white54, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
