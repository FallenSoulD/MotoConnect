import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/user_model.dart';
import '../../models/ride_model.dart';
import '../../services/firestore_service.dart';
import '../../services/route_service.dart';
import '../../widgets/neumorphic_widgets.dart';
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
              backgroundColor: NeuColors.background,
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
                          NeuContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            borderRadius: 20,
                            color: Colors.black87,
                            borderColor: isStart ? NeuColors.accentGreen : NeuColors.accentOrange,
                            borderWidth: 1.5,
                            child: Text(
                              isStart ? "🟢 Buluşma Noktası" : "🏁 Varış Noktası",
                              style: TextStyle(
                                color: isStart ? NeuColors.accentGreen : NeuColors.accentOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            Icons.location_pin,
                            size: 48,
                            color: isStart ? NeuColors.accentGreen : NeuColors.accentOrange,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Üst Bilgilendirme ve Arama Çubuğu
                  Positioned(
                    top: 40,
                    left: 16,
                    right: 16,
                    child: Column(
                      children: [
                        NeuContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          borderRadius: 16,
                          child: Row(
                            children: [
                              NeuIconButton(
                                icon: Icons.arrow_back,
                                size: 36,
                                iconSize: 18,
                                onPressed: () => Navigator.pop(dialogCtx),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: const InputDecoration(
                                    hintText: "Adres, cadde veya mekan ara...",
                                    hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (val) async {
                                    if (val.trim().isEmpty) return;
                                    setDialogState(() => isSearching = true);
                                    final found = await searchAddress(val.trim());
                                    setDialogState(() => isSearching = false);
                                    if (found != null) {
                                      pickerMapController.move(found, 14.5);
                                      setDialogState(() => tempCenter = found);
                                    }
                                  },
                                ),
                              ),
                              if (isSearching)
                                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: NeuColors.accentOrange))
                              else
                                NeuIconButton(
                                  icon: Icons.search,
                                  size: 36,
                                  iconSize: 18,
                                  iconColor: NeuColors.accentOrange,
                                  onPressed: () async {
                                    if (searchController.text.trim().isEmpty) return;
                                    setDialogState(() => isSearching = true);
                                    final found = await searchAddress(searchController.text.trim());
                                    setDialogState(() => isSearching = false);
                                    if (found != null) {
                                      pickerMapController.move(found, 14.5);
                                      setDialogState(() => tempCenter = found);
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Alt Onay Butonu
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: NeuButton(
                      text: "Bu Konumu Seç (${tempCenter.latitude.toStringAsFixed(3)}, ${tempCenter.longitude.toStringAsFixed(3)})",
                      icon: Icons.check,
                      isPrimary: true,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      onPressed: () {
                        onLocationPicked(tempCenter, "${tempCenter.latitude.toStringAsFixed(2)}, ${tempCenter.longitude.toStringAsFixed(2)}");
                        Navigator.pop(dialogCtx);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    void recalculateRoute(StateSetter setModalState) async {
      if (startPoint != null && endPoint != null) {
        setModalState(() => isCalculatingRoute = true);
        final routeRes = await RouteService().fetchRoadRoute(startPoint!, endPoint!);
        setModalState(() {
          currentPolyline = routeRes.waypoints;
          calculatedKm = routeRes.distanceKm;
          calculatedDuration = routeRes.durationText;
          isCalculatingRoute = false;
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.90,
              maxChildSize: 0.96,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return NeuContainer(
                  borderRadius: 28,
                  color: NeuColors.surfaceDark,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    left: 20,
                    right: 20,
                    top: 16,
                  ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // BAŞLIK
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.alt_route, color: NeuColors.accentOrange, size: 24),
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
                          NeuIconButton(
                            icon: Icons.close,
                            size: 36,
                            iconSize: 18,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ================= 1. BÖLÜM: BULUŞMA NOKTASI =================
                      NeuContainer(
                        padding: const EdgeInsets.all(14),
                        borderRadius: 18,
                        borderColor: startPoint != null ? NeuColors.accentGreen : Colors.white.withValues(alpha: 0.05),
                        borderWidth: startPoint != null ? 1.5 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.trip_origin, color: NeuColors.accentGreen, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      "1. Buluşma Noktası",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                    ),
                                  ],
                                ),
                                if (startPoint != null)
                                  const NeuBadge(text: "SEÇİLDİ ✅", color: NeuColors.accentGreen, fontSize: 10),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Haritadan Seç Butonu
                            NeuButton(
                              text: startPoint != null ? "📍 Buluşma Konumunu Değiştir" : "🗺️ Haritadan Buluşma Konumu Seç",
                              icon: Icons.map,
                              color: startPoint != null ? Colors.green[900] : NeuColors.surface,
                              textColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
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

                            const SizedBox(height: 10),
                            NeuTextField(
                              controller: bulusmaController,
                              labelText: 'Buluşma Noktası Konumu / Adresi',
                              hintText: 'Örn: Kadıköy Rıhtım İskelesi / Shell Benzinlik',
                              prefixIcon: Icons.place,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ================= 2. BÖLÜM: VARIŞ NOKTASI =================
                      NeuContainer(
                        padding: const EdgeInsets.all(14),
                        borderRadius: 18,
                        borderColor: endPoint != null ? NeuColors.accentOrange : Colors.white.withValues(alpha: 0.05),
                        borderWidth: endPoint != null ? 1.5 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.flag, color: NeuColors.accentOrange, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      "2. Varış Noktası",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                    ),
                                  ],
                                ),
                                if (endPoint != null)
                                  const NeuBadge(text: "SEÇİLDİ ✅", color: NeuColors.accentOrange, fontSize: 10),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Haritadan Seç Butonu
                            NeuButton(
                              text: endPoint != null ? "🏁 Varış Konumunu Değiştir" : "🗺️ Haritadan Varış Konumu Seç",
                              icon: Icons.map,
                              color: endPoint != null ? Colors.deepOrange[900] : NeuColors.surface,
                              textColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
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

                            const SizedBox(height: 10),
                            NeuTextField(
                              controller: varisController,
                              labelText: 'Varış Noktası Konumu / Adresi',
                              hintText: 'Örn: Şile Sahil / Riva Kalesi',
                              prefixIcon: Icons.navigation,
                            ),
                          ],
                        ),
                      ),

                      // ROTA HESAPLAMA VE MESAFE GÖSTERGESİ
                      if (startPoint != null && endPoint != null) ...[
                        const SizedBox(height: 14),
                        NeuContainer(
                          padding: const EdgeInsets.all(14),
                          borderRadius: 16,
                          borderColor: NeuColors.accentAmber.withValues(alpha: 0.4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.route, color: NeuColors.accentAmber, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "Gerçek Karayolu Mesafesi",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              if (isCalculatingRoute)
                                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: NeuColors.accentAmber, strokeWidth: 2))
                              else
                                Text(
                                  "🛣️ $calculatedKm km • ⏱️ $calculatedDuration",
                                  style: const TextStyle(color: NeuColors.accentAmber, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // SÜRÜŞ BİLGİLERİ ALANLARI
                      NeuTextField(
                        controller: baslikController,
                        labelText: 'Sürüş Başlığı',
                        hintText: 'Örn: Pazar Viraj & Kahve Turu',
                        prefixIcon: Icons.title,
                      ),
                      const SizedBox(height: 12),
                      // 15 Dakika Bilgi Kartı
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.blueAccent, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Oluşturacağınız rota tam 15 dakika sonra başlayacaktır. Katılımcıların başlangıç noktasına gelmesi için 15 dakikası vardır.",
                                style: TextStyle(color: Colors.white, fontSize: 11.5, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Sürüş Temposu
                      const Text(
                        "Sürüş Temposu:",
                        style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.bold),
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
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.timer_outlined, color: Colors.amber, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Rotalar oluşturulduktan sonra maksimum 15 dakika aktif kalır ve ardından otomatik temizlenir.",
                                style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // SÜRÜŞÜ BAŞLAT BUTONU
                      NeuButton(
                        text: 'Rotayı Paylaş & Sürüşü Başlat',
                        icon: Icons.rocket_launch,
                        isPrimary: true,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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

                          final baslamaZamani = DateTime.now().add(const Duration(minutes: 15));
                          final formattedDate = "${baslamaZamani.day.toString().padLeft(2, '0')}.${baslamaZamani.month.toString().padLeft(2, '0')}.${baslamaZamani.year} ${baslamaZamani.hour.toString().padLeft(2, '0')}:${baslamaZamani.minute.toString().padLeft(2, '0')}";

                          final yeniSurus = RideEvent(
                            id: 'ride_${DateTime.now().millisecondsSinceEpoch}',
                            title: baslikController.text.trim(),
                            date: formattedDate,
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

                          _lastRouteCreationTime = DateTime.now();

                          if (!context.mounted) return;
                          Navigator.pop(context);

                          await FirestoreService().createRide(yeniSurus);

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
                      ),
                    ],
                  ),
                );
              },
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
        child: NeuContainer(
          padding: const EdgeInsets.symmetric(vertical: 8),
          borderRadius: 12,
          style: isSelected ? NeuStyle.sunken : NeuStyle.raised,
          color: isSelected ? NeuColors.accentOrange.withValues(alpha: 0.2) : NeuColors.surface,
          borderColor: isSelected ? NeuColors.accentOrange : Colors.white.withValues(alpha: 0.05),
          borderWidth: isSelected ? 1.5 : 1,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? NeuColors.accentOrange : Colors.white70,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
