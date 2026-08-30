import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../widgets/neumorphic_widgets.dart';
class ProfilePreviewScreen extends StatelessWidget {
  final MotoUser user;

  const ProfilePreviewScreen({super.key, required this.user});

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http') || path.startsWith('blob:')) {
      return NetworkImage(path);
    }
    return NetworkImage(path);
  }

  @override
  Widget build(BuildContext context) {
    final photos = user.imageUrls.isNotEmpty
        ? user.imageUrls
        : ["https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800"];

    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        backgroundColor: NeuColors.surfaceDark,
        title: const Row(
          children: [
            Icon(Icons.visibility, color: NeuColors.accentOrange, size: 20),
            SizedBox(width: 8),
            Text(
              "Profil Önizlemesi",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.5),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bilgilendirme Bannerı
            NeuContainer(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              borderRadius: 16,
              color: NeuColors.surfaceDark,
              borderColor: NeuColors.accentOrange.withValues(alpha: 0.4),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: NeuColors.accentOrange, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Diğer sürücüler seni Keşfet / Swipe ekranında tam olarak böyle görüyor.",
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),

            // 1. ANA HERO FOTOĞRAF & İSİM BANNERI
            NeuContainer(
              height: 390,
              borderRadius: 24,
              padding: EdgeInsets.zero,
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
                                fontSize: 26,
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
                          spacing: 6,
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

            // 2. SES VE ŞARKI KARTI
            NeuCard(
              borderColor: NeuColors.accentGreen.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: NeuColors.accentGreen.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.headphones, color: NeuColors.accentGreen, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "FAVORİ SÜRÜŞ ŞARKISI",
                          style: TextStyle(color: NeuColors.accentGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.favoriteTrack.isNotEmpty ? user.favoriteTrack : "Belirtilmedi",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        if (user.exhaustSoundName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            "Egzoz: ${user.exhaustSoundName}",
                            style: const TextStyle(color: NeuColors.accentAmber, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.equalizer, color: NeuColors.accentGreen),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 3. EN SEVDİĞİ VİRAJLI ROTA
            NeuCard(
              title: "EN ÇOK TURLAMAYI SEVDİĞİM ROTA",
              icon: Icons.alt_route,
              iconColor: NeuColors.accentOrange,
              child: Text(
                user.favoriteRoute.isNotEmpty ? user.favoriteRoute : "Rota eklenmedi",
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            // 4. İKİNCİ FOTOĞRAF
            if (photos.length > 1)
              NeuContainer(
                height: 280,
                borderRadius: 20,
                padding: EdgeInsets.zero,
                margin: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image(
                    image: _getImageProvider(photos[1]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // 5. BİYOGRAFİ
            NeuCard(
              title: "HAKKIMDA",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.bio.isNotEmpty ? '"${user.bio}"' : '"Yollarda görüşürüz!"',
                    style: const TextStyle(color: Colors.white, fontSize: 14.5, fontStyle: FontStyle.italic, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      NeuBadge(text: user.ridingStyle, color: NeuColors.accentOrange),
                      const SizedBox(width: 8),
                      NeuBadge(text: user.primaryMotorType, color: Colors.white70),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 6. HOBİLER
            NeuCard(
              title: "SÜRÜŞ İLGİ ALANLARI & HOBİLER",
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.hobbies.map((hobby) {
                  return NeuBadge(
                    text: hobby,
                    color: NeuColors.accentCyan,
                    fontSize: 11.5,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // 7. ÜÇÜNCÜ FOTOĞRAF
            if (photos.length > 2)
              NeuContainer(
                height: 280,
                borderRadius: 20,
                padding: EdgeInsets.zero,
                margin: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image(
                    image: _getImageProvider(photos[2]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // 3'TEN FAZLA FOTOĞRAFLAR (BLURLU)
            if (photos.length > 3)
              ...photos.asMap().entries.skip(3).map((entry) {
                return NeuContainer(
                  height: 280,
                  borderRadius: 20,
                  padding: EdgeInsets.zero,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image(
                          image: _getImageProvider(entry.value),
                          fit: BoxFit.cover,
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14.0, sigmaY: 14.0),
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
                                  "Bu ve sonraki fotoğrafları görmek için VIP üyelik alınız.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
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

            // 8. SÜRÜŞ FELSEFESİ
            NeuCard(
              title: "SÜRÜŞ FELSEFEM",
              icon: Icons.format_quote,
              iconColor: NeuColors.accentAmber,
              borderColor: NeuColors.accentAmber.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.ridingMotto.isNotEmpty ? '"${user.ridingMotto}"' : '"Rüzgarın yönünü hissederek gazla."',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, height: 1.3),
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
          ],
        ),
      ),
    );
  }
}
