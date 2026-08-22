import 'package:flutter/material.dart';
import '../../models/user_model.dart';

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
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.deepOrange),
        title: const Row(
          children: [
            Icon(Icons.visibility, color: Colors.deepOrange, size: 20),
            SizedBox(width: 8),
            Text(
              "Profil Önizlemesi",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bilgilendirme Bannerı
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.deepOrange, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Diğer sürücüler seni Keşfet / Swipe ekranında tam olarak böyle görüyor.",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                // 1. ANA HERO FOTOĞRAF & İSİM BANNERI
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
                            const SizedBox(height: 4),
                            Text(
                              "${user.primaryMotor} • ${user.experienceLevel} Deneyim",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 2. MAKROMUSIC SES VE ŞARKI KARTI
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E2D24), Color(0xFF181E1A)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.headphones, color: Colors.greenAccent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "FAVORİ SÜRÜŞ ŞARKISI",
                              style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.favoriteTrack,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Egzoz Tınısı: ${user.exhaustSoundName}",
                              style: const TextStyle(color: Colors.amber, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.equalizer, color: Colors.greenAccent),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 3. EN SEVDİĞİ VİRAJLI ROTA
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.alt_route, color: Colors.deepOrange, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "EN ÇOK TURLAMAYI SEVDİĞİM ROTA",
                            style: TextStyle(color: Colors.deepOrange, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.favoriteRoute,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 4. İKİNCİ FOTOĞRAF
                if (photos.length > 1)
                  Container(
                    height: 280,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: _getImageProvider(photos[1]),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
                      ],
                    ),
                  ),

                // 5. BİYOGRAFİ
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
                      const Text(
                        "HAKKIMDA",
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"${user.bio}"',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              user.ridingStyle,
                              style: const TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              user.primaryMotorType,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 6. HOBİLER
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
                      const Text(
                        "SÜRÜŞ İLGİ ALANLARI & HOBİLER",
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.hobbies.map((hobby) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              hobby,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 7. ÜÇÜNCÜ FOTOĞRAF
                if (photos.length > 2)
                  Container(
                    height: 280,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: _getImageProvider(photos[2]),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
                      ],
                    ),
                  ),

                // 8. SÜRÜŞ FELSEFESİ
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
