import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../../models/user_model.dart';
import '../../models/sos_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/radar_driver_card.dart';
import '../../widgets/pulse_marker.dart';
import '../../widgets/moto_weather_bar.dart';
import '../../widgets/navigation_helper.dart';
import 'crossed_paths_screen.dart';
import 'sos_sheet.dart';
import '../garage/vip_garage_screen.dart';
import '../../widgets/neumorphic_widgets.dart';

class RadarScreen extends StatefulWidget {
  final MotoUser aktifKullanici;
  const RadarScreen({super.key, required this.aktifKullanici});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  MotoUser? _secilenMotorcu;
  MotoUser? _liveTrackedFriend; // Life 360 Canlı Takip edilen arkadaş
  final MapController _mapController = MapController();
  late LatLng _benimKonumum;
  bool _gpsAktif = false;
  String _gpsDurumMesaji = "GPS Başlatılıyor...";
  StreamSubscription<Position>? _gpsStreamSub;
  DateTime? _lastGpsSyncTime;
  bool _selektorFlashGoster = false;
  double _selectedRadiusKm = 5.0; // 5 km (Standart), 30 km (VIP)
  
  // Crossed Paths State
  final Set<String> _recordedCrossedPaths = {};
  DateTime? _lastCrossedPathCheckTime;

  @override
  void initState() {
    super.initState();
    _benimKonumum = widget.aktifKullanici.latLng;
    // Açılışta eski test botlarını veritabanından hemen temizle
    FirestoreService().purgeAllTestUsers();
    FirestoreService().seedSampleUsersIfEmpty();
    _startContinuousGpsStream();
  }

  @override
  void dispose() {
    _gpsStreamSub?.cancel();
    super.dispose();
  }

