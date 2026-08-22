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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isVerified ? const Color(0xFF0D253A) : Colors.black87,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isVerified ? Colors.blueAccent : Colors.deepOrange, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isVerified) ...[
                  const Icon(Icons.verified, color: Colors.blueAccent, size: 10),
                  const SizedBox(width: 2),
                ],
                Text(
                  rider.nickname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  distBadge,
                  style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isVerified ? Colors.blueAccent : (rider.isBoostActive ? Colors.amber : Colors.deepOrange),
                width: rider.isBoostActive ? 3.5 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: rider.isBoostActive ? Colors.amber.withValues(alpha: 0.7) : Colors.black45,
                  blurRadius: rider.isBoostActive ? 10 : 4,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: rider.isBoostActive ? 22 : 18,
              backgroundImage: rider.imageUrls.isNotEmpty ? _getImageProvider(rider.imageUrls[0]) : null,
              backgroundColor: Colors.grey[850],
              child: rider.imageUrls.isEmpty
                  ? const Icon(Icons.two_wheeler, color: Colors.white70, size: 18)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSosMarker(MotoSosAlert sos) {
    return GestureDetector(
      onTap: () => SosSheet.showSosDetails(context, alert: sos, currentUser: widget.aktifKullanici),
      child: PulseMarker(
        color: Colors.redAccent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red[900],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.redAccent, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: const Center(
            child: Icon(Icons.crisis_alert, color: Colors.white, size: 24),
          ),
        ),
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
                  color: isBoosted ? Colors.amber : Colors.deepOrange,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isBoosted ? Colors.amber[800] : Colors.deepOrange,
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
                            color: Colors.deepOrange.withValues(alpha: 0.08),
                            borderColor: Colors.deepOrange.withValues(alpha: 0.5),
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
                            color: Colors.cyanAccent,
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
                      borderColor: Colors.cyanAccent,
                      borderWidth: 1.2,
                      child: Row(
                        children: [
                          PulseMarker(
                            color: Colors.cyanAccent,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: Colors.cyanAccent,
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(color: Colors.cyanAccent, borderRadius: BorderRadius.circular(4)),
                                      child: const Text("CANLI 360", style: TextStyle(color: Colors.black, fontSize: 8.5, fontWeight: FontWeight.w900)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Mesafe: ${distCalculator.as(LengthUnit.Kilometer, _benimKonumum, liveFriend.latLng).toStringAsFixed(2)} km • Hız: ${liveFriend.topSpeedKmH > 0 ? liveFriend.topSpeedKmH.toStringAsFixed(0) : '68'} km/s",
                                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.navigation, color: Colors.deepOrange, size: 22),
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
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
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
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF380808),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.redAccent, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.redAccent, blurRadius: 14, spreadRadius: 1),
                            ],
                          ),
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
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
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
                                child: const Text("KAPAT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ],
                          ),
                        ),

                      // CANLI MOTORCU HAVA & ASFALT TUTUŞ BAR
                      const MotoWeatherBar(),

                      const SizedBox(height: 8),

                      // RADAR BİLGİ & MENZİL ÇUBUĞU
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.radar, color: Colors.deepOrange, size: 22),
                            const SizedBox(width: 8),
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
                                      color: _gpsAktif ? Colors.greenAccent : Colors.white54,
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
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _buildRadiusButton(5.0, "🎯 5 km (Standart)")),
                            const SizedBox(width: 4),
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
                  child: FloatingActionButton.small(
                    heroTag: 'radar_crossed_paths_btn',
                    backgroundColor: const Color(0xFF1E1E1E),
                    tooltip: "Yollarda Karşılaştıklarım",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CrossedPathsScreen(currentUser: widget.aktifKullanici),
                        ),
                      );
                    },
                    child: const Icon(Icons.history_toggle_off, color: Colors.deepOrange),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB71C1C),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.redAccent, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.6),
                              blurRadius: 16,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.crisis_alert, color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text(
                              "🚨 S.O.S. ÇAĞRISI",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 1.2,
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
                  child: FloatingActionButton(
                    heroTag: 'radar_location_btn',
                    backgroundColor: const Color(0xFF1E1E1E),
                    onPressed: () {
                      _mapController.move(_benimKonumum, 14.5);
                      _startContinuousGpsStream();
                    },
                    child: const Icon(Icons.my_location, color: Colors.deepOrange),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? NeuColors.accentOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isVipOnly && !isUserVip) ...[
              const SizedBox(width: 4),
              const Icon(Icons.lock, color: Colors.amber, size: 13),
            ],
          ],
        ),
      ),
    );
  }
}
