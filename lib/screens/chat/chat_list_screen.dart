import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/neumorphic_widgets.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final MotoUser aktifKullanici;
  const ChatListScreen({super.key, required this.aktifKullanici});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _formatMesajZamani(dynamic timestamp) {
    if (timestamp == null) return "";
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      return "";
    }
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        backgroundColor: NeuColors.surfaceDark,
        title: const Row(
          children: [
            Icon(Icons.chat_bubble, color: NeuColors.accentOrange, size: 22),
            SizedBox(width: 8),
            Text(
              "Eşleşmeler & Sohbet",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getUserChatsStream(widget.aktifKullanici.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: NeuColors.accentOrange));
          }

          final allChats = snapshot.data ?? [];
          final chats = allChats
              .where((c) => !widget.aktifKullanici.isUserBlocked(c['otherUserId'] ?? ''))
              .toList();

          if (chats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    NeuContainer(
                      padding: const EdgeInsets.all(24),
                      borderRadius: 30,
                      depth: 4,
                      child: const Icon(Icons.forum_outlined, size: 64, color: Colors.white38),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Henüz Eşleştiğin Bir Sürücü Yok",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Radarda veya Keşfet ekranında selektör çakıp karşılık aldığında eşleştiğin sürücülerle buradan sohbet edebilirsin. 🏍️💬",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final participants = List<String>.from(chat['participants'] ?? []);
              final otherUserId = participants.firstWhere(
                (id) => id != widget.aktifKullanici.id,
                orElse: () => '',
              );

              final participantData = chat['participantData'] as Map<String, dynamic>? ?? {};
              final otherData = participantData[otherUserId] as Map<String, dynamic>? ?? {};

              final otherNickname = otherData['nickname'] ?? 'Motorcu';
              final otherPhoto = otherData['photo'] as String? ?? '';
              final otherMotor = otherData['motor'] as String? ?? '';
              final otherStyle = otherData['style'] as String? ?? 'Naked';
              final lastMessage = chat['lastMessage'] ?? 'Yeni sohbet';
              final saatStr = _formatMesajZamani(chat['lastMessageTime']);

              final otherUser = MotoUser(
                id: otherUserId,
                nickname: otherNickname,
                bio: '',
                ridingStyle: otherStyle,
                experienceLevel: '',
                garage: [
                  Motorcycle(
                    brand: otherMotor,
                    model: '',
                    engineCc: 0,
                    type: otherStyle,
                  )
                ],
                imageUrls: otherPhoto.isNotEmpty ? [otherPhoto] : [],
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: NeuContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  borderRadius: 16,
                  depth: 3,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SohbetEkrani(
                          aktifKullanici: widget.aktifKullanici,
                          eslesilenKisi: otherUser,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      // Sürücü Avatarı
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: NeuColors.surfaceLight,
                        backgroundImage: otherPhoto.isNotEmpty ? NetworkImage(otherPhoto) : null,
                        child: otherPhoto.isEmpty
                            ? const Icon(Icons.person, color: NeuColors.accentOrange, size: 26)
                            : null,
                      ),
                      const SizedBox(width: 12),

                      // Mesaj Bilgileri
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  otherNickname,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.5,
                                  ),
                                ),
                                if (saatStr.isNotEmpty)
                                  Text(
                                    saatStr,
                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
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
