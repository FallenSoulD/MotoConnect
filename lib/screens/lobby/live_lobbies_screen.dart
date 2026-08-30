import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/live_lobby_model.dart';
import '../../services/firestore_service.dart';
import '../chat/chat_screen.dart';
import '../../widgets/neumorphic_widgets.dart';

class LiveLobbiesScreen extends StatefulWidget {
  final MotoUser currentUser;
  const LiveLobbiesScreen({super.key, required this.currentUser});

  @override
  State<LiveLobbiesScreen> createState() => _LiveLobbiesScreenState();
}

class _LiveLobbiesScreenState extends State<LiveLobbiesScreen> {
  void _yeniLobiFormunuGoster() {
    final titleController = TextEditingController();
    final locationController = TextEditingController(text: "Moda Sahili");
    int selectedDuration = 20;
    String selectedStyle = "Şehir İçi ve Manzara";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return NeuContainer(
              borderRadius: 28,
              color: NeuColors.surfaceDark,
              borderColor: NeuColors.accentOrange.withValues(alpha: 0.4),
              borderWidth: 1.5,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.local_fire_department, color: NeuColors.accentOrange, size: 26),
                            SizedBox(width: 8),
                            Text(
                              "Anlık Gazlama Odası",
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
                    const SizedBox(height: 6),
                    const Text(
                      "15-30 dakika geçerli hızlı buluşma ve turlama lobisi aç.",
                      style: TextStyle(color: Colors.white54, fontSize: 12.5),
                    ),
                    const SizedBox(height: 18),

                    NeuTextField(
                      controller: titleController,
                      labelText: "Oda Başlığı",
                      hintText: "Örn: Moda Sahil Kahve Turu ☕",
                      prefixIcon: Icons.flash_on,
                    ),
                    const SizedBox(height: 12),

                    NeuTextField(
                      controller: locationController,
                      labelText: "Buluşma Noktası",
                      hintText: "Örn: Caddebostan Barlar Sokağı",
                      prefixIcon: Icons.place,
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      "Oda Süresi (Geri Sayım):",
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildDurationChip(15, "15 Dk", selectedDuration, (val) => setModalState(() => selectedDuration = val)),
                        const SizedBox(width: 8),
                        _buildDurationChip(20, "20 Dk (Standart)", selectedDuration, (val) => setModalState(() => selectedDuration = val)),
                        const SizedBox(width: 8),
                        _buildDurationChip(30, "30 Dk", selectedDuration, (val) => setModalState(() => selectedDuration = val)),
                      ],
                    ),

                    const SizedBox(height: 22),

                    NeuButton(
                      text: "Odayı Başlat & Motorcuları Çağır",
                      icon: Icons.local_fire_department,
                      isPrimary: true,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Lütfen oda başlığı yaz!"), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        final newLobby = LiveRideLobby(
                          id: '',
                          title: titleController.text.trim(),
                          creatorId: widget.currentUser.id,
                          creatorNickname: widget.currentUser.nickname,
                          creatorPhoto: widget.currentUser.imageUrls.isNotEmpty
                              ? widget.currentUser.imageUrls[0]
                              : '',
                          locationName: locationController.text.trim(),
                          ridingStyle: selectedStyle,
                          participantIds: [widget.currentUser.id],
                          participantNicknames: [widget.currentUser.nickname],
                          createdAt: DateTime.now(),
                          durationMinutes: selectedDuration,
                        );

                        await FirestoreService().createLiveLobby(newLobby);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("🚀 Anlık Gazlama Odası açıldı ve çevredekilere duyuruldu!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDurationChip(int duration, String label, int selected, Function(int) onSelect) {
    final isSelected = selected == duration;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(duration),
        child: NeuContainer(
          padding: const EdgeInsets.symmetric(vertical: 10),
          borderRadius: 12,
          style: isSelected ? NeuStyle.sunken : NeuStyle.raised,
          color: isSelected ? NeuColors.accentOrange.withValues(alpha: 0.2) : NeuColors.surface,
          borderColor: isSelected ? NeuColors.accentOrange : Colors.white.withValues(alpha: 0.05),
          borderWidth: isSelected ? 1.5 : 1,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? NeuColors.accentOrange : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        backgroundColor: NeuColors.surfaceDark,
        title: const Row(
          children: [
            Icon(Icons.local_fire_department, color: NeuColors.accentOrange, size: 22),
            SizedBox(width: 8),
            Text(
              "Canlı Gazlama Odaları",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 17),
            ),
          ],
        ),
        actions: [
          NeuIconButton(
            icon: Icons.add_circle_outline,
            iconColor: NeuColors.accentOrange,
            size: 40,
            iconSize: 22,
            tooltip: "Yeni Gazlama Odası Aç",
            onPressed: _yeniLobiFormunuGoster,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: StreamBuilder<List<LiveRideLobby>>(
        stream: FirestoreService().streamLiveLobbies(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: NeuColors.accentOrange));
          }

          final lobbies = snapshot.data ?? [];

          if (lobbies.isEmpty) {
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
                      child: const Icon(Icons.local_fire_department, size: 60, color: NeuColors.accentOrange),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      "Şu an aktif anlık gazlama odası yok.",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Hemen 15 dakikalık bir buluşma odası açıp etraftaki motorcuları topla!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    NeuButton(
                      text: "İlk Odayı Sen Başlat",
                      icon: Icons.flash_on,
                      isPrimary: true,
                      onPressed: _yeniLobiFormunuGoster,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: lobbies.length,
            itemBuilder: (context, index) {
              final lobby = lobbies[index];
              final isJoined = lobby.isJoined(widget.currentUser.id);
              final isCreator = lobby.creatorId == widget.currentUser.id;

              return NeuContainer(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                borderRadius: 20,
                depth: 4,
                borderColor: NeuColors.accentOrange.withValues(alpha: 0.4),
                borderWidth: 1.2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık & Kalan Süre Rozeti
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lobby.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        NeuBadge(
                          text: "${lobby.remainingMinutes} dk kaldı",
                          icon: Icons.timer,
                          color: NeuColors.accentAmber,
                          fontSize: 11,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Konum ve Lider
                    Row(
                      children: [
                        const Icon(Icons.place, color: NeuColors.accentGreen, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          lobby.locationName,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.person, color: NeuColors.accentOrange, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "Kuran: ${lobby.creatorNickname}",
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Katılımcı Listesi
                    NeuContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      borderRadius: 12,
                      style: NeuStyle.sunken,
                      child: Row(
                        children: [
                          const Text(
                            "Katılanlar: ",
                            style: TextStyle(color: Colors.white54, fontSize: 11.5),
                          ),
                          Expanded(
                            child: Text(
                              lobby.participantNicknames.join(", "),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 22),

                    // Katıl & Sohbet Butonları
                    Row(
                      children: [
                        Expanded(
                          child: NeuButton(
                            text: isJoined ? (isCreator ? "Odayı Kapat" : "Ayrıl") : "Odaya Katıl (${lobby.participantCount}/${lobby.maxParticipants})",
                            icon: isJoined ? Icons.exit_to_app : Icons.two_wheeler,
                            isPrimary: !isJoined,
                            color: isJoined ? NeuColors.surfaceDark : NeuColors.accentOrange,
                            textColor: isJoined ? Colors.white60 : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            borderRadius: 12,
                            onPressed: () async {
                              await FirestoreService().toggleJoinLobby(
                                lobby.id,
                                widget.currentUser,
                                !isJoined,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isJoined ? "Odadan ayrıldın." : "Gazlama odasına katıldın! 🔥"),
                                  backgroundColor: isJoined ? Colors.redAccent : Colors.green,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                        if (isJoined) ...[
                          const SizedBox(width: 10),
                          NeuIconButton(
                            icon: Icons.chat,
                            iconColor: NeuColors.accentOrange,
                            size: 44,
                            iconSize: 20,
                            tooltip: "Oda Sohbeti",
                            onPressed: () {
                              final dummyOther = MotoUser(
                                id: lobby.creatorId,
                                nickname: "${lobby.creatorNickname} (Oda Lideri)",
                                bio: lobby.title,
                                ridingStyle: lobby.ridingStyle,
                                experienceLevel: "",
                                garage: [],
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SohbetEkrani(
                                    aktifKullanici: widget.currentUser,
                                    eslesilenKisi: dummyOther,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
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
