import 'package:flutter/material.dart';
import '../garage/saved_routes_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../models/user_model.dart';
import '../../models/ride_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/moto_weather_bar.dart';
import '../../widgets/neumorphic_widgets.dart';
import '../../widgets/native_ad_widget.dart';
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
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: NeuContainer(
          padding: const EdgeInsets.all(22),
          borderRadius: 22,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.delete_forever, color: Colors.redAccent, size: 26),
                  SizedBox(width: 10),
                  Text("Rotayı Sil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                "\"${ride.title}\" rotasını kalıcı olarak silmek istediğinize emin misiniz?",
                style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: NeuButton(
                      text: "Vazgeç",
                      color: NeuColors.surfaceDark,
                      textColor: Colors.white60,
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeuButton(
                      text: "Evet, Sil",
                      color: Colors.red[800],
                      textColor: Colors.white,
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: NeuColors.background,
        appBar: AppBar(
          backgroundColor: NeuColors.surfaceDark,
          title: const Row(
            children: [
              Icon(Icons.alt_route, color: NeuColors.accentOrange, size: 22),
              SizedBox(width: 8),
              Text(
                "Rotalar & Sürüşler",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          actions: [
            NeuIconButton(
              icon: Icons.add_location_alt,
              iconColor: NeuColors.accentOrange,
              size: 40,
              iconSize: 20,
              tooltip: "Yeni Rota Başlat",
              onPressed: () => CreateRideSheet.show(context, currentUser: widget.aktifKullanici),
            ),
            const SizedBox(width: 12),
          ],
          bottom: const TabBar(
            indicatorColor: NeuColors.accentOrange,
            labelColor: NeuColors.accentOrange,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: "Keşfet"),
              Tab(text: "Benim Rotalarım"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Column(
        children: [
          // 1. CANLI HAVA DURUMU & ASFALT TUTUŞ BAR
          const MotoWeatherBar(),

          // 2. MENZİL & EŞLEŞME FİLTRE ŞERİDİ
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 6),
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

          const Divider(height: 12),

          // 3. ROTA LİSTESİ
          Expanded(
            child: StreamBuilder<List<RideEvent>>(
              stream: FirestoreService().streamRides(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: NeuColors.accentOrange));
                }

                final allRides = snapshot.data ?? [];

                final filteredRides = allRides.where((ride) {
                  final distance = ride.distanceFrom(widget.aktifKullanici.latLng);
                  if (_selectedFilterRadius == 0) return true;
                  if (_selectedFilterRadius == -1) {
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
                          NeuContainer(
                            padding: const EdgeInsets.all(22),
                            borderRadius: 36,
                            depth: 4,
                            child: const Icon(Icons.alt_route, size: 56, color: NeuColors.accentOrange),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _selectedFilterRadius > 0
                                ? "${_selectedFilterRadius.toInt()} km menzilinde şu an aktif rota yok."
                                : "Seçili filtrede aktif sürüş bulunamadı.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Menzili genişletebilir veya bu bölgede ilk rotayı sen başlatabilirsin!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 12.5),
                          ),
                          const SizedBox(height: 20),
                          NeuButton(
                            text: "İlk Rotayı Sen Başlat",
                            icon: Icons.add,
                            isPrimary: true,
                            onPressed: () => CreateRideSheet.show(context, currentUser: widget.aktifKullanici),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: filteredRides.length,
                  separatorBuilder: (context, index) {
                    if ((index + 1) % 3 == 0) {
                      return NativeAdWidget(
                        currentUser: widget.aktifKullanici,
                        templateType: TemplateType.medium,
                      );
                    }
                    return const SizedBox.shrink();
                  },
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
                      child: NeuContainer(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: EdgeInsets.zero,
                        borderRadius: 20,
                        depth: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  height: 155,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                                        const Icon(Icons.speed, color: NeuColors.accentAmber, size: 14),
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
                                      color: NeuColors.accentOrange.withValues(alpha: 0.9),
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
                              padding: const EdgeInsets.all(16.0),
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
                                      if (_canDeleteRide(ride)) ...[
                                        NeuIconButton(
                                          icon: Icons.delete_outline,
                                          iconColor: Colors.redAccent,
                                          size: 34,
                                          iconSize: 17,
                                          tooltip: "Rotayı Sil",
                                          onPressed: () => _confirmDeleteRide(context, ride),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      NeuBadge(
                                        text: "${ride.participantCount} Sürücü",
                                        icon: Icons.people_outline,
                                        color: NeuColors.accentOrange,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Oluşturan: ${ride.creatorNickname}",
                                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.timer_outlined, color: Colors.amber, size: 11),
                                            const SizedBox(width: 3),
                                            Text(
                                              ride.remainingTimeText,
                                              style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.place, color: NeuColors.accentOrange, size: 15),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "Buluşma: ${ride.meetingPoint}",
                                          style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: NeuColors.accentAmber, size: 14),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          ride.date,
                                          style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      NeuBadge(
                                        text: "${ride.distanceKm.toInt()} km • ${ride.estimatedDuration}",
                                        color: NeuColors.accentCyan,
                                        fontSize: 10.5,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          "Detaylar ve Canlı Rota ➡️",
                                          style: TextStyle(color: Colors.white38, fontSize: 11.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      NeuButton(
                                        text: katildi ? "Ayrıl" : "Katıl",
                                        icon: katildi ? Icons.exit_to_app : Icons.add_circle_outline,
                                        color: katildi ? Colors.red[900] : NeuColors.accentOrange,
                                        isPrimary: !katildi,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        borderRadius: 12,
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
        SavedRoutesScreen(currentUser: widget.aktifKullanici),
      ],
    ),
  ),
);
  }

  Widget _buildFilterChip(String label, double radius) {
    final isSelected = _selectedFilterRadius == radius;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterRadius = radius),
      child: NeuContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        borderRadius: 16,
        style: isSelected ? NeuStyle.sunken : NeuStyle.raised,
        color: isSelected ? NeuColors.accentOrange.withValues(alpha: 0.2) : NeuColors.surface,
        borderColor: isSelected ? NeuColors.accentOrange : Colors.white.withValues(alpha: 0.05),
        borderWidth: isSelected ? 1.5 : 1.0,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? NeuColors.accentOrange : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
