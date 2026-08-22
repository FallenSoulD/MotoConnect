import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/badge_model.dart';
import '../../services/firestore_service.dart';

class LeaderboardScreen extends StatelessWidget {
  final MotoUser currentUser;

  const LeaderboardScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final badges = FirestoreService().getUserBadges(currentUser);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              SizedBox(width: 8),
              Text(
                "Liderlik & Rozetler",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          bottom: const TabBar(
            indicatorColor: Colors.deepOrange,
            labelColor: Colors.deepOrange,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(icon: Icon(Icons.leaderboard), text: "Haftalık Sıralama"),
              Tab(icon: Icon(Icons.military_tech), text: "Motorcu Rozetleri"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: HAFTALIK LİDERLER (GERÇEK KULLANICILAR)
            StreamBuilder<List<LeaderboardEntry>>(
              stream: FirestoreService().streamRealLeaderboardEntries(currentUser),
              builder: (context, snapshot) {
                final entries = snapshot.data ?? [
                  LeaderboardEntry(
                    rank: 1,
                    rider: currentUser,
                    weeklyKm: (currentUser.maxLeanAngleLeft + currentUser.maxLeanAngleRight > 0)
                        ? ((currentUser.maxLeanAngleLeft + currentUser.maxLeanAngleRight) * 6).toInt()
                        : 120,
                    signalCount: 8,
                    points: 320,
                  ),
                ];

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 1. 2. 3. PODYUM KARTI
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E1B00), Color(0xFF181818)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "👑 HAFTANIN EN ÇOK GAZLAYANLARI",
                            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // 2. SIRA (GÜMÜŞ - Varsa)
                              if (entries.length > 1)
                                _buildPodiumItem(
                                  rank: 2,
                                  name: entries[1].rider.nickname,
                                  km: "${entries[1].weeklyKm} km",
                                  color: Colors.grey[300]!,
                                  height: 100,
                                  photo: entries[1].rider.imageUrls.isNotEmpty ? entries[1].rider.imageUrls[0] : "",
                                ),
                              // 1. SIRA (ALTIN)
                              if (entries.isNotEmpty)
                                _buildPodiumItem(
                                  rank: 1,
                                  name: entries[0].rider.nickname,
                                  km: "${entries[0].weeklyKm} km",
                                  color: Colors.amber,
                                  height: 130,
                                  photo: entries[0].rider.imageUrls.isNotEmpty ? entries[0].rider.imageUrls[0] : "",
                                ),
                              // 3. SIRA (BRONZ - Varsa)
                              if (entries.length > 2)
                                _buildPodiumItem(
                                  rank: 3,
                                  name: entries[2].rider.nickname,
                                  km: "${entries[2].weeklyKm} km",
                                  color: Colors.brown[300]!,
                                  height: 80,
                                  photo: entries[2].rider.imageUrls.isNotEmpty ? entries[2].rider.imageUrls[0] : "",
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      "TÜM SÜRÜCÜLER",
                      style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 10),

                    // LİSTE ELEMANLARI
                    ...entries.map((entry) {
                      final isMe = entry.rider.id == currentUser.id;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.deepOrange.withValues(alpha: 0.15) : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isMe ? Colors.deepOrange : Colors.white10,
                            width: isMe ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              "#${entry.rank}",
                              style: TextStyle(
                                color: entry.rank <= 3 ? Colors.amber : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 14),
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white10,
                              backgroundImage: entry.rider.imageUrls.isNotEmpty ? NetworkImage(entry.rider.imageUrls[0]) : null,
                              child: entry.rider.imageUrls.isEmpty ? const Icon(Icons.person, color: Colors.deepOrange) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        entry.rider.nickname,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 6),
                                        const Text("(Sen)", style: TextStyle(color: Colors.deepOrange, fontSize: 11)),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    "${entry.rider.primaryMotor} • ${entry.signalCount} Selektör",
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${entry.weeklyKm} km",
                                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  "${entry.points} Puan",
                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),

            // TAB 2: ROZET VİTRİNİ
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.deepOrange, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Sürüş yaptıkça, rotaları tamamladıkça ve diğer motorcularla yardımlaştıkça yeni rozetlerin kilidini açarsın.",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                ...badges.map((badge) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: badge.isUnlocked ? Colors.amber.withValues(alpha: 0.5) : Colors.white10,
                        width: badge.isUnlocked ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: badge.isUnlocked ? Colors.amber.withValues(alpha: 0.2) : Colors.white10,
                            shape: BoxShape.circle,
                          ),
                          child: Text(badge.icon, style: const TextStyle(fontSize: 28)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    badge.title,
                                    style: TextStyle(
                                      color: badge.isUnlocked ? Colors.white : Colors.white54,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (badge.isUnlocked)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text("Kazanıldı 🌟", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  else
                                    Text(
                                      "${badge.currentProgress}/${badge.targetProgress}",
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                badge.description,
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: badge.progressPercent,
                                  backgroundColor: Colors.white10,
                                  color: badge.isUnlocked ? Colors.amber : Colors.deepOrange,
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumItem({
    required int rank,
    required String name,
    required String km,
    required Color color,
    required double height,
    required String photo,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: rank == 1 ? 24 : 20,
          backgroundColor: color,
          backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
          child: photo.isEmpty ? const Icon(Icons.person, color: Colors.black) : null,
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
        Text(
          km,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
        ),
        const SizedBox(height: 6),
        Container(
          width: 70,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(
              "#$rank",
              style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
