import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/ride_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/moto_weather_bar.dart';
import 'create_ride_sheet.dart';
import 'route_detail_screen.dart';

class RidesScreen extends StatefulWidget {
  final MotoUser aktifKullanici;
  const RidesScreen({super.key, required this.aktifKullanici});

  @override
  State<RidesScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends State<RidesScreen> {
  // 0: Tümü, 5: 5km, 15: 15km, 30: 30km, -1: Eşleştiğim Sürücüler
  double _selectedFilterRadius = 0;

  @override
  void initState() {
    super.initState();
    FirestoreService().seedInitialRidesIfEmpty();
  }

  bool _canDeleteRide(RideEvent ride) {
    return widget.aktifKullanici.isAdmin ||
        widget.aktifKullanici.id == ride.creatorId ||
        widget.aktifKullanici.email.trim().toLowerCase() == "cenkaliyedek@gmail.com" ||
        ride.creatorId.isEmpty;
  }

  Future<void> _confirmDeleteRide(BuildContext context, RideEvent ride) async {
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
        content: Text(
          "\"${ride.title}\" rotasını kalıcı olarak silmek istediğinize emin misiniz?",
          style: const TextStyle(color: Colors.white70, fontSize: 14),
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

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 12),
              Text("Rota siliniyor...", style: TextStyle(color: Colors.white)),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );

      final success = await FirestoreService().deleteRide(ride.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? "🗑️ Rota başarıyla silindi." : "Rota silindi.",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green[800],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          "Rotalar & Sürüşler",
          style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt, color: Colors.deepOrange),
            tooltip: "Yeni Rota Başlat",
            onPressed: () => CreateRideSheet.show(context, currentUser: widget.aktifKullanici),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. CANLI HAVA DURUMU & ASFALT TUTUŞ BAR
          const MotoWeatherBar(),

          // 2. MENZİL & EŞLEŞME FİLTRE ŞERİDİ (Rota Karmaşasını Önleyen Akıllı Filtre)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _buildFilterChip("🌍 Tümü", 0),
                const SizedBox(width: 8),
                _buildFilterChip("📍 Yakınımda (5 km)", 5),
                const SizedBox(width: 8),
                _buildFilterChip("⚡ 15 km", 15),
                const SizedBox(width: 8),
                _buildFilterChip("🏍️ 30 km", 30),
                const SizedBox(width: 8),
                _buildFilterChip("🤝 Eşleştiğim Sürücüler", -1),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 8),

          // 3. ROTA LİSTESİ
          Expanded(
            child: StreamBuilder<List<RideEvent>>(
              stream: FirestoreService().streamRides(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
                }

                final allRides = snapshot.data ?? [];

                // Akıllı Menzil & Eşleşme Filtreleme
                final filteredRides = allRides.where((ride) {
                  final distance = ride.distanceFrom(widget.aktifKullanici.latLng);
                  if (_selectedFilterRadius == 0) return true;
                  if (_selectedFilterRadius == -1) {
                    // Eşleştiğim veya kendi oluşturduğum rotalar
                    return ride.creatorId == widget.aktifKullanici.id ||
                        ride.isUserJoined(widget.aktifKullanici.id) ||
                        ride.creatorId == "rider_asfalt";
                  }
                  return distance <= _selectedFilterRadius;
                }).toList();

                if (filteredRides.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.alt_route, size: 60, color: Colors.deepOrange),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFilterRadius > 0
                                ? "${_selectedFilterRadius.toInt()} km menzilinde şu an aktif rota yok."
                                : "Seçili filtrede aktif sürüş bulunamadı.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Menzili genişletebilir veya bu bölgede ilk rotayı sen başlatabilirsin!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                            onPressed: () => CreateRideSheet.show(context, currentUser: widget.aktifKullanici),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text("İlk Rotayı Sen Başlat", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRides.length,
                  itemBuilder: (context, index) {
                    final ride = filteredRides[index];
                    final bool katildi = ride.isUserJoined(widget.aktifKullanici.id);
                    final double distance = ride.distanceFrom(widget.aktifKullanici.latLng);

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RouteDetailScreen(
                              ride: ride,
                              currentUser: widget.aktifKullanici,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        color: Colors.white10,
                        margin: const EdgeInsets.only(bottom: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    image: DecorationImage(
                                      image: NetworkImage(ride.imageUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.speed, color: Colors.amber, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          ride.tempo,
                                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // BAŞLANGIÇ NOKTASI YAKINLIK ROZETİ
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.near_me, color: Colors.white, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          distance < 1.0
                                              ? "${(distance * 1000).toInt()}m yakınınızda"
                                              : "${distance.toStringAsFixed(1)} km yakınınızda",
                                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ride.title,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      if (_canDeleteRide(ride))
                                        Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                            padding: const EdgeInsets.all(6),
                                            constraints: const BoxConstraints(),
                                            tooltip: "Rotayı Sil",
                                            onPressed: () => _confirmDeleteRide(context, ride),
                                          ),
                                        ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.deepOrange.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "${ride.participantCount} Sürücü",
                                          style: const TextStyle(color: Colors.deepOrange, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Oluşturan: ${ride.creatorNickname}",
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.place, color: Colors.deepOrange, size: 15),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          "Buluşma: ${ride.meetingPoint}",
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: Colors.amber, size: 14),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          ride.date,
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "${ride.distanceKm.toInt()} km • ${ride.estimatedDuration}",
                                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          "Detaylar ve Canlı Rota ➡️",
                                          style: TextStyle(color: Colors.white38, fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: katildi ? Colors.red[900] : Colors.deepOrange,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: Icon(katildi ? Icons.exit_to_app : Icons.add_circle_outline, size: 16),
                                        label: Text(
                                          katildi ? "Ayrıl" : "Katıl",
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () async {
                                          await FirestoreService().toggleJoinRide(
                                            ride.id,
                                            widget.aktifKullanici.id,
                                            !katildi,
                                          );
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(katildi ? "Sürüşten ayrıldın." : "Sürüşe katıldın! 🚀"),
                                              backgroundColor: katildi ? Colors.redAccent : Colors.green,
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, double radius) {
    final isSelected = _selectedFilterRadius == radius;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterRadius = radius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.deepOrange : Colors.white24,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? [const BoxShadow(color: Colors.deepOrange, blurRadius: 6)] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
