import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/chat_model.dart';
import '../../services/firestore_service.dart';
import '../../services/safety_filter_service.dart';
import '../../widgets/moderation_sheets.dart';

class SohbetEkrani extends StatefulWidget {
  final MotoUser aktifKullanici;
  final MotoUser eslesilenKisi;
  const SohbetEkrani({super.key, required this.aktifKullanici, required this.eslesilenKisi});

  @override
  State<SohbetEkrani> createState() => _SohbetEkraniState();
}

class _SohbetEkraniState extends State<SohbetEkrani> {
  final TextEditingController _mesajController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final String _chatRoomId;

  // Anti-Spam & Cooldown Timer Yönetimi
  Timer? _spamTimer;
  int _cooldownSeconds = 0;
  int _totalCooldown = 3;
  int _rapidSendCount = 0;
  DateTime? _lastSentTimestamp;

  @override
  void initState() {
    super.initState();
    _chatRoomId = FirestoreService.getChatRoomId(widget.aktifKullanici.id, widget.eslesilenKisi.id);
  }

  @override
  void dispose() {
    _spamTimer?.cancel();
    _mesajController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _mesajGonder() {
    String text = _mesajController.text.trim();
    if (text.isEmpty) return;

    // Spam Koruması Kontrolü
    if (_cooldownSeconds > 0) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.timer, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text("⏱️ Spam koruması aktif! Lütfen $_cooldownSeconds saniye bekleyin."),
            ],
          ),
          backgroundColor: Colors.deepOrange.shade800,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (SafetyFilterService.containsInappropriateContent(text)) {
      text = SafetyFilterService.maskInappropriateContent(text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Topluluk güvenliği gereği uygunsuz ifadeler yıldızlandı (***)."),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Cooldown Süresini Hesapla (Arka arkaya hızlı mesajlarda süreyi kademeli artırır)
    final now = DateTime.now();
    if (_lastSentTimestamp != null && now.difference(_lastSentTimestamp!).inSeconds < 6) {
      _rapidSendCount++;
    } else {
      _rapidSendCount = 1;
    }
    _lastSentTimestamp = now;

    int cooldownDuration = 3;
    if (_rapidSendCount >= 3) {
      cooldownDuration = 8;
    } else if (_rapidSendCount >= 2) {
      cooldownDuration = 5;
    }

    setState(() {
      _totalCooldown = cooldownDuration;
      _cooldownSeconds = cooldownDuration;
    });

    _spamTimer?.cancel();
    _spamTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_cooldownSeconds > 1) {
          _cooldownSeconds--;
        } else {
          _cooldownSeconds = 0;
          _spamTimer?.cancel();
        }
      });
    });

    _mesajController.clear();

    final newMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: widget.aktifKullanici.id,
      senderNickname: widget.aktifKullanici.nickname,
      receiverId: widget.eslesilenKisi.id,
      text: text,
      timestamp: DateTime.now(),
    );

    FirestoreService().sendMessage(
      chatRoomId: _chatRoomId,
      message: newMessage,
      sender: widget.aktifKullanici,
      receiver: widget.eslesilenKisi,
    );

    _scrollBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isBlocked = widget.aktifKullanici.isUserBlocked(widget.eslesilenKisi.id);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.deepOrange),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white12,
              backgroundImage: widget.eslesilenKisi.imageUrls.isNotEmpty
                  ? NetworkImage(widget.eslesilenKisi.imageUrls[0])
                  : null,
              child: widget.eslesilenKisi.imageUrls.isEmpty
                  ? const Icon(Icons.person, color: Colors.deepOrange)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.eslesilenKisi.nickname,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    widget.eslesilenKisi.ridingStyle,
                    style: const TextStyle(fontSize: 12, color: Colors.deepOrange),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            color: const Color(0xFF2A2A2A),
            onSelected: (value) {
              if (value == 'report') {
                ModerationSheets.showReportSheet(
                  context,
                  currentUserId: widget.aktifKullanici.id,
                  targetUser: widget.eslesilenKisi,
                );
              } else if (value == 'block') {
                ModerationSheets.showBlockDialog(
                  context,
                  currentUserId: widget.aktifKullanici.id,
                  targetUser: widget.eslesilenKisi,
                  onBlocked: () {
                    setState(() {
                      widget.aktifKullanici.blockUser(widget.eslesilenKisi.id);
                    });
                    Navigator.pop(context);
                  },
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report_problem_outlined, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text("Şikayet Et", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Text("Kullanıcıyı Engelle", style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (isBlocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red[900]?.withValues(alpha: 0.4),
              child: const Text(
                "Bu kullanıcıyı engellediniz. Mesaj gönderilemez.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: FirestoreService().streamMessages(
                _chatRoomId,
                widget.aktifKullanici,
                widget.eslesilenKisi,
              ),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.waving_hand, size: 50, color: Colors.deepOrange),
                        const SizedBox(height: 10),
                        Text(
                          "${widget.eslesilenKisi.nickname} ile sohbeti başlat!",
                          style: const TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final mesaj = messages[index];
                    final bool benimMi = mesaj.senderId == widget.aktifKullanici.id;
                    final saatStr =
                        "${mesaj.timestamp.hour.toString().padLeft(2, '0')}:${mesaj.timestamp.minute.toString().padLeft(2, '0')}";

                    return Align(
                      alignment: benimMi ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: benimMi ? Colors.deepOrange : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(benimMi ? 16 : 2),
                            bottomRight: Radius.circular(benimMi ? 2 : 16),
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              benimMi ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              mesaj.text,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              saatStr,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // SPAM KORUMASI GERİ SAYIM ŞERİDİ
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _cooldownSeconds > 0
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2B1700),
                border: Border(
                  top: BorderSide(color: Colors.deepOrange.withValues(alpha: 0.4)),
                  bottom: BorderSide(color: Colors.deepOrange.withValues(alpha: 0.4)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Colors.deepOrange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Spam Koruması: Yeni mesaj için bekleyin",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.deepOrange, width: 1),
                    ),
                    child: Text(
                      "⏱️ ${_cooldownSeconds}s",
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox(height: 0, width: double.infinity),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: const Color(0xFF1A1A1A),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mesajController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _cooldownSeconds > 0
                          ? "Spam koruması aktif (${_cooldownSeconds}s)..."
                          : "Mesaj yaz...",
                      hintStyle: TextStyle(
                        color: _cooldownSeconds > 0 ? Colors.deepOrange.withValues(alpha: 0.6) : Colors.white54,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.black26,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _mesajGonder(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _mesajGonder,
                  child: _cooldownSeconds > 0
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                value: _totalCooldown > 0 ? _cooldownSeconds / _totalCooldown : 0,
                                strokeWidth: 3,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                                backgroundColor: Colors.white12,
                              ),
                            ),
                            CircleAvatar(
                              radius: 19,
                              backgroundColor: const Color(0xFF2A2A2A),
                              child: Text(
                                "$_cooldownSeconds",
                                style: const TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.deepOrange,
                          child: Icon(Icons.send, color: Colors.white, size: 20),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
