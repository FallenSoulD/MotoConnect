import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/crossed_path_model.dart';
import '../../services/firestore_service.dart';
import '../chat/chat_screen.dart';

class CrossedPathsScreen extends StatelessWidget {
  final MotoUser currentUser;

  const CrossedPathsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.deepOrange),
        title: const Row(
          children: [
            Icon(Icons.alt_route, color: Colors.deepOrange),
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
            return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
          }

          final allList = snapshot.data ?? [];
          final list = allList
              .where((item) => !currentUser.isUserBlocked(item.rider.id))
              .toList();

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.navigation_outlined, size: 70, color: Colors.deepOrange),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Henüz yolda kimseyle kesişmedin.",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Motosikletinle turladıkça aynı güzergahtan geçenler burada listelenecek.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final rider = item.rider;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Üst Satır: Profil & Kesişme Rozeti
                      Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white12,
                                backgroundImage: rider.imageUrls.isNotEmpty
                                    ? NetworkImage(rider.imageUrls[0])
                                    : null,
                                child: rider.imageUrls.isEmpty
                                    ? const Icon(Icons.person, color: Colors.deepOrange)
                                    : null,
                              ),
                              if (rider.isVerified)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF121212),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.verified, color: Colors.blueAccent, size: 16),
                                  ),
                                ),
                            ],
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${item.crossCount}x Kesişme",
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

                      // Kesişme Konumu ve Zamanı
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.place, color: Colors.amber, size: 16),
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
                            const Icon(Icons.music_note, color: Colors.greenAccent, size: 15),
                            const SizedBox(width: 4),
                            Text(
                              "Sürüş Şarkısı: ${rider.favoriteTrack}",
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ],

                      const Divider(color: Colors.white12, height: 24),

                      // Aksiyon Butonları
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Selektör Butonu
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.amber,
                                side: const BorderSide(color: Colors.amber),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
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
                              icon: const Icon(Icons.flash_on, size: 16),
                              label: const Text("Selektör Çak", style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Süper Selektör (Tinder Super Like)
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.amber.withValues(alpha: 0.15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: Colors.amber),
                              ),
                            ),
                            icon: const Icon(Icons.star, color: Colors.amber, size: 18),
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
                          const SizedBox(width: 10),
                          // Sohbet Butonu
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
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
                              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16),
                              label: const Text(
                                "Mesaj Yaz",
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
