import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/crossed_path_model.dart';
import '../../services/firestore_service.dart';
import '../chat/chat_screen.dart';
import '../../widgets/neumorphic_widgets.dart';

class CrossedPathsScreen extends StatelessWidget {
  final MotoUser currentUser;

  const CrossedPathsScreen({super.key, required this.currentUser});

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
      body: StreamBuilder<List<CrossedPathEvent>>(
        stream: FirestoreService().streamCrossedPaths(currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: NeuColors.accentOrange));
          }

          final allList = snapshot.data ?? [];
          final list = allList
              .where((item) => !currentUser.isUserBlocked(item.rider.id))
              .toList();

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
                        // Selektör Butonu
                        Expanded(
                          child: NeuButton(
                            text: "Selektör",
                            icon: Icons.flash_on,
                            color: NeuColors.surface,
                            textColor: NeuColors.accentAmber,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            borderRadius: 12,
                            onPressed: () async {
                              await FirestoreService().sendRadarSignal(
                                fromUserId: currentUser.id,
                                fromNickname: currentUser.nickname,
                                toUser: rider,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("${rider.nickname} adlı sürücüye selektör çakıldı! ⚡"),
                                  backgroundColor: const Color(0xFF222222),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Süper Selektör
                        NeuIconButton(
                          icon: Icons.star,
                          iconColor: NeuColors.accentAmber,
                          size: 42,
                          iconSize: 20,
                          tooltip: "Süper Selektör",
                          onPressed: () async {
                            await FirestoreService().sendSuperSignal(
                              fromUserId: currentUser.id,
                              fromNickname: currentUser.nickname,
                              toUser: rider,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("⭐ ${rider.nickname} adlı sürücüye SÜPER SELEKTÖR gönderildi!"),
                                backgroundColor: Colors.amber[900],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        // Sohbet Butonu
                        Expanded(
                          child: NeuButton(
                            text: "Mesaj",
                            icon: Icons.chat_bubble_outline,
                            isPrimary: true,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            borderRadius: 12,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SohbetEkrani(
                                    aktifKullanici: currentUser,
                                    eslesilenKisi: rider,
                                  ),
                                ),
                              );
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
        },
      ),
    );
  }
}
