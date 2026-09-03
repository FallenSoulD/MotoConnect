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
import '../../services/weather_service.dart';
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
  StreamSubscription<Position>? _gpsStreamSub;
  DateTime? _lastGpsSyncTime;
  bool _isMapReady = false;
  bool _isFirstLocationCentered = false;
  
  // Crossed Paths State
  final Set<String> _recordedCrossedPaths = {};
  DateTime? _lastCrossedPathCheckTime;

  // New features
  double _currentSpeedKmH = 0.0;
  Timer? _weatherDebounce;

  @override
  void initState() {
    super.initState();
    _benimKonumum = widget.aktifKullanici.latLng;
    _startContinuousGpsStream();
  }

  @override
  void dispose() {
    _gpsStreamSub?.cancel();
    _weatherDebounce?.cancel();
    super.dispose();
  }

  Future<void> _startContinuousGpsStream() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _gpsAktif = false;
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
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _gpsAktif = false;
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
        });
      }
    }
  }

  void _handleNewPosition(Position position) {
    if (!mounted) return;
    final double speedKmH = (position.speed * 3.6).clamp(0.0, 300.0);
    setState(() {
      _currentSpeedKmH = speedKmH;
      _benimKonumum = LatLng(position.latitude, position.longitude);
      widget.aktifKullanici.latitude = position.latitude;
      widget.aktifKullanici.longitude = position.longitude;
      _gpsAktif = true;
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
            locationName: widget.aktifKullanici.locationName.isNotEmpty ? widget.aktifKullanici.locationName : "Yakınından Geçti",
            distanceKm: dist / 1000.0,
            latitude: _benimKonumum.latitude,
            longitude: _benimKonumum.longitude,
          );
          // Karşı tarafın swipe ekranına da düşmek için karşı taraf için de kaydedelim
          await FirestoreService().recordCrossedPath(
            currentUserId: rider.id,
            otherUser: widget.aktifKullanici,
            locationName: rider.locationName.isNotEmpty ? rider.locationName : "Yakınından Geçti",
            distanceKm: dist / 1000.0,
            latitude: rider.latitude!,
            longitude: rider.longitude!,
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
    return GestureDetector(
      onTap: () {
        SosSheet.showSosDetails(
          context,
          alert: sos,
          currentUser: widget.aktifKullanici,
        );
      },
      child: PulseMarker(
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

            // 2. Çevredeki Filtrelenmiş Denk Gelişler (Grid / Modular Bölgesel Kümeleme)
            final Map<String, List<CrossedPathEvent>> groupedPaths = {};
            for (var event in radardakiMotorcular) {
              final lat = event.latitude ?? event.rider.latLng.latitude;
              final lng = event.longitude ?? event.rider.latLng.longitude;
              
              // 0.015 hassasiyet yaklaşık 1.5 - 2 km'lik grid'ler (bölgeler) oluşturur
              final latKey = (lat / 0.015).round() * 0.015;
              final lngKey = (lng / 0.015).round() * 0.015;
              final key = "${latKey.toStringAsFixed(3)}_${lngKey.toStringAsFixed(3)}";

              if (!groupedPaths.containsKey(key)) {
                groupedPaths[key] = [];
              }
              groupedPaths[key]!.add(event);
            }

            for (var entry in groupedPaths.entries) {
              final count = entry.value.length; 
              final firstEvent = entry.value.first;
              
              final clusterLat = firstEvent.latitude ?? firstEvent.rider.latLng.latitude;
              final clusterLng = firstEvent.longitude ?? firstEvent.rider.latLng.longitude;
              final clusterPoint = LatLng(clusterLat, clusterLng);

              markerListesi.add(
                Marker(
                  point: clusterPoint, 
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CrossedPathsScreen(
                            currentUser: widget.aktifKullanici,
                            filteredEvents: entry.value,
                          ),
                        ),
                      );
                    },
                    child: PulseMarker(
                      color: NeuColors.accentOrange,
                      child: Container(
                        decoration: BoxDecoration(
                          color: NeuColors.surfaceDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: NeuColors.accentOrange, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: NeuColors.accentOrange.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "$count",
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.w900, 
                              fontSize: 18,
                            ),
                          ),
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
                    onPositionChanged: (MapCamera position, bool hasGesture) {
                      if (hasGesture) {
                        if (_weatherDebounce?.isActive ?? false) _weatherDebounce!.cancel();
                        _weatherDebounce = Timer(const Duration(milliseconds: 1500), () {
                          // Kullanıcı haritayı kaydırdıktan 1.5 saniye sonra o noktanın havasını çek
                          MotoWeatherService().fetchWeather(
                            lat: position.center.latitude,
                            lng: position.center.longitude,
                          );
                        });
                      }
                    },
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all, // Rotate aktif
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

                // SOL ORTA: HIZ GÖSTERGESİ (SPEEDOMETER)
                Positioned(
                  bottom: 120,
                  left: 16,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: NeuColors.surfaceDark.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _currentSpeedKmH > 100 ? Colors.redAccent : (_currentSpeedKmH > 50 ? Colors.amber : NeuColors.accentGreen),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _currentSpeedKmH > 100 ? Colors.redAccent.withValues(alpha: 0.5) : Colors.black54,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentSpeedKmH.toStringAsFixed(0),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: _currentSpeedKmH > 100 ? Colors.redAccent : Colors.black, blurRadius: 4),
                            ],
                          ),
                        ),
                        const Text(
                          "km/s",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
                        icon: Icons.explore_outlined,
                        iconColor: Colors.white,
                        color: Colors.blueAccent.withValues(alpha: 0.7),
                        size: 42,
                        iconSize: 20,
                        tooltip: "Pusula Sıfırla",
                        onPressed: () {
                          _mapController.rotate(0.0);
                        },
                      ),
                      const SizedBox(height: 12),
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
