import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../screens/garage/vip_garage_screen.dart';
import 'neumorphic_widgets.dart';
import 'moderation_sheets.dart';

class RadarDriverCard extends StatelessWidget {
  final MotoUser selectedRider;
  final LatLng currentUserLocation;
  final MotoUser currentUser;
  final VoidCallback onClose;
  final VoidCallback onSignalTriggered;
  final VoidCallback? onStartLiveTracking;
  final VoidCallback? onOpenNavigation;

  const RadarDriverCard({
    super.key,
    required this.selectedRider,
    required this.currentUserLocation,
    required this.currentUser,
    required this.onClose,
    required this.onSignalTriggered,
    this.onStartLiveTracking,
    this.onOpenNavigation,
  });

  String _formatDistance(LatLng p1, LatLng p2) {
    const Distance distance = Distance();
    final double meter = distance.as(LengthUnit.Meter, p1, p2);
    if (meter < 1000) {
      return "${meter.toStringAsFixed(0)} metre uzakta";
    }
    return "${(meter / 1000).toStringAsFixed(1)} km uzakta";
  }

  Color _getStyleColor(String style) {
    if (style.contains("Racing")) return Colors.redAccent;
    if (style.contains("Enduro")) return Colors.greenAccent;
    if (style.contains("Cruiser")) return Colors.purpleAccent;
    return NeuColors.accentOrange;
  }

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      depth: 6,
      borderColor: NeuColors.accentOrange.withValues(alpha: 0.7),
      borderWidth: 1.5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profil & Başlık Satırı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: NeuColors.surfaceDark,
                        backgroundImage: selectedRider.imageUrls.isNotEmpty
                            ? NetworkImage(selectedRider.imageUrls[0])
                            : null,
                        child: selectedRider.imageUrls.isEmpty
                            ? const Icon(Icons.person, color: NeuColors.accentOrange)
                            : null,
                      ),
                      if (selectedRider.isVerified)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: const BoxDecoration(
                              color: NeuColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified, color: Colors.blueAccent, size: 14),
                          ),
                        ),
                      if (selectedRider.isPremium)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: const BoxDecoration(
                              color: NeuColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.workspace_premium, color: NeuColors.accentAmber, size: 14),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            selectedRider.nickname,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (selectedRider.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: Colors.blueAccent, size: 15),
                          ],
                          if (selectedRider.isPremium) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.workspace_premium, color: NeuColors.accentAmber, size: 16),
                          ],
                        ],
                      ),
                      Text(
                        "${selectedRider.primaryMotor} • ${_formatDistance(currentUserLocation, selectedRider.latLng)}",
                        style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.flag_outlined, color: Colors.white54, size: 20),
                    tooltip: "Sürücüyü Şikayet Et",
                    onPressed: () {
                      ModerationSheets.showReportSheet(
                        context,
                        currentUserId: currentUser.id,
                        targetUser: selectedRider,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: onClose,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Sürüş Tarzı & Konum
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStyleColor(selectedRider.ridingStyle).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  selectedRider.ridingStyle,
                  style: TextStyle(
                    color: _getStyleColor(selectedRider.ridingStyle),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Konum: ${selectedRider.locationName}",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),

          // Sürüş Şarkısı & Egzoz Sesi
          if (selectedRider.favoriteTrack.isNotEmpty || selectedRider.exhaustSoundName.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (selectedRider.favoriteTrack.isNotEmpty) ...[
                  const Icon(Icons.music_note, color: Colors.greenAccent, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      selectedRider.favoriteTrack,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ),
                ],
                if (selectedRider.exhaustSoundName.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      selectedRider.exhaustSoundName,
                      style: const TextStyle(color: NeuColors.accentAmber, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ],

          const SizedBox(height: 12),

          // LİFE 360 CANLI TAKİP & NAVİGASYON HIZLI BUTONLARI
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onStartLiveTracking,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.radar, color: Colors.cyanAccent, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "Canlı 360 Takip",
                          style: TextStyle(color: Colors.cyanAccent, fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: onOpenNavigation,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.navigation_outlined, color: Colors.deepOrange, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "Yol Tarifi Al",
                          style: TextStyle(color: Colors.deepOrange, fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Aksiyon Butonları: Neumorphic Selektör & Süper Selektör
          Row(
            children: [
              // Standart Selektör Butonu
              Expanded(
                flex: 3,
                child: NeuButton(
                  isPrimary: true,
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: () async {
                    if (currentUser.useRadarLike()) {
                      onSignalTriggered();
                      await FirestoreService().updateLikes(
                        currentUser.id,
                        radarLikes: currentUser.radarLikesLeft,
                      );
                      await FirestoreService().sendRadarSignal(
                        fromUserId: currentUser.id,
                        fromNickname: currentUser.nickname,
                        toUser: selectedRider,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.flash_on, color: Colors.amber),
                              const SizedBox(width: 8),
                              Text("${selectedRider.nickname} adlı sürücüye selektör atıldı! ⚡"),
                            ],
                          ),
                          backgroundColor: NeuColors.surfaceDark,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      VipGarajEkrani.showPaywall(context, currentUser: currentUser);
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flash_on, color: NeuColors.accentAmber, size: 18),
                      SizedBox(width: 6),
                      Text(
                        "Selektör At ⚡",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Süper Selektör Butonu
              Expanded(
                flex: 2,
                child: NeuButton(
                  color: NeuColors.accentAmber,
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: () async {
                    if (currentUser.useSuperLike()) {
                      onSignalTriggered();
                      await FirestoreService().sendSuperSignal(
                        fromUserId: currentUser.id,
                        fromNickname: currentUser.nickname,
                        toUser: selectedRider,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("⭐ ${selectedRider.nickname} adlı sürücüye SÜPER SELEKTÖR gönderildi! 🔥"),
                          backgroundColor: Colors.amber[900],
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      VipGarajEkrani.showPaywall(context, currentUser: currentUser);
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.black, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "Süper ⭐",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
