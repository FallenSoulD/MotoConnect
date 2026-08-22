import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/live_lobby_model.dart';
import '../../services/firestore_service.dart';
import '../chat/chat_screen.dart';

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
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 28),
                        SizedBox(width: 8),
                        Text(
                          "Anlık Gazlama Odası Başlat",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "15-30 dakika geçerli hızlı buluşma ve turlama lobisi aç.",
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Oda Başlığı (Örn: Moda Sahil Kahve Turu ☕)",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.flash_on, color: Colors.amber),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.deepOrange),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: locationController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Buluşma Noktası (Örn: Caddebostan Barlar Sokağı)",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.place, color: Colors.deepOrange),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      initialValue: selectedDuration,
                      dropdownColor: const Color(0xFF2A2A2A),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Oda Süresi (Geri Sayım)",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.timer, color: Colors.deepOrange),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 15, child: Text("15 Dakika (Hemen Toplan)")),
                        DropdownMenuItem(value: 20, child: Text("20 Dakika (Standart)")),
                        DropdownMenuItem(value: 30, child: Text("30 Dakika (Geniş Zaman)")),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedDuration = val);
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
                        child: const Text(
                          "Odayı Başlat & Motorcuları Çağır",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.deepOrange),
        title: const Row(
          children: [
            Icon(Icons.local_fire_department, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text(
              "Canlı Gazlama Odaları",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 17),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.deepOrange, size: 28),
            tooltip: "Yeni Gazlama Odası Aç",
            onPressed: _yeniLobiFormunuGoster,
          ),
        ],
      ),
      body: StreamBuilder<List<LiveRideLobby>>(
        stream: FirestoreService().streamLiveLobbies(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
          }

          final lobbies = snapshot.data ?? [];

          if (lobbies.isEmpty) {
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
                    child: const Icon(Icons.local_fire_department, size: 70, color: Colors.deepOrange),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Şu an aktif anlık gazlama odası yok.",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Hemen 15 dakikalık bir buluşma odası açıp etraftaki motorcuları topla!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                    onPressed: _yeniLobiFormunuGoster,
                    icon: const Icon(Icons.flash_on, color: Colors.white),
                    label: const Text("İlk Odayı Sen Başlat", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lobbies.length,
            itemBuilder: (context, index) {
              final lobby = lobbies[index];
              final isJoined = lobby.isJoined(widget.currentUser.id);
              final isCreator = lobby.creatorId == widget.currentUser.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF241C1A), Color(0xFF1E1E1E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.deepOrange.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer, color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  "${lobby.remainingMinutes} dk kaldı",
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Konum ve Lider
                      Row(
                        children: [
                          const Icon(Icons.place, color: Colors.greenAccent, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            lobby.locationName,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.person, color: Colors.deepOrange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "Kuran: ${lobby.creatorNickname}",
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Katılımcı Listesi
                      Row(
                        children: [
                          const Text(
                            "Katılanlar: ",
                            style: TextStyle(color: Colors.white54, fontSize: 12),
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

                      const Divider(color: Colors.white12, height: 24),

                      // Katıl & Sohbet Butonları
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isJoined ? Colors.white24 : Colors.deepOrange,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
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
                              icon: Icon(isJoined ? Icons.exit_to_app : Icons.two_wheeler, color: Colors.white, size: 18),
                              label: Text(
                                isJoined ? (isCreator ? "Odayı Kapat" : "Ayrıl") : "Odaya Katıl (${lobby.participantCount}/${lobby.maxParticipants})",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          if (isJoined) ...[
                            const SizedBox(width: 10),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.deepOrange.withValues(alpha: 0.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(color: Colors.deepOrange),
                                ),
                              ),
                              icon: const Icon(Icons.chat, color: Colors.deepOrange),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
