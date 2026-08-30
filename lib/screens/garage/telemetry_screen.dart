import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/user_model.dart';
import '../../models/telemetry_model.dart';
import '../../services/firestore_service.dart';
import '../../services/sensor_service.dart';
import '../../widgets/neumorphic_widgets.dart';

class TelemetryScreen extends StatefulWidget {
  final MotoUser currentUser;

  const TelemetryScreen({super.key, required this.currentUser});

  @override
  State<TelemetryScreen> createState() => _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sensör ve Telemetri State
  StreamSubscription<double>? _sensorAngleSub;
  StreamSubscription<double>? _sensorGSub;
  StreamSubscription<Position>? _gpsSub;

  double _currentLeanAngle = 0.0; // Negatif: Sol, Pozitif: Sağ
  double _maxLeanLeft = 0.0;
  double _maxLeanRight = 0.0;
  double _currentSpeed = 0.0;
  double _topSpeed = 0.0;
  double _gForce = 1.0;
  double _calibrationOffset = 0.0; // 0° kalibrasyon sapması

  // Sürüş Oturumu State
  bool _isRecording = false;
  Timer? _sessionTimer;
  int _sessionDurationSeconds = 0;
  List<double> _speedSamples = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _maxLeanLeft = widget.currentUser.maxLeanAngleLeft;
    _maxLeanRight = widget.currentUser.maxLeanAngleRight;
    _topSpeed = widget.currentUser.topSpeedKmH;

