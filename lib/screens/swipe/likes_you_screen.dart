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
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flash_on, color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              "Sana Selektör Atanlar",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.workspace_premium, color: Colors.black, size: 14),
                      SizedBox(width: 4),
                      Text("VIP Kilitli", style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [NeuColors.background, NeuColors.surfaceDark],
          ),
        ),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService().streamIncomingSignals(widget.currentUser.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
            }

            var signals = snapshot.data ?? [];
            
            // Filtreleme: Yalnızca engellenenleri gizle
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
                        padding: const EdgeInsets.all(28),
                        borderRadius: 40,
                        depth: 6,
                        child: Icon(Icons.flash_off, size: 72, color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Henüz Seni Bula Yok",
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Radarda gazlayarak, sürüşlere katılarak ve profilini zenginleştirerek çevrendeki motorcuların dikkatini çek! 🏍️⚡",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Stack(
              children: [
                GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.72,
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
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSuper
                                ? Colors.amber.withValues(alpha: 0.8)
                                : (isVip ? Colors.deepOrange.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05)),
                            width: isSuper ? 2 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSuper ? Colors.amber.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // TEMSİLİ MOTOR ARKA PLAN RESMİ
                              Image.network(
                                "https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=500",
                                fit: BoxFit.cover,
                              ),

                              // VIP DEĞİLSE BLUR EFEKTİ VE KİLİT
                              if (!isVip) ...[
                                BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                  child: Container(
                                    color: NeuColors.background.withValues(alpha: 0.6),
                                  ),
                                ),
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black45,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                        ),
                                        child: const Icon(Icons.lock, color: Colors.amber, size: 28),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        isSuper ? "Süper Selektör" : "Gizli Beğeni",
                                        style: TextStyle(
                                          color: isSuper ? Colors.amber : Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // KARARTMA GRADYANI
                              if (isVip)
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
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 4),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.auto_awesome, color: Colors.black, size: 12),
                                        SizedBox(width: 4),
                                        Text("SÜPER", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
                                      ],
                                    ),
                                  ),
                                ),

                              // BİLGİLER VEYA KİLİT METNİ (ALT KISIM)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: isVip ? null : BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                  ),
                                  child: isVip
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              fromNick,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 17,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(isSuper ? Icons.bolt : Icons.flash_on, 
                                                  color: isSuper ? Colors.amber : Colors.deepOrange, size: 14),
                                                const SizedBox(width: 4),
                                                const Text(
                                                  "Selektör Attı",
                                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                      : Column(
                                          children: [
                                            const Text(
                                              "Görmek İçin",
                                              style: TextStyle(color: Colors.white54, fontSize: 11),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "VIP'ye Geç",
                                              style: TextStyle(color: Colors.amber[300], fontSize: 13, fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
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
      ),
    );
  }
}
