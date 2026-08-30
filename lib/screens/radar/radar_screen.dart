import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../models/user_model.dart';
import '../../models/sos_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/pulse_marker.dart';
import '../../widgets/moto_weather_bar.dart';
import 'crossed_paths_screen.dart';
import '../../models/crossed_path_model.dart';
import 'sos_sheet.dart';
import '../../widgets/neumorphic_widgets.dart';
import 'ride_recording_screen.dart';
/// [RadarScreen]
/// Uygulamanın ana ekranıdır (Harita). 
/// Kullanıcının mevcut konumunu alır, etrafındaki (yanından geçtiği) sürücüleri ve aktif S.O.S sinyallerini harita üzerinde gösterir.
/// Karanlık tema harita (OpenStreetMap + ColorFiltered) kullanır.
class RadarScreen extends StatefulWidget {
  final MotoUser aktifKullanici;
  const RadarScreen({super.key, required this.aktifKullanici});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  final MapController _mapController = MapController();
  late LatLng _benimKonumum;
  bool _gpsAktif = false;
  String _gpsDurumMesaji = "GPS Başlatılıyor...";
  StreamSubscription<Position>? _gpsStreamSub;
  DateTime? _lastGpsSyncTime;
  bool _isMapReady = false;
  bool _isFirstLocationCentered = false;
  
  // Crossed Paths State
  final Set<String> _recordedCrossedPaths = {};
  DateTime? _lastCrossedPathCheckTime;

  @override
  void initState() {
    super.initState();
    _benimKonumum = widget.aktifKullanici.latLng;
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

    if (_isMapReady && !_isFirstLocationCentered) {
      _isFirstLocationCentered = true;
      _mapController.move(_benimKonumum, 14.5);
    }

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
    return StreamBuilder<List<CrossedPathEvent>>(
      stream: FirestoreService().streamCrossedPaths(widget.aktifKullanici.id),
      builder: (context, snapshot) {
        final allCrossedPaths = snapshot.data ?? [];

        // 1. Engellenenleri Filtrele (Mesafe kısıtlaması kaldırıldı, tüm karşılaşılanlar görünür)
        final radardakiMotorcular = allCrossedPaths.where((event) {
          if (widget.aktifKullanici.isUserBlocked(event.rider.id)) return false;
          return true;
        }).toList();

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

            // 2. Çevredeki Filtrelenmiş Denk Gelişler
            for (var event in radardakiMotorcular) {
              markerListesi.add(
                Marker(
                  point: event.rider.latLng, // Note: Should ideally be the crossed location, but using rider's last known location.
                  width: 60,
                  height: 60,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CrossedPathsScreen(currentUser: widget.aktifKullanici),
                        ),
                      );
                    },
                    child: PulseMarker(
                      color: NeuColors.accentOrange,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: NeuColors.surfaceDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: NeuColors.accentOrange, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${event.crossCount}",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Text(
                              "Kesişme",
                              style: TextStyle(color: NeuColors.accentOrange, fontSize: 7, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                    onMapReady: () {
                      _isMapReady = true;
                      if (_gpsAktif && !_isFirstLocationCentered) {
                        _isFirstLocationCentered = true;
                        _mapController.move(_benimKonumum, 14.5);
                      }
                    },
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
                      userAgentPackageName: 'com.motoconnect.app',
                      maxNativeZoom: 16,
                    ),
                    MarkerLayer(markers: markerListesi),
                  ],
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
                                    "Radar: ${radardakiMotorcular.length} Sürücü",
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

                // SAĞ ALT: SÜRÜŞE BAŞLA & KONUMUMA ODAKLAN
                Positioned(
                  bottom: 24,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NeuIconButton(
                        icon: Icons.sports_motorsports,
                        iconColor: Colors.white,
                        color: NeuColors.accentOrange,
                        size: 52,
                        iconSize: 24,
                        tooltip: "Sürüşe Başla (Kayıt & SOS)",
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => RideRecordingScreen(user: widget.aktifKullanici),
                          ));
                        },
                      ),
                      const SizedBox(height: 16),
                      NeuIconButton(
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
                    ],
                  ),
                ),

              ],
            );
          },
        );
      },
    );
  }


}
