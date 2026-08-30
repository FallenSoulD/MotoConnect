import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/badge_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/neumorphic_widgets.dart';
import '../../services/ad_helper.dart';

class LeaderboardScreen extends StatefulWidget {
  final MotoUser currentUser;

  const LeaderboardScreen({super.key, required this.currentUser});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedTab = 0; // 0: Sıralama, 1: Rozetler

  @override
  Widget build(BuildContext context) {
    final badges = FirestoreService().getUserBadges(widget.currentUser);

    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        backgroundColor: NeuColors.surfaceDark,
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: NeuColors.accentAmber, size: 22),
            SizedBox(width: 8),
            Text(
              "Liderlik & Rozetler",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: NeuSegmentedTabs(
              tabs: const ["🏆 Haftalık Sıralama", "🎖️ Motorcu Rozetleri"],
              selectedIndex: _selectedTab,
              onTabSelected: (idx) => setState(() => _selectedTab = idx),
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _buildLeaderboardTab()
                : _buildBadgesTab(badges),
          ),
          const SizedBox(height: 8),
          MotoBannerAd(currentUser: widget.currentUser),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return StreamBuilder<List<LeaderboardEntry>>(
      stream: FirestoreService().streamRealLeaderboardEntries(widget.currentUser),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [
          LeaderboardEntry(
            rank: 1,
            rider: widget.currentUser,
            weeklyKm: (widget.currentUser.maxLeanAngleLeft + widget.currentUser.maxLeanAngleRight > 0)
                ? ((widget.currentUser.maxLeanAngleLeft + widget.currentUser.maxLeanAngleRight) * 6).toInt()
                : 120,
            signalCount: 8,
            points: 320,
          ),
        ];

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // 1. 2. 3. PODYUM KARTI (Neumorphic 3D Podyum)
            NeuContainer(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              borderRadius: 22,
              depth: 4,
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stars, color: NeuColors.accentAmber, size: 18),
                      SizedBox(width: 6),
                      Text(
                        "HAFTANIN EN ÇOK GAZLAYANLARI",
                        style: TextStyle(
                          color: NeuColors.accentAmber,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 2. SIRA (GÜMÜŞ)
                      if (entries.length > 1)
                        _buildPodiumItem(
                          rank: 2,
                          name: entries[1].rider.nickname,
                          km: "${entries[1].weeklyKm} km",
                          color: const Color(0xFFC0C0C0),
                          height: 95,
                          photo: entries[1].rider.imageUrls.isNotEmpty ? entries[1].rider.imageUrls[0] : "",
                        )
                      else
                        const SizedBox(width: 70),

                      // 1. SIRA (ALTIN)
                      if (entries.isNotEmpty)
                        _buildPodiumItem(
                          rank: 1,
                          name: entries[0].rider.nickname,
                          km: "${entries[0].weeklyKm} km",
                          color: NeuColors.accentGold,
                          height: 125,
                          photo: entries[0].rider.imageUrls.isNotEmpty ? entries[0].rider.imageUrls[0] : "",
                        ),

                      // 3. SIRA (BRONZ)
                      if (entries.length > 2)
                        _buildPodiumItem(
                          rank: 3,
                          name: entries[2].rider.nickname,
                          km: "${entries[2].weeklyKm} km",
                          color: const Color(0xFFCD7F32),
                          height: 75,
                          photo: entries[2].rider.imageUrls.isNotEmpty ? entries[2].rider.imageUrls[0] : "",
                        )
                      else
                        const SizedBox(width: 70),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                "TÜM SÜRÜCÜLER",
                style: TextStyle(color: Colors.white54, fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),

            // LİSTE ELEMANLARI
            ...entries.map((entry) {
              final isMe = entry.rider.id == widget.currentUser.id;
              final Color rankColor = entry.rank == 1
                  ? NeuColors.accentGold
                  : (entry.rank == 2
                      ? const Color(0xFFC0C0C0)
                      : (entry.rank == 3 ? const Color(0xFFCD7F32) : Colors.white54));

              return NeuContainer(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                borderRadius: 16,
                borderColor: isMe ? NeuColors.accentOrange.withValues(alpha: 0.6) : null,
                borderWidth: isMe ? 1.5 : 1.0,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: entry.rank <= 3 ? rankColor.withValues(alpha: 0.15) : NeuColors.surfaceDark,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "#${entry.rank}",
                          style: TextStyle(
                            color: rankColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    NeuAvatar(
                      radius: 20,
                      borderColor: isMe ? NeuColors.accentOrange : Colors.white12,
                      image: entry.rider.imageUrls.isNotEmpty ? NetworkImage(entry.rider.imageUrls[0]) : null,
                      child: entry.rider.imageUrls.isEmpty ? const Icon(Icons.person, color: NeuColors.accentOrange, size: 20) : null,
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
                                const NeuBadge(text: "Sen", color: NeuColors.accentOrange, fontSize: 9),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
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
                          style: const TextStyle(color: NeuColors.accentAmber, fontWeight: FontWeight.bold, fontSize: 14),
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
    );
  }

  Widget _buildBadgesTab(List<RiderBadge> badges) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        NeuContainer(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 14),
          borderRadius: 16,
          color: NeuColors.surfaceDark,
          borderColor: NeuColors.accentOrange.withValues(alpha: 0.3),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: NeuColors.accentOrange, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Sürüş yaptıkça, rotaları tamamladıkça ve diğer motorcularla yardımlaştıkça yeni rozetlerin kilidini açarsın.",
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        ...badges.map((badge) {
          return NeuContainer(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            borderColor: badge.isUnlocked ? NeuColors.accentAmber.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
            borderWidth: badge.isUnlocked ? 1.5 : 1,
            child: Row(
              children: [
                NeuContainer(
                  width: 54,
                  height: 54,
                  borderRadius: 27,
                  style: badge.isUnlocked ? NeuStyle.raised : NeuStyle.sunken,
                  color: badge.isUnlocked ? NeuColors.accentAmber.withValues(alpha: 0.15) : NeuColors.surfaceDark,
                  child: Center(
                    child: Text(badge.icon, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              badge.title,
                              style: TextStyle(
                                color: badge.isUnlocked ? Colors.white : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                          if (badge.isUnlocked)
                            const NeuBadge(
                              text: "Kazanıldı 🌟",
                              color: NeuColors.accentGreen,
                              fontSize: 10,
                            )
                          else
                            Text(
                              "${badge.currentProgress}/${badge.targetProgress}",
                              style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
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
                          backgroundColor: NeuColors.surfaceDark,
                          color: badge.isUnlocked ? NeuColors.accentAmber : NeuColors.accentOrange,
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
        NeuAvatar(
          radius: rank == 1 ? 26 : 22,
          borderColor: color,
          borderWidth: 2,
          image: photo.isNotEmpty ? NetworkImage(photo) : null,
          child: photo.isEmpty ? Icon(Icons.person, color: color) : null,
        ),
        const SizedBox(height: 6),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
        Text(
          km,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
        ),
        const SizedBox(height: 6),
        NeuContainer(
          width: 74,
          height: height,
          borderRadius: 14,
          style: NeuStyle.raised,
          color: color.withValues(alpha: 0.18),
          borderColor: color.withValues(alpha: 0.7),
          child: Center(
            child: Text(
              "#$rank",
              style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}
