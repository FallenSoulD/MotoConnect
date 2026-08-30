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
              final lastMessage = chat['lastMessage'] as String? ?? '';
              final lastSenderId = chat['lastSenderId'] as String? ?? '';
              final saatStr = _formatMesajZamani(chat['lastMessageTime']);

              // GÖNDEREN KİM KONTROLÜ
              final bool isFromMe = lastSenderId.isNotEmpty && lastSenderId == widget.aktifKullanici.id;
              final bool isFromOther = lastSenderId.isNotEmpty && lastSenderId != widget.aktifKullanici.id;
              final bool isNewChat = lastMessage.isEmpty || lastMessage == 'Yeni sohbet';

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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  borderRadius: 18,
                  depth: isFromOther ? 5 : 3,
                  color: isFromOther
                      ? const Color(0xFF221A16) // Karşı taraf yazdıysa hafif turuncu yansıma
                      : NeuColors.surface,
                  borderColor: isFromOther
                      ? NeuColors.accentOrange.withValues(alpha: 0.85) // Parlayan Turuncu Çerçeve
                      : Colors.white.withValues(alpha: 0.05),
                  borderWidth: isFromOther ? 1.8 : 1.0,
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
                      // SÜRÜCÜ AVATARI (Karşı taraf yazdıysa parlayan turuncu halka)
                      Stack(
                        children: [
                          NeuAvatar(
                            radius: 26,
                            borderColor: isFromOther ? NeuColors.accentOrange : Colors.white12,
                            borderWidth: isFromOther ? 2.0 : 1.0,
                            image: otherPhoto.isNotEmpty ? NetworkImage(otherPhoto) : null,
                            child: otherPhoto.isEmpty
                                ? const Icon(Icons.person, color: NeuColors.accentOrange, size: 26)
                                : null,
                          ),
                          if (isFromOther)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 13,
                                height: 13,
                                decoration: BoxDecoration(
                                  color: NeuColors.accentOrange,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: NeuColors.surfaceDark, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: NeuColors.accentOrange.withValues(alpha: 0.8),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // MESAJ VE KULLANICI BİLGİLERİ
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    otherNickname,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: isFromOther ? FontWeight.w900 : FontWeight.bold,
                                      fontSize: 15.5,
                                    ),
                                  ),
                                ),
                                if (saatStr.isNotEmpty)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isFromOther) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          margin: const EdgeInsets.only(right: 6),
                                          decoration: BoxDecoration(
                                            color: NeuColors.accentOrange,
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: NeuColors.accentOrange.withValues(alpha: 0.5),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            "YENİ",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                      Text(
                                        saatStr,
                                        style: TextStyle(
                                          color: isFromOther ? NeuColors.accentOrange : Colors.white38,
                                          fontSize: 11,
                                          fontWeight: isFromOther ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 5),

                            // GÖNDEREN AYRIMI (Ben mi yazdım, Karşı taraf mı yazdı?)
                            Row(
                              children: [
                                if (isFromMe) ...[
                                  const Icon(Icons.done_all, color: NeuColors.accentCyan, size: 15),
                                  const SizedBox(width: 4),
                                  const Text(
                                    "Sen: ",
                                    style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ] else if (isFromOther) ...[
                                  const Icon(Icons.mark_chat_unread, color: NeuColors.accentOrange, size: 14),
                                  const SizedBox(width: 4),
                                ],
                                Expanded(
                                  child: Text(
                                    isNewChat ? "👋 Yeni eşleşme! Sohbeti başlat." : lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isFromOther
                                          ? Colors.white
                                          : isNewChat
                                              ? Colors.white38
                                              : Colors.white60,
                                      fontWeight: isFromOther ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      Icon(
                        Icons.chevron_right,
                        color: isFromOther ? NeuColors.accentOrange : Colors.white24,
                        size: 22,
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
