import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/crossed_path_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/neumorphic_widgets.dart';

class CrossedPathsScreen extends StatefulWidget {
  final MotoUser currentUser;
  final List<CrossedPathEvent>? filteredEvents;

  const CrossedPathsScreen({
    super.key, 
    required this.currentUser,
    this.filteredEvents,
  });

  @override
  State<CrossedPathsScreen> createState() => _CrossedPathsScreenState();
}

class _CrossedPathsScreenState extends State<CrossedPathsScreen> {
  final Set<String> _likedUserIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        backgroundColor: NeuColors.surfaceDark,
        title: const Row(
          children: [
            Icon(Icons.alt_route, color: NeuColors.accentOrange, size: 22),
            SizedBox(width: 8),
            Text(
              "Yolda Karşılaştıklarım",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 17),
            ),
          ],
        ),
      ),
      body: widget.filteredEvents != null
          ? _buildListView(widget.filteredEvents!.where((item) => item.rider.id.isNotEmpty).toList())
          : StreamBuilder<List<CrossedPathEvent>>(
              stream: FirestoreService().streamCrossedPaths(widget.currentUser.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: NeuColors.accentOrange));
                }

                final allList = snapshot.data ?? [];
                final list = allList
                    .where((item) => item.rider.id.isNotEmpty && !widget.currentUser.isUserBlocked(item.rider.id))
                    .toList();

                return _buildListView(list);
              },
            ),
    );
  }

  Widget _buildListView(List<CrossedPathEvent> list) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NeuContainer(
                padding: const EdgeInsets.all(24),
                borderRadius: 36,
                depth: 4,
                child: const Icon(Icons.navigation_outlined, size: 64, color: NeuColors.accentOrange),
              ),
              const SizedBox(height: 18),
              const Text(
                "Henüz yolda kimseyle kesişmedin.",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Motosikletinle turladıkça aynı güzergahtan geçenler burada listelenecek.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final rider = item.rider;

              return NeuContainer(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                borderRadius: 20,
                depth: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Üst Satır: Profil & Kesişme Rozeti
                    Row(
                      children: [
                        NeuAvatar(
                          radius: 26,
                          borderColor: rider.isVerified ? Colors.blueAccent : NeuColors.accentOrange,
                          image: rider.imageUrls.isNotEmpty ? NetworkImage(rider.imageUrls[0]) : null,
                          child: rider.imageUrls.isEmpty ? const Icon(Icons.person, color: NeuColors.accentOrange, size: 24) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    rider.nickname,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (rider.isVerified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified, color: Colors.blueAccent, size: 15),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${rider.primaryMotor} • ${rider.ridingStyle}",
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        NeuBadge(
                          text: "${item.crossCount}x Kesişme",
                          icon: Icons.repeat,
                          color: NeuColors.accentOrange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Kesişme Konumu ve Zamanı
                    NeuContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      borderRadius: 12,
                      style: NeuStyle.sunken,
                      child: Row(
                        children: [
                          const Icon(Icons.place, color: NeuColors.accentAmber, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "${item.locationName} (${item.timeAgo})",
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Sürüş Şarkısı Çipi
                    if (rider.favoriteTrack.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.music_note, color: NeuColors.accentGreen, size: 15),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "Sürüş Şarkısı: ${rider.favoriteTrack}",
                              style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const Divider(height: 22),

                    // Aksiyon Butonları
                    Row(
                      children: [
                        // Dinamik Beğeni Butonu (İlk kez basıldığında Selektör, sonra Süper Selektör)
                        Expanded(
                          child: NeuButton(
                            text: _likedUserIds.contains(rider.id) ? "Süper Selektör" : "Selektör",
                            icon: _likedUserIds.contains(rider.id) ? Icons.star : Icons.flash_on,
                            color: _likedUserIds.contains(rider.id) ? NeuColors.accentAmber : NeuColors.surface,
                            textColor: _likedUserIds.contains(rider.id) ? Colors.black : NeuColors.accentAmber,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            borderRadius: 12,
                            onPressed: () async {
                              if (_likedUserIds.contains(rider.id)) {
                                // SÜPER SELEKTÖR AT
                                if (widget.currentUser.useSuperLike()) {
                                  await FirestoreService().sendSuperSignal(
                                    fromUserId: widget.currentUser.id,
                                    fromNickname: widget.currentUser.nickname,
                                    toUser: rider,
                                  );
                                  await FirestoreService().updateLikes(
                                    widget.currentUser.id,
                                    superLikes: widget.currentUser.superLikesLeft,
                                    lastLimitsResetAt: widget.currentUser.lastLimitsResetAt,
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("⭐ ${rider.nickname} adlı sürücüye SÜPER SELEKTÖR gönderildi!"),
                                      backgroundColor: Colors.amber[900],
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Günlük Süper Selektör hakkın doldu! VIP Garaj ile limitsiz."),
                                      backgroundColor: Colors.amber,
                                    ),
                                  );
                                }
                              } else {
                                // NORMAL SELEKTÖR AT VE BUTONU GÜNCELLE
                                if (widget.currentUser.useRadarLike()) {
                                  await FirestoreService().sendRadarSignal(
                                    fromUserId: widget.currentUser.id,
                                    fromNickname: widget.currentUser.nickname,
                                    toUser: rider,
                                  );
                                  await FirestoreService().updateLikes(
                                    widget.currentUser.id,
                                    radarLikes: widget.currentUser.radarLikesLeft,
                                    lastLimitsResetAt: widget.currentUser.lastLimitsResetAt,
                                  );
                                  setState(() {
                                    _likedUserIds.add(rider.id);
                                  });
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("${rider.nickname} adlı sürücüye selektör çakıldı! ⚡"),
                                      backgroundColor: const Color(0xFF222222),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Günlük Selektör hakkın doldu! VIP Garaj ile limitsiz."),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
  }
}