  Future<void> _startContinuousGpsStream() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _gpsAktif = false;
            _gpsDurumMesaji = "Konum servisi kapalı";
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _gpsAktif = false;
              _gpsDurumMesaji = "Konum izni verilmedi";
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _gpsAktif = false;
            _gpsDurumMesaji = "Konum izni kalıcı reddedildi";
          });
        }
        return;
      }

      // 1. İlk konumu hemen çek
      final initialPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _handleNewPosition(initialPos);

      // 2. Life 360 gibi canlı, sürekli GPS akışını başlat (navigasyon hassasiyetinde)
      _gpsStreamSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2,
        ),
      ).listen((Position position) {
        _handleNewPosition(position);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _gpsAktif = false;
          _gpsDurumMesaji = "GPS Hatası (Varsayılan Konum)";
        });
      }
    }
  }

  void _handleNewPosition(Position position) {
    if (!mounted) return;
    final double speedKmH = (position.speed * 3.6).clamp(0.0, 300.0);
    setState(() {
      _benimKonumum = LatLng(position.latitude, position.longitude);
      widget.aktifKullanici.latitude = position.latitude;
      widget.aktifKullanici.longitude = position.longitude;
      _gpsAktif = true;
      _gpsDurumMesaji = "Canlı 360 GPS Aktif (${speedKmH.toStringAsFixed(0)} km/s) 🟢";
    });

    // 4 saniyede bir Firestore'a anlık koordinat, hız ve yön senkronize et
    final now = DateTime.now();
    if (_lastGpsSyncTime == null || now.difference(_lastGpsSyncTime!).inSeconds >= 4) {
      _lastGpsSyncTime = now;
      FirestoreService().updateUserLocation(
        widget.aktifKullanici.id,
        position.latitude,
        position.longitude,
        "İstanbul",
        speed: speedKmH,
        heading: position.heading,
      );
    }

    // 15 saniyede bir Crossed Paths (Kesişen Yollar) kontrolü yap (1km yarıçap)
    if (_lastCrossedPathCheckTime == null || now.difference(_lastCrossedPathCheckTime!).inSeconds >= 15) {
      _lastCrossedPathCheckTime = now;
      _checkCrossedPaths();
    }
  }

  void _checkCrossedPaths() async {
    try {
      final radarUsers = await FirestoreService().getRadarUsersOnce(
        currentUserId: widget.aktifKullanici.id,
        currentUserEmail: widget.aktifKullanici.email,
      );

      for (var rider in radarUsers) {
        if (_recordedCrossedPaths.contains(rider.id)) continue; // Bu oturumda zaten kaydedildi

        if (rider.latitude == null || rider.longitude == null) continue;

        double dist = Geolocator.distanceBetween(
          _benimKonumum.latitude,
          _benimKonumum.longitude,
          rider.latitude!,
          rider.longitude!,
        );

        if (dist <= 1000.0) { // 1 KM Yarıçap
          await FirestoreService().recordCrossedPath(
            currentUserId: widget.aktifKullanici.id,
            otherUser: rider,
            locationName: "Yakınından Geçti",
            distanceKm: dist / 1000.0,
          );
          // Karşı tarafın swipe ekranına da düşmek için karşı taraf için de kaydedelim
          await FirestoreService().recordCrossedPath(
            currentUserId: rider.id,
            otherUser: widget.aktifKullanici,
            locationName: "Yakınından Geçti",
            distanceKm: dist / 1000.0,
          );
          
          _recordedCrossedPaths.add(rider.id);
          debugPrint("CROSSED PATH RECORDED WITH: ${rider.nickname} (${dist.toStringAsFixed(0)}m)");
        }
      }
    } catch (e) {
      debugPrint("Crossed paths check failed: $e");
    }
  }

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http')) {
      return NetworkImage(path);
    }
    if (path.startsWith('data:image')) {
      final base64String = path.split(',').last;
      return MemoryImage(base64Decode(base64String));
    }
    return NetworkImage(path);
  }

  Widget _buildMarkerIcon(MotoUser rider, double distKm) {
    final bool isVerified = rider.isVerified;
    final String distBadge = distKm < 1 ? "${(distKm * 1000).toInt()} m" : "${distKm.toStringAsFixed(1)} km";

    return GestureDetector(
      onTap: () {
        setState(() {
          _secilenMotorcu = rider;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mesafe Rozeti
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: NeuColors.surfaceDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: NeuColors.accentOrange, width: 1),
            ),
            child: Text(
              distBadge,
              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 3),
          // Sürücü Avatarı
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isVerified ? Colors.blueAccent : NeuColors.accentOrange,
                    width: 2.2,
                  ),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: NeuColors.surfaceDark,
                  backgroundImage: rider.imageUrls.isNotEmpty ? _getImageProvider(rider.imageUrls[0]) : null,
                  child: rider.imageUrls.isEmpty ? const Icon(Icons.person, color: NeuColors.accentOrange, size: 20) : null,
                ),
              ),
              if (isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(color: NeuColors.surfaceDark, shape: BoxShape.circle),
                    child: const Icon(Icons.verified, color: Colors.blueAccent, size: 13),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSosMarker(MotoSosAlert sos) {
    return PulseMarker(
      color: Colors.redAccent,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red[900],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.redAccent, width: 2),
          boxShadow: const [BoxShadow(color: Colors.redAccent, blurRadius: 10)],
        ),
        child: const Icon(Icons.crisis_alert, color: Colors.white, size: 22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MotoUser>>(
      stream: FirestoreService().streamRadarUsers(
        currentUserId: widget.aktifKullanici.id,
        currentUserEmail: widget.aktifKullanici.email,
      ),
      builder: (context, snapshot) {
        final allRiders = snapshot.data ?? [];
        const Distance distCalculator = Distance();

        // 1. Engellenenleri ve Mesafe Filtresine Uymayanları Filtrele
        final radardakiMotorcular = allRiders.where((m) {
          if (widget.aktifKullanici.isUserBlocked(m.id)) return false;
          if (_selectedRadiusKm >= 500) return true; // Tüm Şehir
          final double d = distCalculator.as(LengthUnit.Kilometer, _benimKonumum, m.latLng);
          return d <= _selectedRadiusKm;
        }).toList();

        // Canlı Takip Edilen Arkadaşı Listeden Gerçek Zamanlı Güncelle
        MotoUser? liveFriend;
        if (_liveTrackedFriend != null) {
          try {
            liveFriend = allRiders.firstWhere((r) => r.id == _liveTrackedFriend!.id);
          } catch (_) {
            liveFriend = _liveTrackedFriend;
          }
        }

        return StreamBuilder<List<MotoSosAlert>>(
          stream: FirestoreService().streamActiveSosAlerts(),
          builder: (context, sosSnapshot) {
            final activeSosList = sosSnapshot.data ?? [];
            final myActiveSosList = activeSosList.where((s) => s.senderId == widget.aktifKullanici.id).toList();
            final bool hasMyActiveSos = myActiveSosList.isNotEmpty;

            final List<Marker> markerListesi = [];

            // 1. Kendi Konumumuz
            final bool isBoosted = widget.aktifKullanici.isBoostActive;
            markerListesi.add(
              Marker(
                point: _benimKonumum,
                width: isBoosted ? 85 : 70,
                height: isBoosted ? 85 : 70,
                child: PulseMarker(
                  color: isBoosted ? NeuColors.accentAmber : NeuColors.accentOrange,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isBoosted ? NeuColors.accentAmber : NeuColors.accentOrange,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isBoosted ? Colors.amberAccent : Colors.white,
                        width: isBoosted ? 3.5 : 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isBoosted ? Colors.amber.withValues(alpha: 0.8) : Colors.black54,
                          blurRadius: isBoosted ? 14 : 6,
                          spreadRadius: isBoosted ? 3 : 1,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.two_wheeler, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
            );

            // 2. Çevredeki Filtrelenmiş Motorcular
            for (var rider in radardakiMotorcular) {
              final double d = distCalculator.as(LengthUnit.Kilometer, _benimKonumum, rider.latLng);
              markerListesi.add(
                Marker(
                  point: rider.latLng,
                  width: 90,
                  height: 75,
                  child: _buildMarkerIcon(rider, d),
                ),
              );
            }

            // 3. Aktif S.O.S. Çağrıları
            for (var sos in activeSosList) {
              markerListesi.add(
                Marker(
                  point: sos.latLng,
                  width: 60,
                  height: 60,
                  child: _buildSosMarker(sos),
                ),
              );
            }

            return Stack(
              children: [
                // AÇIK KAYNAK HARİTA
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _benimKonumum,
                    initialZoom: 13.0,
                    minZoom: 8.0,
                    maxZoom: 18.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onTap: (tapPosition, point) => setState(() => _secilenMotorcu = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.motoconnect.app',
                    ),
                    // Radar menzil dairesi
                    if (_selectedRadiusKm < 500)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _benimKonumum,
                            radius: _selectedRadiusKm * 1000,
                            useRadiusInMeter: true,
                            color: NeuColors.accentOrange.withValues(alpha: 0.08),
                            borderColor: NeuColors.accentOrange.withValues(alpha: 0.5),
                            borderStrokeWidth: 1.5,
                          ),
                        ],
                      ),
                    // Life 360 Canlı Takip Rota Çizgisi
                    if (liveFriend != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [_benimKonumum, liveFriend.latLng],
                            strokeWidth: 4.5,
                            color: NeuColors.accentCyan,
                          ),
                        ],
                      ),
                    MarkerLayer(markers: markerListesi),
                  ],
                ),

                // SELEKTÖR GÖRSEL FLASH EFEKTİ
                if (_selektorFlashGoster)
                  IgnorePointer(
                    child: Container(
                      color: Colors.amber.withValues(alpha: 0.35),
                    ),
                  ),

                // LİFE 360 CANLI TAKİP HUD ŞERİDİ
                if (liveFriend != null)
                  Positioned(
                    top: 100,
                    left: 16,
                    right: 16,
                    child: NeuContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      borderRadius: 16,
                      depth: 4,
                      color: const Color(0xFF0B2230),
                      borderColor: NeuColors.accentCyan,
                      borderWidth: 1.2,
                      child: Row(
                        children: [
                          PulseMarker(
                            color: NeuColors.accentCyan,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: NeuColors.accentCyan,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.radar, color: Colors.black, size: 16),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        liveFriend.nickname,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const NeuBadge(text: "CANLI 360", color: NeuColors.accentCyan, fontSize: 8.5),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Mesafe: ${distCalculator.as(LengthUnit.Kilometer, _benimKonumum, liveFriend.latLng).toStringAsFixed(2)} km • Hız: ${liveFriend.topSpeedKmH > 0 ? liveFriend.topSpeedKmH.toStringAsFixed(0) : '68'} km/s",
                                  style: const TextStyle(color: NeuColors.accentCyan, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          NeuIconButton(
                            icon: Icons.navigation,
                            iconColor: NeuColors.accentOrange,
                            size: 36,
                            iconSize: 18,
                            tooltip: "Yol Tarifi Al",
                            onPressed: () {
                              final f = liveFriend;
                              if (f == null) return;
                              NavigationHelper.openNavigationSheet(
                                context,
                                targetLat: f.latLng.latitude,
                                targetLng: f.latLng.longitude,
                                title: "${f.nickname} Konumu",
                                subtitle: "Canlı 360 Sürüş Takibi",
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          NeuIconButton(
                            icon: Icons.close,
                            size: 36,
                            iconSize: 16,
                            tooltip: "Takibi Bırak",
                            onPressed: () => setState(() => _liveTrackedFriend = null),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ÜST BİLGİ, HAVA DURUMU & RADAR ÇUBUĞU
                Positioned(
                  top: 36,
                  left: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // S.O.S. YAYINDA VE AKTİFSE KAPATMA BANNERI
                      if (hasMyActiveSos)
                        NeuContainer(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          borderRadius: 16,
                          color: const Color(0xFF380808),
                          borderColor: Colors.redAccent,
                          borderWidth: 1.5,
                          child: Row(
                            children: [
                              const Icon(Icons.crisis_alert, color: Colors.redAccent, size: 24),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "🚨 S.O.S. YAYININIZ AKTİF!",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                                    ),
                                    Text(
                                      "Çevredeki motorcular çağrınızı görüyor.",
                                      style: TextStyle(color: Colors.white70, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              NeuButton(
                                text: "KAPAT",
                                color: Colors.redAccent,
                                textColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                borderRadius: 10,
                                onPressed: () async {
                                  await FirestoreService().cancelMyActiveSosAlerts(widget.aktifKullanici.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("✅ S.O.S. Kapatıldı. Güvendesiniz!"),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                      // CANLI MOTORCU HAVA & ASFALT TUTUŞ BAR
                      const MotoWeatherBar(),

                      const SizedBox(height: 8),

                      // RADAR BİLGİ & MENZİL ÇUBUĞU
                      NeuContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        borderRadius: 16,
                        child: Row(
                          children: [
                            const Icon(Icons.radar, color: NeuColors.accentOrange, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Radar: ${radardakiMotorcular.length} Sürücü (${_selectedRadiusKm.toInt()} km)",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  Text(
                                    _gpsDurumMesaji,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _gpsAktif ? NeuColors.accentGreen : Colors.white54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      // RADAR MENZİLİ SEÇİCİSİ (5 KM vs 30 KM VIP)
                      NeuContainer(
                        padding: const EdgeInsets.all(4),
                        borderRadius: 16,
                        child: Row(
                          children: [
                            Expanded(child: _buildRadiusButton(5.0, "🎯 5 km (Standart)")),
                            const SizedBox(width: 6),
                            Expanded(child: _buildRadiusButton(30.0, "👑 30 km (VIP)")),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // SAĞ ÜST: YOLLARDA KARŞILAŞTIKLARIM BUTONU
                Positioned(
                  top: 195,
                  right: 16,
                  child: NeuIconButton(
                    icon: Icons.history_toggle_off,
                    iconColor: NeuColors.accentOrange,
                    size: 42,
                    iconSize: 20,
                    tooltip: "Yol Kesişmeleri",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CrossedPathsScreen(currentUser: widget.aktifKullanici),
                        ),
                      );
                    },
                  ),
                ),

                // SOL ALT: HARİTADAN DOĞRUDAN S.O.S. ACİL YARDIM ÇAĞRISI BUTONU
                if (_secilenMotorcu == null)
                  Positioned(
                    bottom: 24,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => SosSheet.showCreateSos(context, currentUser: widget.aktifKullanici),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.crisis_alert, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "S.O.S. ÇAĞRISI",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // SAĞ ALT: KONUMUMA ODAKLAN BUTONU
                Positioned(
                  bottom: 24,
                  right: 16,
                  child: NeuIconButton(
                    icon: Icons.my_location,
                    iconColor: NeuColors.accentOrange,
                    size: 52,
                    iconSize: 24,
                    tooltip: "Konumuma Odaklan",
                    onPressed: () {
                      _mapController.move(_benimKonumum, 14.5);
                      _startContinuousGpsStream();
                    },
                  ),
                ),

                // SEÇİLEN MOTORCU BİLGİ KARTI
                if (_secilenMotorcu != null)
                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 88,
                    child: RadarDriverCard(
                      selectedRider: _secilenMotorcu!,
                      currentUserLocation: _benimKonumum,
                      currentUser: widget.aktifKullanici,
                      onClose: () => setState(() => _secilenMotorcu = null),
                      onSignalTriggered: () {
                        setState(() {
                          _selektorFlashGoster = true;
                        });
                        Future.delayed(const Duration(milliseconds: 180), () {
                          if (mounted) setState(() => _selektorFlashGoster = false);
                        });
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showVipRadiusSheet() {
    VipGarajEkrani.showPaywall(context, currentUser: widget.aktifKullanici);
  }

  Widget _buildRadiusButton(double km, String label) {
    final bool isSelected = _selectedRadiusKm == km;
    final bool isVipOnly = km > 5;
    final bool isUserVip = widget.aktifKullanici.isPremium;

    return GestureDetector(
      onTap: () {
        if (isVipOnly && !isUserVip) {
          _showVipRadiusSheet();
          return;
        }
        setState(() => _selectedRadiusKm = km);
        double targetZoom = km == 5 ? 14.5 : 11.5;
        _mapController.move(_benimKonumum, targetZoom);
      },
      child: NeuContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        borderRadius: 12,
        style: isSelected ? NeuStyle.sunken : NeuStyle.flat,
        color: isSelected ? NeuColors.accentOrange.withValues(alpha: 0.2) : Colors.transparent,
        borderColor: isSelected ? NeuColors.accentOrange : Colors.transparent,
        borderWidth: isSelected ? 1.2 : 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? NeuColors.accentOrange : Colors.white70,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isVipOnly && !isUserVip) ...[
              const SizedBox(width: 4),
              const Icon(Icons.lock, color: NeuColors.accentAmber, size: 13),
            ],
          ],
        ),
      ),
    );
  }
}
