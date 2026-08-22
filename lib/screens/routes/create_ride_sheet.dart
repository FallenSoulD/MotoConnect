import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/user_model.dart';
import '../../models/ride_model.dart';
import '../../services/firestore_service.dart';
import '../../services/route_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateRideSheet {
  static DateTime? _lastRouteCreationTime;

  static void show(BuildContext context, {required MotoUser currentUser}) {
    // 5 DAKİKALIK SPAM KONTROLÜ
    if (_lastRouteCreationTime != null) {
      final difference = DateTime.now().difference(_lastRouteCreationTime!);
      if (difference < const Duration(minutes: 5)) {
        final remainingMinutes = 5 - difference.inMinutes;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.timer, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "⏳ Spam koruması: Yeni rota oluşturmak için lütfen $remainingMinutes dakika bekleyin.",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.amber[800],
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    final baslikController = TextEditingController();
    final tarihController = TextEditingController(text: "Hafta Sonu, 09:30");
    final bulusmaController = TextEditingController();
    final varisController = TextEditingController();
    String seciliTempo = "Sakin & Manzaralı";

    LatLng? startPoint;
    LatLng? endPoint;

    List<LatLng> currentPolyline = [];
    double calculatedKm = 0;
    String calculatedDuration = "—";
    bool isCalculatingRoute = false;

    // Harita Konumu Seçici Tam Ekran / Dialog Açıcı
    void pickLocationOnMap({
      required BuildContext parentContext,
      required bool isStart,
      required LatLng? currentSelected,
      required Function(LatLng, String) onLocationPicked,
    }) {
      LatLng tempCenter = currentSelected ?? const LatLng(41.0082, 28.9784);
      final pickerMapController = MapController();
      final searchController = TextEditingController();
      bool isSearching = false;

      Future<LatLng?> searchAddress(String query) async {
        try {
          final uri = Uri.parse("https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1");
          final response = await http.get(uri, headers: {
            'User-Agent': 'MotoConnectApp/1.0'
          });
          if (response.statusCode == 200) {
            final List data = json.decode(response.body);
            if (data.isNotEmpty) {
              final lat = double.tryParse(data[0]['lat'] ?? '');
              final lon = double.tryParse(data[0]['lon'] ?? '');
              if (lat != null && lon != null) {
                return LatLng(lat, lon);
              }
            }
          }
        } catch (e) {
          debugPrint("Geocoding HTTP error: $e");
        }
        return null;
      }

      showDialog(
        context: parentContext,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog.fullscreen(
              backgroundColor: const Color(0xFF141414),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: pickerMapController,
                    options: MapOptions(
                      initialCenter: tempCenter,
                      initialZoom: 12.5,
                      minZoom: 8.0,
                      maxZoom: 18.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onPositionChanged: (pos, hasGesture) {
                        if (hasGesture) {
                          setDialogState(() {
                            tempCenter = pos.center;
                          });
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.motoconnect.app',
                      ),
                    ],
                  ),

                  // Ortadaki Sabit Hedef Pin (Crosshair)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 36),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isStart ? Colors.greenAccent : Colors.deepOrange,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              isStart ? "🟢 Buluşma Noktası" : "🏁 Varış Noktası",
                              style: TextStyle(
                                color: isStart ? Colors.greenAccent : Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            isStart ? Icons.location_on : Icons.flag,
                            size: 48,
                            color: isStart ? Colors.greenAccent : Colors.deepOrange,
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 12),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Üst Başlık, Arama Barı & Kapat Butonu
                  Positioned(
                    top: MediaQuery.of(ctx).padding.top + 10,
                    left: 16,
                    right: 16,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24),
                            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isStart ? Icons.trip_origin : Icons.flag,
                                    color: isStart ? Colors.greenAccent : Colors.deepOrange,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isStart ? "1. Buluşma Konumunu Seç" : "2. Varış Konumunu Seç",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.pop(dialogCtx),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Arama Çubuğu
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
                          ),
                          child: TextField(
                            controller: searchController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: isStart ? "Buluşma noktası ara..." : "Varış noktası ara...",
                              hintStyle: const TextStyle(color: Colors.white54),
                              prefixIcon: const Icon(Icons.search, color: Colors.white54),
                              suffixIcon: isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.check_circle, color: Colors.amber),
                                      onPressed: () async {
                                        if (searchController.text.trim().isEmpty) return;
                                        setDialogState(() => isSearching = true);
                                        try {
                                          final newPos = await searchAddress(searchController.text.trim());
                                          if (newPos != null) {
                                            pickerMapController.move(newPos, 14.0);
                                            setDialogState(() => tempCenter = newPos);
                                          } else {
                                            throw Exception("Bulunamadı");
                                          }
                                        } catch (e) {
                                          if (parentContext.mounted) {
                                            ScaffoldMessenger.of(parentContext).showSnackBar(
                                              const SnackBar(content: Text("Konum bulunamadı!"), backgroundColor: Colors.red),
                                            );
                                          }
                                        } finally {
                                          setDialogState(() => isSearching = false);
                                        }
                                      },
                                    ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onSubmitted: (val) async {
                              if (val.trim().isEmpty) return;
                              setDialogState(() => isSearching = true);
                              try {
                                final newPos = await searchAddress(val.trim());
                                if (newPos != null) {
                                  pickerMapController.move(newPos, 14.0);
                                  setDialogState(() => tempCenter = newPos);
                                } else {
                                  throw Exception("Bulunamadı");
                                }
                              } catch (e) {
                                if (parentContext.mounted) {
                                  ScaffoldMessenger.of(parentContext).showSnackBar(
                                    const SnackBar(content: Text("Konum bulunamadı!"), backgroundColor: Colors.red),
                                  );
                                }
                              } finally {
                                setDialogState(() => isSearching = false);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hızlı Semt Seçimleri
                  Positioned(
                    bottom: 90,
                    left: 12,
                    right: 12,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: (isStart
                            ? [
                                {"name": "Kadıköy Rıhtım", "lat": 40.9901, "lng": 29.0232},
                                {"name": "Beşiktaş Meydan", "lat": 41.0420, "lng": 29.0080},
                                {"name": "Ataşehir Shell", "lat": 40.9850, "lng": 29.1120},
                                {"name": "Üsküdar Sahil", "lat": 41.0260, "lng": 29.0150},
                              ]
                            : [
                                {"name": "Şile Liman", "lat": 41.1760, "lng": 29.6100},
                                {"name": "Riva Sahil", "lat": 41.2250, "lng": 29.2190},
                                {"name": "Körfez Pisti", "lat": 40.7600, "lng": 29.7400},
                                {"name": "Darlık Barajı", "lat": 41.1020, "lng": 29.5800},
                              ]).map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A2A2A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(color: isStart ? Colors.greenAccent.withValues(alpha: 0.4) : Colors.deepOrange.withValues(alpha: 0.4)),
                              ),
                              icon: Icon(Icons.place, size: 14, color: isStart ? Colors.greenAccent : Colors.deepOrange),
                              label: Text(item["name"] as String, style: const TextStyle(fontSize: 12)),
                              onPressed: () {
                                final pos = LatLng(item["lat"] as double, item["lng"] as double);
                                pickerMapController.move(pos, 14.0);
                                setDialogState(() {
                                  tempCenter = pos;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Alt Onay Butonu
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isStart ? Colors.green[800] : Colors.deepOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 6,
                        ),
                        icon: const Icon(Icons.check_circle, size: 22),
                        label: Text(
                          isStart ? "✅ Bu Noktayı Buluşma Konumu Yap" : "✅ Bu Noktayı Varış Konumu Yap",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: () async {
                          final defaultName = searchController.text.trim().isNotEmpty
                              ? searchController.text.trim()
                              : "${tempCenter.latitude.toStringAsFixed(3)}, ${tempCenter.longitude.toStringAsFixed(3)}";
                              
                          onLocationPicked(tempCenter, defaultName);
                          Navigator.pop(dialogCtx);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    void recalculateRoute(Function setModalState) async {
      if (startPoint == null || endPoint == null) return;
      setModalState(() => isCalculatingRoute = true);
      final result = await RouteService().fetchRoadRoute(startPoint!, endPoint!);
      setModalState(() {
        currentPolyline = result.waypoints;
        calculatedKm = result.distanceKm;
        calculatedDuration = result.durationText;
        isCalculatingRoute = false;
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BAŞLIK
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.alt_route, color: Colors.deepOrange, size: 26),
                            SizedBox(width: 10),
                            Text(
                              'Yeni Rota & Sürüş Başlat',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ================= 1. BÖLÜM: BULUŞMA NOKTASI =================
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF262626),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: startPoint != null ? Colors.greenAccent : Colors.white12,
                          width: startPoint != null ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.trip_origin, color: Colors.greenAccent, size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "1. Buluşma Noktası",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              if (startPoint != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text("SEÇİLDİ ✅", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Haritadan Seç Butonu
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: startPoint != null ? Colors.green[900] : const Color(0xFF3A3A3A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.map, size: 18, color: Colors.greenAccent),
                              label: Text(
                                startPoint != null ? "📍 Buluşma Konumunu Değiştir" : "🗺️ Haritadan Buluşma Konumu Seç",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              onPressed: () {
                                pickLocationOnMap(
                                  parentContext: context,
                                  isStart: true,
                                  currentSelected: startPoint,
                                  onLocationPicked: (pos, defaultName) {
                                    setModalState(() {
                                      startPoint = pos;
                                      if (bulusmaController.text.trim().isEmpty) {
                                        bulusmaController.text = "Buluşma Noktası ($defaultName)";
                                      }
                                    });
                                    recalculateRoute(setModalState);
                                  },
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 10),
                          TextField(
                            controller: bulusmaController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Buluşma Noktası Konumu / Adresi',
                              hintText: 'Örn: Kadıköy Rıhtım İskelesi / Shell Benzinlik',
                              hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                              labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                              prefixIcon: const Icon(Icons.place, color: Colors.greenAccent, size: 18),
                              filled: true,
                              fillColor: Colors.black26,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ================= 2. BÖLÜM: VARIŞ NOKTASI =================
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF262626),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: endPoint != null ? Colors.deepOrange : Colors.white12,
                          width: endPoint != null ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.flag, color: Colors.deepOrange, size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "2. Varış Noktası",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              if (endPoint != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text("SEÇİLDİ ✅", style: TextStyle(color: Colors.deepOrange, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Haritadan Seç Butonu
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: endPoint != null ? Colors.deepOrange[900] : const Color(0xFF3A3A3A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.map, size: 18, color: Colors.deepOrange),
                              label: Text(
                                endPoint != null ? "🏁 Varış Konumunu Değiştir" : "🗺️ Haritadan Varış Konumu Seç",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              onPressed: () {
                                pickLocationOnMap(
                                  parentContext: context,
                                  isStart: false,
                                  currentSelected: endPoint,
                                  onLocationPicked: (pos, defaultName) {
                                    setModalState(() {
                                      endPoint = pos;
                                      if (varisController.text.trim().isEmpty) {
                                        varisController.text = "Varış Noktası ($defaultName)";
                                      }
                                    });
                                    recalculateRoute(setModalState);
                                  },
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 10),
                          TextField(
                            controller: varisController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Varış Noktası Konumu / Adresi',
                              hintText: 'Örn: Şile Sahil / Riva Kalesi',
                              hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                              labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                              prefixIcon: const Icon(Icons.navigation, color: Colors.deepOrange, size: 18),
                              filled: true,
                              fillColor: Colors.black26,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ROTA HESAPLAMA VE MESAFE GÖSTERGESİ
                    if (startPoint != null && endPoint != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.route, color: Colors.amber, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "Gerçek Karayolu Mesafesi",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            if (isCalculatingRoute)
                              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2))
                            else
                              Text(
                                "🛣️ $calculatedKm km • ⏱️ $calculatedDuration",
                                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // SÜRÜŞ BİLGİLERİ ALANLARI
                    TextField(
                      controller: baslikController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Sürüş Başlığı (Örn: Pazar Viraj & Kahve Turu)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.title, color: Colors.deepOrange),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.deepOrange),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tarihController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Tarih ve Saat (Örn: Pazar, 09:30)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.access_time, color: Colors.deepOrange),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.deepOrange),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Sürüş Temposu
                    const Text(
                      "Sürüş Temposu:",
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTempoChip("Sakin & Manzaralı", seciliTempo, (val) => setModalState(() => seciliTempo = val)),
                        const SizedBox(width: 8),
                        _buildTempoChip("Orta & Akıcı", seciliTempo, (val) => setModalState(() => seciliTempo = val)),
                        const SizedBox(width: 8),
                        _buildTempoChip("Hızlı / Sportif ⚡", seciliTempo, (val) => setModalState(() => seciliTempo = val)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // SÜRÜŞÜ BAŞLAT BUTONU
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                        ),
                        onPressed: () async {
                          if (startPoint == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("⚠️ Lütfen 1. Buluşma Noktasını haritadan seçin!"),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          if (endPoint == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("⚠️ Lütfen 2. Varış Noktasını haritadan seçin!"),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          if (baslikController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Lütfen sürüş başlığını yazın!"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          List<LatLng> finalWaypoints = currentPolyline;
                          if (finalWaypoints.isEmpty || finalWaypoints.length < 2) {
                            final routeRes = await RouteService().fetchRoadRoute(startPoint!, endPoint!);
                            finalWaypoints = routeRes.waypoints;
                            calculatedKm = routeRes.distanceKm;
                            calculatedDuration = routeRes.durationText;
                          }

                          final bulusmaAdi = bulusmaController.text.trim().isNotEmpty
                              ? bulusmaController.text.trim()
                              : "Buluşma Noktası (${startPoint!.latitude.toStringAsFixed(2)}, ${startPoint!.longitude.toStringAsFixed(2)})";

                          final varisAdi = varisController.text.trim().isNotEmpty
                              ? varisController.text.trim()
                              : "Varış Noktası (${endPoint!.latitude.toStringAsFixed(2)}, ${endPoint!.longitude.toStringAsFixed(2)})";

                          final yeniSurus = RideEvent(
                            id: 'ride_${DateTime.now().millisecondsSinceEpoch}',
                            title: baslikController.text.trim(),
                            date: tarihController.text.trim(),
                            meetingPoint: bulusmaAdi,
                            route: "$bulusmaAdi -> $varisAdi",
                            tempo: seciliTempo,
                            imageUrl: "https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800",
                            creatorId: currentUser.id,
                            creatorNickname: currentUser.nickname,
                            participantIds: [currentUser.id],
                            distanceKm: calculatedKm,
                            estimatedDuration: calculatedDuration,
                            waypoints: finalWaypoints,
                          );

                          // 1. Spam sayacı
                          _lastRouteCreationTime = DateTime.now();

                          // 2. Paneli kapat
                          if (!context.mounted) return;
                          Navigator.pop(context);

                          // 3. Veritabanına kaydet
                          await FirestoreService().createRide(yeniSurus);

                          // 4. Başarı bildirimi
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "🗺️ $calculatedKm km Gerçek Karayolu Rotası Oluşturuldu! 🚀",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        },
                        child: const Text(
                          'Rotayı Paylaş & Sürüşü Başlat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  static Widget _buildTempoChip(String title, String selected, Function(String) onSelect) {
    final isSelected = selected == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepOrange : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? Colors.deepOrangeAccent : Colors.white24),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

