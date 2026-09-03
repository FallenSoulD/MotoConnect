import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../screens/garage/vip_garage_screen.dart';
import 'neumorphic_widgets.dart';
import 'moderation_sheets.dart';

class RadarDriverCard extends StatefulWidget {
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

  @override
  State<RadarDriverCard> createState() => _RadarDriverCardState();
}

class _RadarDriverCardState extends State<RadarDriverCard> {
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
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      color: NeuColors.surfaceDark.withValues(alpha: 0.96),
      borderColor: NeuColors.accentOrange.withValues(alpha: 0.5),
      borderWidth: 1.2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profil & Başlık Satırı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundImage: widget.selectedRider.imageUrls.isNotEmpty
                              ? NetworkImage(widget.selectedRider.imageUrls[0])
                              : const NetworkImage('https://via.placeholder.com/150'),
                        ),
                        if (widget.selectedRider.isOnline)
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: NeuColors.surfaceDark, width: 2.5),
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
                              Flexible(
                                child: Text(
                                  widget.selectedRider.nickname,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.selectedRider.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, color: Colors.blueAccent, size: 16),
                              ],
                              if (widget.selectedRider.isPremium) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.workspace_premium, color: NeuColors.accentAmber, size: 16),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.white54, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                _formatDistance(widget.currentUserLocation, widget.selectedRider.latLng),
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  NeuIconButton(
                    icon: Icons.report_problem_outlined,
                    iconColor: Colors.redAccent,
                    size: 36,
                    iconSize: 18,
                    onPressed: () {
                      ModerationSheets.showReportSheet(
                        context,
                        currentUserId: widget.currentUser.id,
                        targetUser: widget.selectedRider,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  NeuIconButton(
                    icon: Icons.close,
                    size: 36,
                    iconSize: 18,
                    iconColor: Colors.white54,
                    onPressed: widget.onClose,
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
                  color: _getStyleColor(widget.selectedRider.ridingStyle).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.selectedRider.ridingStyle,
                  style: TextStyle(
                    color: _getStyleColor(widget.selectedRider.ridingStyle),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Konum: ${widget.selectedRider.locationName}",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),

          // Sürüş Şarkısı & Egzoz Sesi
          if (widget.selectedRider.favoriteTrack.isNotEmpty || widget.selectedRider.exhaustSoundName.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (widget.selectedRider.favoriteTrack.isNotEmpty) ...[
                  const Icon(Icons.music_note, color: Colors.greenAccent, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.selectedRider.favoriteTrack,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ),
                ],
                if (widget.selectedRider.exhaustSoundName.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.selectedRider.exhaustSoundName,
                      style: const TextStyle(color: NeuColors.accentAmber, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ],



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
                    if (widget.currentUser.useRadarLike()) {
                      widget.onSignalTriggered();
                      await FirestoreService().updateLikes(
                        widget.currentUser.id,
                        radarLikes: widget.currentUser.radarLikesLeft,
                        lastLimitsResetAt: widget.currentUser.lastLimitsResetAt,
                      );
                      await FirestoreService().sendRadarSignal(
                        fromUserId: widget.currentUser.id,
                        fromNickname: widget.currentUser.nickname,
                        toUser: widget.selectedRider,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.flash_on, color: Colors.amber),
                              const SizedBox(width: 8),
                              Text("${widget.selectedRider.nickname} adlı sürücüye selektör atıldı! ⚡"),
                            ],
                          ),
                          backgroundColor: NeuColors.surfaceDark,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      VipGarajEkrani.showPaywall(context, currentUser: widget.currentUser);
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
                    if (widget.currentUser.useSuperLike()) {
                      widget.onSignalTriggered();
                      await FirestoreService().sendSuperSignal(
                        fromUserId: widget.currentUser.id,
                        fromNickname: widget.currentUser.nickname,
                        toUser: widget.selectedRider,
                      );
                      await FirestoreService().updateLikes(
                        widget.currentUser.id,
                        superLikes: widget.currentUser.superLikesLeft,
                        lastLimitsResetAt: widget.currentUser.lastLimitsResetAt,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("⭐ ${widget.selectedRider.nickname} adlı sürücüye SÜPER SELEKTÖR gönderildi! 🔥"),
                          backgroundColor: Colors.amber[900],
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      VipGarajEkrani.showPaywall(context, currentUser: widget.currentUser);
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
