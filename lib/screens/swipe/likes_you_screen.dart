import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/neumorphic_widgets.dart';
import '../garage/vip_garage_screen.dart';
import '../chat/chat_screen.dart';

class LikesYouScreen extends StatefulWidget {
  final MotoUser currentUser;
  const LikesYouScreen({super.key, required this.currentUser});

  @override
  State<LikesYouScreen> createState() => _LikesYouScreenState();
}

class _LikesYouScreenState extends State<LikesYouScreen> {
  void _eslesmePenceresiGoster(MotoUser matchedRider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: NeuColors.surfaceDark,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: NeuColors.accentOrange, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: NeuColors.accentOrange.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "⚡ EŞLEŞTİNİZ! 🎉",
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Sen ve ${matchedRider.nickname} birbirinize selektör çaktınız!",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.deepOrange,
                    backgroundImage: widget.currentUser.imageUrls.isNotEmpty
                        ? NetworkImage(widget.currentUser.imageUrls[0])
                        : null,
                    child: widget.currentUser.imageUrls.isEmpty
                        ? const Icon(Icons.person, color: Colors.white, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.bolt, color: Colors.amber, size: 34),
                  const SizedBox(width: 14),
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.deepOrange,
                    backgroundImage: matchedRider.imageUrls.isNotEmpty
                        ? NetworkImage(matchedRider.imageUrls[0])
                        : null,
                    child: matchedRider.imageUrls.isEmpty
                        ? const Icon(Icons.person, color: Colors.white, size: 30)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SohbetEkrani(
                          aktifKullanici: widget.currentUser,
                          eslesilenKisi: matchedRider,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text(
                    "Hemen Mesaj At",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        widget.currentUser.blockUser(matchedRider.id);
                        FirestoreService().blockUser(widget.currentUser.id, matchedRider.id);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Kullanıcı gizlendi."), backgroundColor: Colors.redAccent),
                        );
                      },
                      child: const Text("Reddet (Gizle)", style: TextStyle(color: Colors.redAccent)),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Daha Sonra", style: TextStyle(color: Colors.white54)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVip = widget.currentUser.isPremium;

    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        backgroundColor: NeuColors.surfaceDark,
        title: const Row(
          children: [
            Icon(Icons.flash_on, color: Colors.amber, size: 22),
            SizedBox(width: 8),
            Text(
              "Sana Selektör Atanlar",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        actions: [
          if (!isVip)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: GestureDetector(
                onTap: () => VipGarajEkrani.showPaywall(context, currentUser: widget.currentUser),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.workspace_premium, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text("VIP Kilitli", style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().streamIncomingSignals(widget.currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
          }

          var signals = snapshot.data ?? [];
          
          // Filtreleme: Yalnızca engellenenleri gizle (Swipe'ta pass edilenler burada görünmeye devam eder)
          signals = signals.where((signal) {
            final senderId = signal['fromUserId'] ?? '';
            return !widget.currentUser.isUserBlocked(senderId);
          }).toList();

          if (signals.isEmpty) {
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
                      child: const Icon(Icons.flash_off, size: 64, color: Colors.white38),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Henüz Sana Selektör Atan Yok",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Radarda gazlayarak, sürüşlere katılarak ve profilini zenginleştirerek çevrendeki motorcuların dikkatini çek! 🏍️⚡",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }

          return Stack(
            children: [
              // SELEKTÖR ATANLAR IZGARASI
              GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.75,
                ),
                itemCount: signals.length,
                itemBuilder: (context, index) {
                  final signal = signals[index];
                  final fromNick = signal['fromNickname'] ?? 'Motorcu';
                  final isSuper = signal['isSuperSignal'] == true;

                  final senderRider = MotoUser(
                    id: signal['fromUserId'] ?? '',
                    nickname: fromNick,
                    bio: '',
                    ridingStyle: 'Motosiklet Tutkunu',
                    experienceLevel: '1+ Yıl',
                    garage: const [],
                    imageUrls: const [],
                  );

                  return GestureDetector(
                    onTap: () {
                      if (!isVip) {
                        VipGarajEkrani.showPaywall(context, currentUser: widget.currentUser);
                      } else {
                        _eslesmePenceresiGoster(senderRider);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSuper
                            ? Colors.amber
                            : (isVip ? Colors.deepOrange.withValues(alpha: 0.6) : Colors.white12),
                        width: isSuper ? 2 : 1,
                      ),
                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // TEMSİLİ MOTOR ARKA PLAN RESMİ
                          Image.network(
                            "https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=500",
                            fit: BoxFit.cover,
                          ),

                          // VIP DEĞİLSE BLUR EFEKTİ
                          if (!isVip)
                            BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.4),
                              ),
                            ),

                          // KARARTMA GRADYANI
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.transparent, Colors.black87],
                              ),
                            ),
                          ),

                          // SÜPER SELEKTÖR ROZETİ
                          if (isSuper)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, color: Colors.black, size: 12),
                                    SizedBox(width: 3),
                                    Text("SÜPER", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 9)),
                                  ],
                                ),
                              ),
                            ),

                          // BİLGİLER VEYA KİLİT
                          Positioned(
                            bottom: 12,
                            left: 10,
                            right: 10,
                            child: isVip
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        fromNick,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isSuper ? "⭐ Süper Selektör Çaktı!" : "⚡ Selektör Çaktı",
                                        style: TextStyle(
                                          color: isSuper ? Colors.amber : Colors.deepOrangeAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock, color: Colors.amber, size: 28),
                                      SizedBox(height: 4),
                                      Text(
                                        "VIP ile Gör",
                                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                },
              ),

              // EĞER VIP DEĞİLSE ALTTA SABİT VIP AÇILIŞ ÇUBUĞU
              if (!isVip)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: NeuContainer(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 20,
                    depth: 6,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.workspace_premium, color: Colors.amber, size: 22),
                            SizedBox(width: 8),
                            Text(
                              "Sana Selektör Atanları Gör",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Sana selektör atan sürücülerin kim olduğunu öğrenmek ve doğrudan eşleşmek için VIP Garaj'a katılın.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60, fontSize: 11.5),
                        ),
                        const SizedBox(height: 14),
                        NeuButton(
                          color: Colors.amber[700]!,
                          textColor: Colors.black,
                          borderRadius: 14,
                          depth: 3,
                          onPressed: () => VipGarajEkrani.showPaywall(context, currentUser: widget.currentUser),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_open, color: Colors.black, size: 18),
                              SizedBox(width: 8),
                              Text("VIP Kilidini Aç 👑", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
