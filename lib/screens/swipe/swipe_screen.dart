import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../chat/chat_screen.dart';
import '../garage/vip_garage_screen.dart';

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
      // SADECE AYNI ROTADAN GEÇEN / KESİŞEN SÜRÜCÜLERİ ÇEK
      final crossedEvents = await FirestoreService()
          .streamCrossedPaths(widget.aktifKullanici.id)
          .first;

      final Map<String, MotoUser> uniqueCrossedRiders = {};
      final String myEmail = widget.aktifKullanici.email.trim().toLowerCase();

      for (final event in crossedEvents) {
        final rider = event.rider;
        if (rider.id.isEmpty || rider.id == widget.aktifKullanici.id) continue;
        if (myEmail.isNotEmpty && rider.email.trim().toLowerCase() == myEmail) continue;
        if (widget.aktifKullanici.isUserBlocked(rider.id)) continue;
        if (FirestoreService.isTestUser(rider.id, rider.nickname, rider.email)) continue;

        uniqueCrossedRiders[rider.id] = rider;
      }

      if (mounted) {
        setState(() {
          tumProfiller = uniqueCrossedRiders.values.toList();
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
  }

  void _eslesmeEkraniGoster(MotoUser eslesenKisi, {bool isSuperMatch = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isSuperMatch ? Colors.amber : Colors.deepOrange,
            width: 2.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isSuperMatch ? Colors.amber : Colors.deepOrange).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuperMatch ? Icons.auto_awesome : Icons.two_wheeler,
                  color: isSuperMatch ? Colors.amber : Colors.deepOrange,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSuperMatch ? "SÜPER EŞLEŞME! ⭐" : "EŞLEŞTİNİZ! 🎉",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isSuperMatch ? Colors.amber : Colors.deepOrange,
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
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.deepOrange,
                    backgroundImage: widget.aktifKullanici.imageUrls.isNotEmpty
                        ? _getImageProvider(widget.aktifKullanici.imageUrls[0])
                        : null,
                    child: widget.aktifKullanici.imageUrls.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.bolt,
                    color: isSuperMatch ? Colors.amber : Colors.deepOrange,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.deepOrange,
                    backgroundImage: eslesenKisi.imageUrls.isNotEmpty
                        ? _getImageProvider(eslesenKisi.imageUrls[0])
                        : null,
                    child: eslesenKisi.imageUrls.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuperMatch ? Colors.amber[700] : Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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
                  child: Text(
                    "Sohbete Başla",
                    style: TextStyle(
                      color: isSuperMatch ? Colors.black : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
      // Süper Like doğrudan eşleşme tetikler
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
    }

    setState(() {
      karsilasilacakProfiller.removeAt(0);
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
      return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.two_wheeler, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text(
              'Keşfet',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.aktifKullanici.isPremium
                      ? Colors.amber.withValues(alpha: 0.2)
                      : Colors.deepOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.aktifKullanici.isPremium ? Colors.amber : Colors.white24,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.aktifKullanici.isPremium ? Icons.workspace_premium : Icons.flash_on,
                      color: widget.aktifKullanici.isPremium ? Colors.amber : Colors.deepOrange,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.aktifKullanici.isPremium ? "VIP" : "${widget.aktifKullanici.swipeLikesLeft}",
                      style: TextStyle(
                        color: widget.aktifKullanici.isPremium ? Colors.amber : Colors.white,
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
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(tarz),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      backgroundColor: const Color(0xFF1E1E1E),
                      selectedColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.deepOrange : Colors.white12,
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _seciliTarzFiltresi = tarz;
                          _filtreleProfiller();
                        });
                      },
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
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.alt_route, size: 70, color: Colors.deepOrange),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Henüz Aynı Rotadan Geçen Sürücü Yok",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Motosikletinle yola çıktıkça veya ortak rotalara katıldıkça aynı güzergahta kesiştiğin sürücüler bu ekrana düşecek. 🏍️✨",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text("Yeniden Kontrol Et", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    // ARKA PLAN SIRADAKİ KART ÖNİZLEMESİ (BLURLU DERİNLİK EFEKTİ)
                    if (karsilasilacakProfiller.length > 1)
                      Positioned.fill(
                        child: Transform.scale(
                          scale: 0.94,
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: const Color(0xFF1A1A1A),
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

                    // ÖN PLANDAKİ ETKİLEŞİMLİ VE KAYDIRILABİLİR KART (OPAK & NET)
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
                            // Sağa Kaydırma: Selektör / Beğen
                            _animateAndEvaluate(true);
                          } else if (_dragOffset.dx < -100) {
                            // Sola Kaydırma: Pas / Reddet
                            _animateAndEvaluate(false);
                          } else if (_dragOffset.dy < -90 && _dragOffset.dx.abs() < 80) {
                            // Yukarı Kaydırma: Süper Selektör (En Büyük Beğeni)
                            _animateAndEvaluate(true, isSuperLike: true);
                          } else {
                            // Merkeze Geri Yaylanma
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

                              // KAYDIRMA DAMGASI: SELEKTÖR (SAĞA SÜRÜKLERKEN GÖRÜNÜR)
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

                              // KAYDIRMA DAMGASI: PAS (SOLA SÜRÜKLERKEN GÖRÜNÜR)
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

                              // KAYDIRMA DAMGASI: SÜPER SELEKTÖR (YUKARI SÜRÜKLERKEN GÖRÜNÜR)
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

                    // 3'LÜ ALT AKSİYON BUTONLARI (SOL: PAS, ORTA: EN BÜYÜK BEĞENİ / SÜPER SELEKTÖR, SAĞ: SELEKTÖR)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ❌ EN SOL: PAS GEÇ / REDDET
                          GestureDetector(
                            onTap: () => _animateAndEvaluate(false),
                            child: Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.7), width: 2),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black87, blurRadius: 12, offset: Offset(0, 4)),
                                ],
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.close, color: Colors.redAccent, size: 28),
                                  Text("PAS", style: TextStyle(color: Colors.redAccent, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 22),

                          // ⭐👑🔥 ORTA: PROGRAMIMIZIN EN BÜYÜK BEĞENİSİ (SÜPER SELEKTÖR)
                          GestureDetector(
                            onTap: () => _animateAndEvaluate(true, isSuperLike: true),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFF8C00), Color(0xFFB8860B)],
                                ),
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.6),
                                    blurRadius: 24,
                                    spreadRadius: 3,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                                  SizedBox(height: 2),
                                  Text(
                                    "SÜPER\nSELEKTÖR",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 22),

                          // ⚡ EN SAĞ: SELEKTÖR ÇAK (NORMAL BEĞENİ)
                          GestureDetector(
                            onTap: () => _animateAndEvaluate(true),
                            child: Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF5722), Color(0xFFFF2A6D)],
                                ),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepOrange.withValues(alpha: 0.5),
                                    blurRadius: 16,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.flash_on, color: Colors.white, size: 28),
                                  Text("SELEKTÖR", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
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

  /// Dikey olarak akan zengin profil akışı (Arka planı tamamen opak ve net)
  Widget _buildRichVerticalProfile(MotoUser user) {
    final photos = user.imageUrls.isNotEmpty
        ? user.imageUrls
        : ["https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800"];

    final isVip = widget.aktifKullanici.isPremium;

    return Container(
      color: const Color(0xFF121212),
      child: SingleChildScrollView(
        controller: _profileScrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // 1. ANA HERO FOTOĞRAF & İSİM BANNERI (1. Fotoğraf: Herkese Net)
          Container(
            height: 380,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: DecorationImage(
                image: _getImageProvider(photos[0]),
                fit: BoxFit.cover,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Stack(
              children: [
                // Karartma Gradyanı
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
                // Sağ Üst Mavi Tik ve Konum Rozeti
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
                        const Icon(Icons.place, color: Colors.deepOrange, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          user.locationName,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                // Sol Alt İsim, Mavi Tik ve Motor Rozeti
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
                          _buildBadge(Icons.two_wheeler, user.primaryMotor, Colors.deepOrange),
                          _buildBadge(Icons.speed, user.ridingStyle, Colors.amber),
                          _buildBadge(Icons.history, "${user.experienceLevel} Tecrübe", Colors.cyanAccent),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. HAKKINDA BİYOGRAFİSİ KARTI
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notes, color: Colors.deepOrange, size: 18),
                    SizedBox(width: 6),
                    Text("SÜRÜCÜ HAKKINDA", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  user.bio.isNotEmpty ? user.bio : "Henüz biyografi eklenmedi. Yollarda görüşürüz!",
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. FOTOĞRAF GALERİSİ (İlk 3 Görsel Herkese Açık, 3+ Görseller VIP)
          if (photos.length > 1) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.photo_library, color: Colors.amber, size: 18),
                  SizedBox(width: 6),
                  Text("GARAJ & SÜRÜŞ FOTOĞRAFLARI", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
            ),
            ...photos.asMap().entries.skip(1).map((entry) {
              final int photoIndex = entry.key; // 1, 2, 3, 4...
              final String photoUrl = entry.value;
              final bool isLocked = !isVip && photoIndex >= 3; // 0, 1, 2 ücretsiz; 3+ (4. foto ve sonrası) VIP

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                height: 320,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: _getImageProvider(photoUrl),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: Colors.white12),
                ),
                child: isLocked
                    ? ClipRRect(
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
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.amber, width: 1.5),
                                  ),
                                  child: const Icon(Icons.workspace_premium, color: Colors.amber, size: 30),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "VIP 3+ Fotoğraf Kilidi",
                                  style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "İlk 3 fotoğraf ücretsizdir. 3'ten fazla tüm fotoğrafları net görmek için VIP Garaj'a yükseltin.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber[700],
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.workspace_premium, size: 16),
                                  label: const Text("VIP Kilidini Aç", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  onPressed: () {
                                    VipGarajEkrani.showPaywall(context, currentUser: widget.aktifKullanici);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : null,
              );
            }),
          ],

          const SizedBox(height: 8),

          // 4. İLGİ ALANLARI / HOBİLER ETİKETLERİ
          if (user.hobbies.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.interests, color: Colors.deepOrange, size: 18),
                      SizedBox(width: 6),
                      Text("SÜRÜŞ İLGİ ALANLARI", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.hobbies.map((hobi) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          hobi,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 5. GARAJ MOTORLARI KARTI
          if (user.garage.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.garage, color: Colors.deepOrange, size: 18),
                      SizedBox(width: 6),
                      Text("GARAJ", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...user.garage.map((motor) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.two_wheeler, color: Colors.deepOrange, size: 24),
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
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 6. EN SEVDİĞİ ROTA VE VİRAJ KARTI
          if (user.favoriteRoute.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.alt_route, color: Colors.cyanAccent, size: 18),
                      SizedBox(width: 6),
                      Text("FAVORİ ROTASI & VİRAJLARI", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.favoriteRoute,
                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 7. SÜRÜŞ FELSEFESİ & HEDEF KARTI
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.withValues(alpha: 0.15), const Color(0xFF1E1E1E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.format_quote, color: Colors.amber, size: 20),
                    SizedBox(width: 6),
                    Text(
                      "SÜRÜŞ FELSEFEM",
                      style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '"${user.ridingMotto}"',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                if (user.nextGoal.isNotEmpty) ...[
                  const Divider(color: Colors.white12, height: 20),
                  Row(
                    children: [
                      const Icon(Icons.flag_outlined, color: Colors.deepOrange, size: 16),
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
    ),
  );
}

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
