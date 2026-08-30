import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../chat/chat_screen.dart';
import '../garage/vip_garage_screen.dart';
import '../../widgets/neumorphic_widgets.dart';
import '../../services/ad_helper.dart';

class SwipeScreen extends StatefulWidget {
  final MotoUser aktifKullanici;
  const SwipeScreen({super.key, required this.aktifKullanici});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  List<MotoUser> tumProfiller = [];
  List<MotoUser> karsilasilacakProfiller = [];
  bool _yukleniyor = true;
  String _seciliTarzFiltresi = "Tümü";
  int _swipeCount = 0;

  final List<String> _tarzlar = ["Tümü", "Racing", "Naked", "Enduro", "Cruiser"];
  final ScrollController _profileScrollController = ScrollController();

  // SÜRÜKLEME / KAYDIRMA (SWIPE GESTURE) DEĞİŞKENLERİ
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0.0;
  bool _isAnimatingOut = false;

  @override
  void initState() {
    super.initState();
    _profilleriYukle();
  }

  @override
  void dispose() {
    _profileScrollController.dispose();
    super.dispose();
  }

  void _profilleriYukle() async {
    try {
      // 1. AYNI ROTADAN GEÇEN / KESİŞEN SÜRÜCÜLER
      final crossedEvents = await FirestoreService()
          .streamCrossedPaths(widget.aktifKullanici.id)
          .first;

      // 2. VERİTABANINDAN GENEL KULLANICILAR (Aynı hobilere/tarza sahip olanları eşleştirmek için)
      final allUsers = await FirestoreService().getRadarUsersOnce(
          currentUserId: widget.aktifKullanici.id, 
          currentUserEmail: widget.aktifKullanici.email
      );

      final Map<String, MotoUser> uniqueRiders = {};
      final String myEmail = widget.aktifKullanici.email.trim().toLowerCase();

      void addValidUser(MotoUser rider) {
        if (rider.id.isEmpty || rider.id == widget.aktifKullanici.id) return;
        if (myEmail.isNotEmpty && rider.email.trim().toLowerCase() == myEmail) return;
        if (widget.aktifKullanici.isUserBlocked(rider.id)) return;
        if (widget.aktifKullanici.isUserPassed(rider.id)) return;
        if (FirestoreService.isTestUser(rider.id, rider.nickname, rider.email)) return;
        uniqueRiders[rider.id] = rider;
      }

      for (final event in crossedEvents) {
        addValidUser(event.rider);
      }

      for (final rider in allUsers) {
        addValidUser(rider);
      }

      if (mounted) {
        setState(() {
          tumProfiller = uniqueRiders.values.toList();
          _filtreleProfiller();
          _yukleniyor = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  void _filtreleProfiller() {
    if (_seciliTarzFiltresi == "Tümü") {
      karsilasilacakProfiller = List.from(tumProfiller);
    } else {
      karsilasilacakProfiller = tumProfiller.where((u) {
        return u.ridingStyle.toLowerCase().contains(_seciliTarzFiltresi.toLowerCase()) ||
            u.primaryMotorType.toLowerCase().contains(_seciliTarzFiltresi.toLowerCase());
      }).toList();
    }

    // Ortak özellikleri (tarz, motor tipi veya HOBİLERİ) olanları puanlayıp en üste al
    karsilasilacakProfiller.sort((a, b) {
      final myStyle = widget.aktifKullanici.ridingStyle.toLowerCase();
      final myMotor = widget.aktifKullanici.primaryMotorType.toLowerCase();
      final myHobbies = widget.aktifKullanici.hobbies.map((e) => e.toLowerCase()).toList();

      int aScore = 0;
      int bScore = 0;

      if (a.ridingStyle.toLowerCase() == myStyle && myStyle.isNotEmpty) aScore += 2;
      if (a.primaryMotorType.toLowerCase() == myMotor && myMotor.isNotEmpty) aScore += 2;
      aScore += a.hobbies.where((h) => myHobbies.contains(h.toLowerCase())).length;

      if (b.ridingStyle.toLowerCase() == myStyle && myStyle.isNotEmpty) bScore += 2;
      if (b.primaryMotorType.toLowerCase() == myMotor && myMotor.isNotEmpty) bScore += 2;
      bScore += b.hobbies.where((h) => myHobbies.contains(h.toLowerCase())).length;

      return bScore.compareTo(aScore); // Yüksek skor en üstte
    });
  }

  void _eslesmeEkraniGoster(MotoUser eslesenKisi, {bool isSuperMatch = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: NeuContainer(
          padding: const EdgeInsets.all(24.0),
          borderRadius: 26,
          borderColor: isSuperMatch ? NeuColors.accentAmber : NeuColors.accentOrange,
          borderWidth: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeuContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 36,
                color: (isSuperMatch ? NeuColors.accentAmber : NeuColors.accentOrange).withValues(alpha: 0.15),
                child: Icon(
                  isSuperMatch ? Icons.auto_awesome : Icons.two_wheeler,
                  color: isSuperMatch ? NeuColors.accentAmber : NeuColors.accentOrange,
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSuperMatch ? "SÜPER EŞLEŞME! ⭐" : "EŞLEŞTİNİZ! 🎉",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isSuperMatch ? NeuColors.accentAmber : NeuColors.accentOrange,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Sen ve ${eslesenKisi.nickname} birbirinize selektör çaktınız! Birlikte gazlamaya ne dersin?",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NeuAvatar(
                    radius: 32,
                    borderColor: NeuColors.accentOrange,
                    image: widget.aktifKullanici.imageUrls.isNotEmpty
                        ? _getImageProvider(widget.aktifKullanici.imageUrls[0])
                        : null,
                    child: widget.aktifKullanici.imageUrls.isEmpty
                        ? const Icon(Icons.person, color: NeuColors.accentOrange)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Icon(
                    Icons.bolt,
                    color: isSuperMatch ? NeuColors.accentAmber : NeuColors.accentOrange,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  NeuAvatar(
                    radius: 32,
                    borderColor: isSuperMatch ? NeuColors.accentAmber : NeuColors.accentOrange,
                    image: eslesenKisi.imageUrls.isNotEmpty
                        ? _getImageProvider(eslesenKisi.imageUrls[0])
                        : null,
                    child: eslesenKisi.imageUrls.isEmpty
                        ? const Icon(Icons.person, color: NeuColors.accentOrange)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              NeuButton(
                text: "Sohbete Başla",
                icon: Icons.chat_bubble_outline,
                isPrimary: true,
                color: isSuperMatch ? NeuColors.accentAmber : NeuColors.accentOrange,
                textColor: isSuperMatch ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SohbetEkrani(
                        aktifKullanici: widget.aktifKullanici,
                        eslesilenKisi: eslesenKisi,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Keşfetmeye Devam Et", style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _animateAndEvaluate(bool begenildiMi, {bool isSuperLike = false}) {
    if (karsilasilacakProfiller.isEmpty || _isAnimatingOut) return;

    setState(() {
      _isAnimatingOut = true;
      if (isSuperLike) {
        _dragOffset = const Offset(0, -600);
        _dragAngle = 0.0;
      } else if (begenildiMi) {
        _dragOffset = const Offset(500, 50);
        _dragAngle = 0.35;
      } else {
        _dragOffset = const Offset(-500, 50);
        _dragAngle = -0.35;
      }
    });

    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      _profilDegerlendir(begenildiMi, isSuperLike: isSuperLike);
      setState(() {
        _dragOffset = Offset.zero;
        _dragAngle = 0.0;
        _isAnimatingOut = false;
      });
    });
  }

  void _profilDegerlendir(bool begenildiMi, {bool isSuperLike = false}) {
    if (karsilasilacakProfiller.isEmpty) return;
    final degerlendirilenKullanici = karsilasilacakProfiller[0];

    if (isSuperLike) {
      if (!widget.aktifKullanici.useSuperLike()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Günlük Süper Selektör hakkın doldu! VIP Garaj ile limitsiz."),
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }
      FirestoreService().sendSuperSignal(
        fromUserId: widget.aktifKullanici.id,
        fromNickname: widget.aktifKullanici.nickname,
        toUser: degerlendirilenKullanici,
      );
      _eslesmeEkraniGoster(degerlendirilenKullanici, isSuperMatch: true);
    } else if (begenildiMi) {
      if (!widget.aktifKullanici.useSwipeLike()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Günlük Swipe limitin doldu! VIP Garaj\'a geçerek limitsiz kaydır.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      FirestoreService().updateLikes(
        widget.aktifKullanici.id,
        swipeLikes: widget.aktifKullanici.swipeLikesLeft,
      );

      final bool karsilikliBegeniVarMi = degerlendirilenKullanici.id == "rider_asfalt";

      if (karsilikliBegeniVarMi) {
        _eslesmeEkraniGoster(degerlendirilenKullanici);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${degerlendirilenKullanici.nickname}'e selektör çakıldı! Karşılık verirse eşleşeceksiniz ⚡"),
            backgroundColor: const Color(0xFF2C1A0E),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // REDDETTİ (Pas Geçti)
      widget.aktifKullanici.passUser(degerlendirilenKullanici.id);
      FirestoreService().passUser(widget.aktifKullanici.id, degerlendirilenKullanici.id);
    }

    setState(() {
      karsilasilacakProfiller.removeAt(0);
      _swipeCount++;
      if (_swipeCount % 5 == 0) {
        AdHelper.showInterstitialAd(widget.aktifKullanici);
      }
      if (_profileScrollController.hasClients) {
        _profileScrollController.jumpTo(0);
      }
    });
  }

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http')) {
      return NetworkImage(path);
    }
    return const AssetImage('assets/images/default_avatar.png');
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) {
      return const Center(child: CircularProgressIndicator(color: NeuColors.accentOrange));
    }

    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        backgroundColor: NeuColors.surfaceDark,
        title: const Row(
          children: [
            Icon(Icons.two_wheeler, color: NeuColors.accentOrange, size: 22),
            SizedBox(width: 8),
            Text(
              'Keşfet',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        actions: [
          // VIP & HAK GÖSTERGESİ
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VipGarajEkrani(aktifKullanici: widget.aktifKullanici)),
                );
              },
              child: NeuContainer(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                borderRadius: 12,
                borderColor: widget.aktifKullanici.isPremium ? NeuColors.accentAmber : Colors.white.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    Icon(
                      widget.aktifKullanici.isPremium ? Icons.workspace_premium : Icons.flash_on,
                      color: widget.aktifKullanici.isPremium ? NeuColors.accentAmber : NeuColors.accentOrange,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.aktifKullanici.isPremium ? "VIP" : "${widget.aktifKullanici.swipeLikesLeft}",
                      style: TextStyle(
                        color: widget.aktifKullanici.isPremium ? NeuColors.accentAmber : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // DUYURU BANNER'I
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .where('isActive', isEqualTo: true)
                  .orderBy('createdAt', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
                
                final doc = snapshot.data!.docs.first;
                final data = doc.data() as Map<String, dynamic>;
                final message = data['message'] ?? '';
                
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    border: Border(bottom: BorderSide(color: Colors.white24, width: 1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // TARZ FİLTRELEME ÇİPLERİ
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _tarzlar.length,
                itemBuilder: (context, index) {
                  final tarz = _tarzlar[index];
                  final isSelected = _seciliTarzFiltresi == tarz;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _seciliTarzFiltresi = tarz;
                          _filtreleProfiller();
                        });
                      },
                      child: NeuContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        borderRadius: 14,
                        style: isSelected ? NeuStyle.sunken : NeuStyle.raised,
                        color: isSelected ? NeuColors.accentOrange.withValues(alpha: 0.2) : NeuColors.surface,
                        borderColor: isSelected ? NeuColors.accentOrange : Colors.white.withValues(alpha: 0.05),
                        borderWidth: isSelected ? 1.5 : 1,
                        child: Center(
                          child: Text(
                            tarz,
                            style: TextStyle(
                              color: isSelected ? NeuColors.accentOrange : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // PROFİL AKIŞI
            if (karsilasilacakProfiller.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NeuContainer(
                        padding: const EdgeInsets.all(24),
                        borderRadius: 36,
                        depth: 4,
                        child: const Icon(Icons.alt_route, size: 64, color: NeuColors.accentOrange),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Henüz Aynı Rotadan Geçen Sürücü Yok",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          "Motosikletinle yola çıktıkça veya ortak rotalara katıldıkça aynı güzergahta kesiştiğin sürücüler bu ekrana düşecek. 🏍️✨",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 24),
                      NeuButton(
                        text: "Yeniden Kontrol Et",
                        icon: Icons.refresh,
                        isPrimary: true,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        onPressed: () {
                          setState(() {
                            _seciliTarzFiltresi = "Tümü";
                            _profilleriYukle();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Stack(
                  children: [
                    // ARKA PLAN SIRADAKİ KART ÖNİZLEMESİ
                    if (karsilasilacakProfiller.length > 1)
                      Positioned.fill(
                        child: Transform.scale(
                          scale: 0.94,
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: NeuColors.surfaceDark,
                              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16)],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image(
                                    image: _getImageProvider(
                                      karsilasilacakProfiller[1].imageUrls.isNotEmpty
                                          ? karsilasilacakProfiller[1].imageUrls[0]
                                          : "https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800",
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                  BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                    child: Container(
                                      color: Colors.black.withValues(alpha: 0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // ÖN PLANDAKİ ETKİLEŞİMLİ VE KAYDIRILABİLİR KART
                    Positioned.fill(
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _dragOffset += details.delta;
                            _dragAngle = (_dragOffset.dx / 300) * 0.25;
                          });
                        },
                        onPanEnd: (details) {
                          if (_dragOffset.dx > 100) {
                            _animateAndEvaluate(true);
                          } else if (_dragOffset.dx < -100) {
                            _animateAndEvaluate(false);
                          } else if (_dragOffset.dy < -90 && _dragOffset.dx.abs() < 80) {
                            _animateAndEvaluate(true, isSuperLike: true);
                          } else {
                            setState(() {
                              _dragOffset = Offset.zero;
                              _dragAngle = 0.0;
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: _isAnimatingOut
                              ? const Duration(milliseconds: 200)
                              : const Duration(milliseconds: 0),
                          curve: Curves.easeOut,
                          transform: Matrix4.translationValues(_dragOffset.dx, _dragOffset.dy, 0)
                            ..rotateZ(_dragAngle),
                          child: Stack(
                            children: [
                              _buildRichVerticalProfile(karsilasilacakProfiller[0]),

                              // KAYDIRMA DAMGASI: SELEKTÖR
                              if (_dragOffset.dx > 20)
                                Positioned(
                                  top: 30,
                                  left: 30,
                                  child: Opacity(
                                    opacity: (_dragOffset.dx / 100).clamp(0.0, 1.0),
                                    child: Transform.rotate(
                                      angle: -0.2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.greenAccent, width: 3),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.greenAccent, blurRadius: 16),
                                          ],
                                        ),
                                        child: const Text(
                                          "SELEKTÖR ⚡",
                                          style: TextStyle(
                                            color: Colors.greenAccent,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // KAYDIRMA DAMGASI: PAS
                              if (_dragOffset.dx < -20)
                                Positioned(
                                  top: 30,
                                  right: 30,
                                  child: Opacity(
                                    opacity: ((-_dragOffset.dx) / 100).clamp(0.0, 1.0),
                                    child: Transform.rotate(
                                      angle: 0.2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.redAccent, width: 3),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.redAccent, blurRadius: 16),
                                          ],
                                        ),
                                        child: const Text(
                                          "PAS ❌",
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // KAYDIRMA DAMGASI: SÜPER SELEKTÖR
                              if (_dragOffset.dy < -30 && _dragOffset.dx.abs() < 70)
                                Positioned(
                                  top: 80,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Opacity(
                                      opacity: ((-_dragOffset.dy) / 100).clamp(0.0, 1.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.amber, width: 3),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.amber, blurRadius: 20, spreadRadius: 2),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
                                            SizedBox(width: 8),
                                            Text(
                                              "SÜPER SELEKTÖR ⭐",
                                              style: TextStyle(
                                                color: Colors.amber,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 3'LÜ ALT AKSİYON BUTONLARI (Tactile Neumorphic Buttons)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ❌ PAS GEÇ
                          GestureDetector(
                            onTap: () => _animateAndEvaluate(false),
                            child: NeuContainer(
                              width: 62,
                              height: 62,
                              borderRadius: 31,
                              depth: 5,
                              borderColor: Colors.redAccent.withValues(alpha: 0.6),
                              borderWidth: 1.5,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.close, color: Colors.redAccent, size: 26),
                                  Text("PAS", style: TextStyle(color: Colors.redAccent, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 20),

                          // ⭐ SÜPER SELEKTÖR (Gold Accent)
                          GestureDetector(
                            onTap: () => _animateAndEvaluate(true, isSuperLike: true),
                            child: NeuContainer(
                              width: 78,
                              height: 78,
                              borderRadius: 39,
                              depth: 6,
                              color: const Color(0xFF2A2210),
                              borderColor: NeuColors.accentAmber,
                              borderWidth: 2,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_awesome, color: NeuColors.accentAmber, size: 30),
                                  SizedBox(height: 2),
                                  Text("SÜPER", style: TextStyle(color: NeuColors.accentAmber, fontSize: 9, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 20),

                          // ⚡ SELEKTÖR ÇAK
                          GestureDetector(
                            onTap: () => _animateAndEvaluate(true),
                            child: NeuContainer(
                              width: 62,
                              height: 62,
                              borderRadius: 31,
                              depth: 5,
                              borderColor: NeuColors.accentOrange.withValues(alpha: 0.7),
                              borderWidth: 1.5,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.flash_on, color: NeuColors.accentOrange, size: 26),
                                  Text("SELEKTÖR", style: TextStyle(color: NeuColors.accentOrange, fontSize: 8, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Dikey olarak akan zengin profil akışı
  Widget _buildRichVerticalProfile(MotoUser user) {
    final photos = user.imageUrls.isNotEmpty
        ? user.imageUrls
        : ["https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800"];

    final isVip = widget.aktifKullanici.isPremium;

    return SingleChildScrollView(
      controller: _profileScrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ANA HERO FOTOĞRAF & İSİM BANNERI
          NeuContainer(
            height: 380,
            padding: EdgeInsets.zero,
            borderRadius: 24,
            depth: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image(
                    image: _getImageProvider(photos[0]),
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.transparent, Colors.black87],
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.place, color: NeuColors.accentOrange, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          user.locationName,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user.nickname,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                            ),
                          ),
                          if (user.isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: Colors.blueAccent, size: 22),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          NeuBadge(text: user.primaryMotor, icon: Icons.two_wheeler, color: NeuColors.accentOrange),
                          NeuBadge(text: user.ridingStyle, icon: Icons.speed, color: NeuColors.accentAmber),
                          NeuBadge(text: "${user.experienceLevel} Tecrübe", icon: Icons.history, color: NeuColors.accentCyan),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2. HAKKINDA BİYOGRAFİSİ KARTI
          NeuCard(
            title: "SÜRÜCÜ HAKKINDA",
            icon: Icons.notes,
            iconColor: NeuColors.accentOrange,
            child: Text(
              user.bio.isNotEmpty ? user.bio : "Henüz biyografi eklenmedi. Yollarda görüşürüz!",
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ),

          const SizedBox(height: 14),

          // 3. FOTOĞRAF GALERİSİ
          if (photos.length > 1) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.photo_library, color: NeuColors.accentAmber, size: 18),
                  SizedBox(width: 6),
                  Text("GARAJ & SÜRÜŞ FOTOĞRAFLARI", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
            ),
            ...photos.asMap().entries.skip(1).map((entry) {
              final int photoIndex = entry.key;
              final String photoUrl = entry.value;
              final bool isLocked = !isVip && photoIndex >= 3;

              return NeuContainer(
                margin: const EdgeInsets.only(bottom: 14),
                height: 320,
                padding: EdgeInsets.zero,
                borderRadius: 20,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image(
                        image: _getImageProvider(photoUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (isLocked)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.5),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: NeuColors.accentAmber.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: NeuColors.accentAmber, width: 1.5),
                                  ),
                                  child: const Icon(Icons.workspace_premium, color: NeuColors.accentAmber, size: 30),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "VIP 3+ Fotoğraf Kilidi",
                                  style: TextStyle(color: NeuColors.accentAmber, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "İlk 3 fotoğraf ücretsizdir. 3'ten fazla tüm fotoğrafları net görmek için VIP Garaj'a yükseltin.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                const SizedBox(height: 12),
                                NeuButton(
                                  text: "VIP Kilidini Aç",
                                  icon: Icons.workspace_premium,
                                  color: NeuColors.accentAmber,
                                  textColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  onPressed: () {
                                    VipGarajEkrani.showPaywall(context, currentUser: widget.aktifKullanici);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 8),

          // 4. İLGİ ALANLARI / HOBİLER ETİKETLERİ
          if (user.hobbies.isNotEmpty) ...[
            NeuCard(
              title: "SÜRÜŞ İLGİ ALANLARI",
              icon: Icons.interests,
              iconColor: NeuColors.accentOrange,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.hobbies.map((hobi) {
                  return NeuBadge(text: hobi, color: NeuColors.accentCyan, fontSize: 11.5);
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 5. GARAJ MOTORLARI KARTI
          if (user.garage.isNotEmpty) ...[
            NeuCard(
              title: "GARAJ",
              icon: Icons.garage,
              iconColor: NeuColors.accentOrange,
              child: Column(
                children: user.garage.map((motor) {
                  return NeuContainer(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    borderRadius: 14,
                    style: NeuStyle.sunken,
                    child: Row(
                      children: [
                        const Icon(Icons.two_wheeler, color: NeuColors.accentOrange, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${motor.brand} ${motor.model}",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                "${motor.engineCc} cc • ${motor.type}",
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 6. EN SEVDİĞİ ROTA VE VİRAJ KARTI
          if (user.favoriteRoute.isNotEmpty) ...[
            NeuCard(
              title: "FAVORİ ROTASI & VİRAJLARI",
              icon: Icons.alt_route,
              iconColor: NeuColors.accentCyan,
              child: Text(
                user.favoriteRoute,
                style: const TextStyle(color: NeuColors.accentCyan, fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 7. SÜRÜŞ FELSEFESİ & HEDEF KARTI
          NeuCard(
            title: "SÜRÜŞ FELSEFEM",
            icon: Icons.format_quote,
            iconColor: NeuColors.accentAmber,
            borderColor: NeuColors.accentAmber.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.ridingMotto.isNotEmpty ? '"${user.ridingMotto}"' : '"Rüzgarın izinden."',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                if (user.nextGoal.isNotEmpty) ...[
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.flag_outlined, color: NeuColors.accentOrange, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Gelecek Hedefim: ${user.nextGoal}",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
