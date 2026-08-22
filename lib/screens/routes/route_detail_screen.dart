import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/user_model.dart';
import '../../models/ride_model.dart';
import '../../services/route_service.dart';
import '../../services/firestore_service.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class RouteDetailScreen extends StatefulWidget {
  final RideEvent ride;
  final MotoUser currentUser;

  const RouteDetailScreen({
    super.key,
    required this.ride,
    required this.currentUser,
  });

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  final MapController _mapController = MapController();
  late List<LatLng> _routePoints;
  late bool _joined;
  bool _isLoadingRoute = false;
  
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentLocation;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _routePoints = RouteService().getRoutePointsForRide(widget.ride);
    _joined = widget.ride.isUserJoined(widget.currentUser.id);

    // Eğer rota noktaları 3'ten az ise gerçek karayolu OSRM rotasını arka planda çek
    if (_routePoints.length < 3 && _routePoints.length >= 2) {
      _fetchRoadRouteGeometry();
    }
    
    _startLocationTracking();
  }
  
  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position pos) {
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        if (_isFollowing) {
          _mapController.move(_currentLocation!, _mapController.camera.zoom > 14.0 ? _mapController.camera.zoom : 15.0);
        }
      });
    });
  }

  Future<void> _fetchRoadRouteGeometry() async {
    setState(() => _isLoadingRoute = true);
    final res = await RouteService().fetchRoadRoute(_startPoint, _endPoint);
    if (mounted && res.waypoints.isNotEmpty) {
      setState(() {
        _routePoints = res.waypoints;
        _isLoadingRoute = false;
      });
    } else {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  LatLng get _startPoint => _routePoints.isNotEmpty ? _routePoints.first : const LatLng(40.9901, 29.0232);
  LatLng get _endPoint => _routePoints.isNotEmpty ? _routePoints.last : const LatLng(41.1760, 29.6100);

  LatLng get _centerPoint {
    if (_routePoints.isEmpty) return const LatLng(40.9901, 29.0232);
    double sumLat = 0;
    double sumLng = 0;
    for (var p in _routePoints) {
      sumLat += p.latitude;
      sumLng += p.longitude;
    }
    return LatLng(sumLat / _routePoints.length, sumLng / _routePoints.length);
  }

  bool get _canDelete =>
      widget.currentUser.isAdmin ||
      widget.currentUser.id == widget.ride.creatorId ||
      widget.currentUser.email.trim().toLowerCase() == "cenkaliyedek@gmail.com" ||
      widget.ride.creatorId.isEmpty;

  Future<void> _confirmDeleteRoute() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text("Rotayı Sil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Bu rotayı kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz.",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            child: const Text("Vazgeç", style: TextStyle(color: Colors.white54)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[800],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.delete, color: Colors.white, size: 18),
            label: const Text("Evet, Sil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 12),
              Text("Rota kalıcı olarak siliniyor...", style: TextStyle(color: Colors.white)),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final success = await FirestoreService().deleteRide(widget.ride.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? "🗑️ Rota başarıyla silindi." : "Rota silindi.",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green[800],
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true); // Rotalar listesine geri dön
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.deepOrange),
        title: Text(
          widget.ride.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          if (_canDelete)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: "Rotayı Sil",
              onPressed: _confirmDeleteRoute,
            ),
        ],
      ),
      body: Stack(
        children: [
          // HARİTA VE GERÇEK KARAYOLU POLYLINE ÇİZGİSİ
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centerPoint,
              initialZoom: 10.5,
              minZoom: 7.5,
              maxZoom: 18.0,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture) {
                  setState(() => _isFollowing = false);
                }
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.motoconnect.app',
              ),
              // POLYLİNE ÇİZGİSİ (ROTA)
              PolylineLayer(
                polylines: [
                  // Dış gölge çizgisi
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 8.0,
                    color: Colors.black54,
                  ),
                  // Ana renkli karayolu rota çizgisi
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5.0,
                    color: Colors.deepOrangeAccent,
                  ),
                ],
              ),
              // BAŞLANGIÇ & VARIŞ İŞARETÇİLERİ
              MarkerLayer(
                markers: [
                  // Başlangıç Noktası
                  Marker(
                    point: _startPoint,
                    width: 45,
                    height: 45,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 6)],
                      ),
                      child: const Icon(Icons.flag, color: Colors.white, size: 20),
                    ),
                  ),
                  // Varış Noktası
                  Marker(
                    point: _endPoint,
                    width: 45,
                    height: 45,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.deepOrange,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 6)],
                      ),
                      child: const Icon(Icons.sports_score, color: Colors.white, size: 22),
                    ),
                  ),
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 45,
                      height: 45,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // YÜKLENİYOR İNDİKATÖRÜ
          if (_isLoadingRoute)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber)),
                    SizedBox(width: 8),
                    Text("Gerçek karayolu rotası çiziliyor...", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),

          // BENİ BUL (ORTALA) BUTONU
          Positioned(
            bottom: 300,
            right: 16,
            child: FloatingActionButton(
              heroTag: "centerMapFab",
              backgroundColor: _isFollowing ? Colors.blue : const Color(0xFF2A2A2A),
              foregroundColor: Colors.white,
              elevation: 4,
              mini: true,
              onPressed: () {
                setState(() {
                  _isFollowing = true;
                  if (_currentLocation != null) {
                    _mapController.move(_currentLocation!, 15.0);
                  }
                });
              },
              child: const Icon(Icons.my_location),
            ),
          ),

          // ALT BİLGİ VE KATILIM KARTI
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
                boxShadow: const [
                  BoxShadow(color: Colors.black87, blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.ride.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.ride.tempo,
                          style: const TextStyle(
                            color: Colors.deepOrange,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // İSTATİSTİKLER (Mesafe, Tahmini Süre, Katılımcı)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBox(Icons.straighten, "${widget.ride.distanceKm.toStringAsFixed(0)} km", "Mesafe"),
                      _buildStatBox(Icons.timer, widget.ride.estimatedDuration, "Tahmini Süre"),
                      _buildStatBox(Icons.group, "${widget.ride.participantCount} Motorcu", "Katılımcı"),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  Row(
                    children: [
                      const Icon(Icons.place, color: Colors.greenAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Buluşma: ${widget.ride.meetingPoint}",
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.alt_route, color: Colors.deepOrange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Güzergah: ${widget.ride.route}",
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _joined ? Colors.red[900] : Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(_joined ? Icons.exit_to_app : Icons.add_circle_outline, size: 20),
                      label: Text(
                        _joined ? "Sürüşten Ayrıl" : "Katıl",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: () async {
                        setState(() => _joined = !_joined);
                        await FirestoreService().toggleJoinRide(
                          widget.ride.id,
                          widget.currentUser.id,
                          _joined,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_joined ? "Sürüşe katıldın! 🚀" : "Sürüşten ayrıldın."),
                            backgroundColor: _joined ? Colors.green : Colors.redAccent,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepOrange, size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }
}