    FirestoreService().seedSampleTelemetryIfEmpty();
    _initSensors();
    _initGps();
  }

  @override
  void dispose() {
    _sensorAngleSub?.cancel();
    _sensorGSub?.cancel();
    _gpsSub?.cancel();
    _sessionTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _initSensors() async {
    await SensorService().requestPermissionAndStart();

    _sensorAngleSub = SensorService().leanAngleStream.listen((angle) {
      final calibrated = angle - _calibrationOffset;
      _updateLeanAngle(calibrated, _gForce);
    });

    _sensorGSub = SensorService().gForceStream.listen((g) {
      if (mounted) setState(() => _gForce = g);
    });
  }

  void _initGps() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      _gpsSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 2),
      ).listen((Position position) {
        // Hız (m/s -> km/s)
        final double speedKmH = (position.speed * 3.6).clamp(0.0, 320.0);
        if (mounted) {
          setState(() {
            _currentSpeed = speedKmH;
            if (speedKmH > _topSpeed) _topSpeed = speedKmH;
            if (_isRecording) _speedSamples.add(speedKmH);
          });
        }
      });
    } catch (_) {}
  }

  void _updateLeanAngle(double angle, double g) {
    if (!mounted) return;
    setState(() {
      _currentLeanAngle = angle.clamp(-65.0, 65.0);
      _gForce = g;

      if (_currentLeanAngle < 0) {
        final absLeft = _currentLeanAngle.abs();
        if (absLeft > _maxLeanLeft) _maxLeanLeft = absLeft;
      } else {
        if (_currentLeanAngle > _maxLeanRight) _maxLeanRight = _currentLeanAngle;
      }
    });
  }

  void _toggleSessionRecording() {
    if (_isRecording) {
      // Oturumu Bitir ve Kaydet
      _sessionTimer?.cancel();
      _showSaveSessionDialog();
      setState(() => _isRecording = false);
    } else {
      // Yeni Oturum Başlat
      setState(() {
        _isRecording = true;
        _sessionDurationSeconds = 0;
        _speedSamples = [];
      });
      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _sessionDurationSeconds++);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🚀 Telemetri oturumu başladı! Virajları ve hızını canlı kaydediyoruz."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showSaveSessionDialog() {
    final double avgSpeed = _speedSamples.isNotEmpty
        ? (_speedSamples.reduce((a, b) => a + b) / _speedSamples.length)
        : _currentSpeed;
    final int safetyScore = math.min(100, math.max(60, 100 - ((_topSpeed > 140 ? 10 : 0) + (_maxLeanLeft > 55 ? 5 : 0))));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.flag_circle, color: NeuColors.accentOrange, size: 28),
                  SizedBox(width: 8),
                  Text(
                    "Sürüş Oturumu Tamamlandı 🏁",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    _dialogStatRow("Maksimum Sol Yatış:", "${_maxLeanLeft.toStringAsFixed(1)}°"),
                    _dialogStatRow("Maksimum Sağ Yatış:", "${_maxLeanRight.toStringAsFixed(1)}°"),
                    _dialogStatRow("Maksimum Hız:", "${_topSpeed.toStringAsFixed(0)} km/s"),
                    _dialogStatRow("Ortalama Hız:", "${avgSpeed.toStringAsFixed(0)} km/s"),
                    _dialogStatRow("Sürüş Süresi:", "${_sessionDurationSeconds ~/ 60} dk ${_sessionDurationSeconds % 60} sn"),
                    _dialogStatRow("Güvenlik Skoru:", "$safetyScore / 100 🛡️"),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeuColors.accentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.leaderboard, size: 20),
                label: const Text("Liderlik Tablosuna Kaydet 🏆", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final record = TelemetryRecord(
                    id: '',
                    userId: widget.currentUser.id,
                    nickname: widget.currentUser.nickname,
                    motorcycle: widget.currentUser.primaryMotor,
                    location: widget.currentUser.locationName,
                    maxLeanLeft: _maxLeanLeft,
                    maxLeanRight: _maxLeanRight,
                    topSpeed: _topSpeed,
                    avgSpeed: avgSpeed,
                    durationSeconds: _sessionDurationSeconds,
                    safetyScore: safetyScore,
                    timestamp: DateTime.now(),
                  );
                  await FirestoreService().saveTelemetryRecord(record);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("🏆 Telemetri dereceniz Liderlik Tablosuna başarıyla işlendi!"),
                        backgroundColor: Colors.amber,
                      ),
                    );
                    _tabController.animateTo(1);
                  }
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Yalnızca Kapat", style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: const TextStyle(color: NeuColors.accentAmber, fontWeight: FontWeight.bold, fontSize: 13.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        backgroundColor: NeuColors.surfaceDark,
        title: const Row(
          children: [
            Icon(Icons.screen_rotation, color: NeuColors.accentOrange, size: 22),
            SizedBox(width: 8),
            Text(
              "Telemetri & Yatış Açısı",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: NeuColors.accentOrange,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.speed, size: 20), text: "Canlı Kokpit"),
            Tab(icon: Icon(Icons.leaderboard, size: 20), text: "Viraj Liderleri 🏆"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveCockpitTab(),
          _buildLeaderboardTab(),
        ],
      ),
    );
  }

  Widget _buildLiveCockpitTab() {
    final double absLean = _currentLeanAngle.abs();
    final String direction = _currentLeanAngle < -1.0 ? "SOL VİRAJ" : (_currentLeanAngle > 1.0 ? "SAĞ VİRAJ" : "DİK KONUM");
    final Color angleColor = absLean > 45 ? Colors.redAccent : (absLean > 30 ? Colors.amber : Colors.cyanAccent);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // YASAL & GÜVENLİK BİLGİLENDİRME ŞERİDİ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.gavel, color: Colors.amber, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "⚖️ Yasal Uyarısı: Yatış açısı ve telemetri verileri kapalı pistler ve güvenli sürüş içindir. Trafik kurallarına uyunuz.",
                    style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          // SENSÖR BAŞLATMA / İZİN VERME HIZLI BUTONU
          GestureDetector(
            onTap: () async {
              await SensorService().requestPermissionAndStart();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("⚡ Telefon jiroskopu ve hareket sensörleri bağlandı! 🟢"),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0C3825), Color(0xFF1E1E1E)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.6)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.sensors, color: Colors.greenAccent, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "⚡ Telefon Sensörlerini & Jiroskopu Başlat",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          "Tarayıcıda / iPhone'da hareket iznini aktifleştirmek için dokunun.",
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.touch_app, color: Colors.greenAccent, size: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 1. CANLI YATIŞ AÇISI GÖSTERGE KOKPİTİ
          NeuContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 24,
            depth: 5,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("SOL MAKSİMUM", style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text("${_maxLeanLeft.toStringAsFixed(1)}°", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: angleColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: angleColor),
                      ),
                      child: Text(
                        direction,
                        style: TextStyle(color: angleColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("SAĞ MAKSİMUM", style: TextStyle(color: NeuColors.accentOrange, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text("${_maxLeanRight.toStringAsFixed(1)}°", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // YATAN MOTOSİKLET VİZUALİZASYONU
                SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Derece Skala Çemberi
                      CustomPaint(
                        size: const Size(220, 160),
                        painter: _LeanGaugePainter(currentAngle: _currentLeanAngle),
                      ),

                      // Dönen / Yatan Motor İkonu
                      Transform.rotate(
                        angle: (_currentLeanAngle * math.pi / 180),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.two_wheeler,
                              size: 76,
                              color: angleColor,
                            ),
                            Container(
                              width: 32,
                              height: 3,
                              decoration: BoxDecoration(
                                color: angleColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // BÜYÜK DİJİTAL AÇI GÖSTERGESİ
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      absLean.toStringAsFixed(1),
                      style: TextStyle(
                        color: angleColor,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "° DERECE",
                      style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. HIZ & G-FORCE KARTLARI
          Row(
            children: [
              Expanded(
                child: NeuContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 18,
                  depth: 3,
                  child: Column(
                    children: [
                      const Icon(Icons.speed, color: Colors.greenAccent, size: 24),
                      const SizedBox(height: 6),
                      Text(
                        "${_currentSpeed.toStringAsFixed(0)} km/s",
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      const Text("Canlı GPS Hızı", style: TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeuContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 18,
                  depth: 3,
                  child: Column(
                    children: [
                      const Icon(Icons.compress, color: Colors.amber, size: 24),
                      const SizedBox(height: 6),
                      Text(
                        "${_gForce.toStringAsFixed(2)} G",
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      const Text("G-Kuvveti", style: TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. SÜRÜŞÜ BAŞLAT / BİTİR AKSİYON BUTONU
          NeuButton(
            color: _isRecording ? Colors.red[800]! : Colors.green[800]!,
            textColor: Colors.white,
            borderRadius: 18,
            depth: 4,
            padding: const EdgeInsets.symmetric(vertical: 16),
            onPressed: _toggleSessionRecording,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_isRecording ? Icons.stop_circle : Icons.play_circle_fill, size: 24),
                const SizedBox(width: 10),
                Text(
                  _isRecording
                      ? "⏹️ Sürüşü Tamamla (${_sessionDurationSeconds ~/ 60}:${(_sessionDurationSeconds % 60).toString().padLeft(2, '0')})"
                      : "🟢 Sürüş Oturumunu Başlat",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. OTOMATİK DONANIM SENSÖR DURUMU & 0° KALİBRASYON KARTI
          NeuContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            depth: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.sensors, color: Colors.greenAccent, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "📱 Otomatik Telefon Sensörleri: Aktif 🟢",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "Telefonun dahili jiroskop ve ivmeölçer donanımı motosikletin viraj yatış açısını ve dinamiklerini otomatik hesaplar.",
                  style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.3),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NeuColors.accentOrange,
                      side: const BorderSide(color: NeuColors.accentOrange, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text(
                      "🎯 Dik Konumda 0° Açıyı Sıfırla (Kalibre Et)",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        _calibrationOffset = _currentLeanAngle + _calibrationOffset;
                        _currentLeanAngle = 0.0;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("🎯 0° Dik Konum Kalibre Edildi!"),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return StreamBuilder<List<TelemetryRecord>>(
      stream: FirestoreService().streamTelemetryLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: NeuColors.accentOrange));
        }

        final records = snapshot.data ?? [];

        if (records.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NeuContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 30,
                    depth: 4,
                    child: const Icon(Icons.emoji_events_outlined, size: 64, color: Colors.amber),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Henüz Liderlik Kaydı Yok",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Telemetri ekranından bir sürüş oturumu başlatıp tamamlayarak ilk viraj rekorunu sen kır! 🏆🏍️",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            final rank = index + 1;

            Color rankColor = Colors.white54;
            Widget rankIcon = Text("#$rank", style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 14));

            if (rank == 1) {
              rankColor = Colors.amber;
              rankIcon = const Icon(Icons.workspace_premium, color: Colors.amber, size: 28);
            } else if (rank == 2) {
              rankColor = const Color(0xFFC0C0C0);
              rankIcon = const Icon(Icons.military_tech, color: Color(0xFFC0C0C0), size: 26);
            } else if (rank == 3) {
              rankColor = const Color(0xFFCD7F32);
              rankIcon = const Icon(Icons.military_tech, color: Color(0xFFCD7F32), size: 24);
            }

            final isMe = record.userId == widget.currentUser.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NeuContainer(
                padding: const EdgeInsets.all(14),
                borderRadius: 18,
                depth: isMe ? 5 : 2,
                color: isMe ? const Color(0xFF262015) : NeuColors.surface,
                borderColor: isMe ? Colors.amber : (rank == 1 ? Colors.amber.withValues(alpha: 0.4) : Colors.white12),
                borderWidth: isMe ? 1.5 : 1,
                child: Row(
                  children: [
                    // Sıralama Rozeti
                    SizedBox(width: 36, child: Center(child: rankIcon)),
                    const SizedBox(width: 8),

                    // Sürücü ve Motor Bilgisi
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  record.nickname,
                                  style: TextStyle(
                                    color: isMe ? Colors.amber : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                                  child: const Text("SEN", style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${record.motorcycle} • ${record.location}",
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text("Sol: ${record.maxLeanLeft.toStringAsFixed(1)}°", style: const TextStyle(color: Colors.cyanAccent, fontSize: 10.5, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text("Sağ: ${record.maxLeanRight.toStringAsFixed(1)}°", style: const TextStyle(color: NeuColors.accentOrange, fontSize: 10.5, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text("🛡️ %${record.safetyScore}", style: const TextStyle(color: Colors.greenAccent, fontSize: 10.5)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Derece Açı Rozeti
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: rankColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: rankColor.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "${record.maxLeanAngle.toStringAsFixed(1)}°",
                            style: TextStyle(
                              color: rankColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const Text(
                            "YATIŞ",
                            style: TextStyle(color: Colors.white38, fontSize: 8.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LeanGaugePainter extends CustomPainter {
  final double currentAngle;

  _LeanGaugePainter({required this.currentAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.75);
    final radius = size.width * 0.42;

    final arcPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    // Yay Çizgisi (-60° ile +60°)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.85,
      math.pi * 0.7,
      false,
      arcPaint,
    );

    // Limit Açı İbreleri (30°, 45°, 55°)
    final tickPaint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 2;

    for (int deg in [-50, -40, -30, -15, 0, 15, 30, 40, 50]) {
      final rad = (deg - 90) * math.pi / 180;
      final p1 = Offset(center.dx + (radius - 8) * math.cos(rad), center.dy + (radius - 8) * math.sin(rad));
      final p2 = Offset(center.dx + (radius + 6) * math.cos(rad), center.dy + (radius + 6) * math.sin(rad));
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LeanGaugePainter oldDelegate) => oldDelegate.currentAngle != currentAngle;
}
