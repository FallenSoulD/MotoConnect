import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class EditVibeSheet {
  static const List<String> experienceLevels = [
    "Yeni Başlayan (<1 Yıl)",
    "1 - 3 Yıl",
    "3 - 5 Yıl",
    "5 - 10 Yıl",
    "10+ Yıl / Usta Sürücü 👑",
  ];

  static const List<String> ridingStyles = [
    "Naked & Şehir",
    "Supersport / Racing ⚡",
    "Touring & Macera 🌍",
    "Enduro & Çamur 🪵",
    "Chopper & Cruiser 🦅",
    "Scooter & Maxi 🛵",
  ];

  static const List<String> availableHobbies = [
    "🏎️ Pist Günleri",
    "☕ Gece Kahvesi",
    "🎧 Intercom Muhabbeti",
    "🛠️ Kendim Bakım Yaparım",
    "⛺ Moto Kamp",
    "🪵 Çamur & Enduro",
    "📸 Moto Fotoğrafçılık",
    "⚙️ Quickshifter & Gazlama",
    "🌇 Gün Batımı Sürüşü",
    "🌙 Gece Sürüşü",
    "🛣️ Uzun Yol Turları",
    "🧗 Doğa Keşfi",
    "🎸 Rock & Blues",
    "🍕 Yol Üstü Lezzetleri",
    "🏁 Viraj Sevdalısı",
    "⚡ Grup Sürüşü",
  ];

  static void show(BuildContext context, {required MotoUser user, required VoidCallback onSaved}) {
    String selectedExp = experienceLevels.contains(user.experienceLevel)
        ? user.experienceLevel
        : (user.experienceLevel.isNotEmpty ? user.experienceLevel : experienceLevels[1]);

    String selectedStyle = ridingStyles.contains(user.ridingStyle)
        ? user.ridingStyle
        : (user.ridingStyle.isNotEmpty ? user.ridingStyle : ridingStyles[0]);

    final bioController = TextEditingController(text: user.bio);
    final trackController = TextEditingController(text: user.favoriteTrack);
    final exhaustController = TextEditingController(text: user.exhaustSoundName);
    final routeController = TextEditingController(text: user.favoriteRoute);
    final mottoController = TextEditingController(text: user.ridingMotto);
    final goalController = TextEditingController(text: user.nextGoal);
    final selectedHobbies = List<String>.from(user.hobbies);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.90,
              maxChildSize: 0.96,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    left: 20,
                    right: 20,
                    top: 20,
                  ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Başlık
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.tune, color: Colors.deepOrange, size: 26),
                              SizedBox(width: 10),
                              Text(
                                "Sürüş Kimliği & Deneyim",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Motosiklet sürüş tecrübeni, tarzını ve ilgi alanlarını diğer motorcuların görebileceği şekilde güncelle.",
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      const SizedBox(height: 20),

                      // 1. MOTOR SÜRÜŞ DENEYİMİ (TECRÜBE SÜRESİ) SEÇİMİ
                      const Row(
                        children: [
                          Icon(Icons.history_edu, color: Colors.amber, size: 18),
                          SizedBox(width: 6),
                          Text(
                            "SÜRÜCÜ MOTOR DENEYİM SÜRESİ",
                            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: experienceLevels.map((exp) {
                          final isSelected = selectedExp == exp;
                          return GestureDetector(
                            onTap: () => setSheetState(() => selectedExp = exp),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.amber[800] : const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? Colors.amberAccent : Colors.white24,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    exp,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.check_circle, color: Colors.white, size: 15),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // 2. SÜRÜŞ TARZI SEÇİMİ
                      const Row(
                        children: [
                          Icon(Icons.two_wheeler, color: Colors.deepOrange, size: 18),
                          SizedBox(width: 6),
                          Text(
                            "BİRİNCİL SÜRÜŞ TARZI",
                            style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ridingStyles.map((style) {
                          final isSelected = selectedStyle == style;
                          return GestureDetector(
                            onTap: () => setSheetState(() => selectedStyle = style),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.deepOrange : const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? Colors.deepOrangeAccent : Colors.white24,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    style,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.check, color: Colors.white, size: 15),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // 3. HOBİLER & İLGİ ALANLARI SEÇİMİ
                      const Text(
                        "SÜRÜŞ HOBİLERİ & İLGİ ALANLARI (Tıkla Seç)",
                        style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableHobbies.map((hobby) {
                          final isSelected = selectedHobbies.contains(hobby);
                          return GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                if (isSelected) {
                                  selectedHobbies.remove(hobby);
                                } else {
                                  if (selectedHobbies.length < 6) {
                                    selectedHobbies.add(hobby);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("En fazla 6 hobi seçebilirsin!"),
                                        backgroundColor: Colors.amber,
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.deepOrange : Colors.black38,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? Colors.deepOrange : Colors.white24,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    hobby,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.check, color: Colors.white, size: 14),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 22),

                      // 4. BİYOGRAFİ
                      TextField(
                        controller: bioController,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Hakkında / Biyografi",
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.badge, color: Colors.deepOrange),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 5. FAVORİ SÜRÜŞ ŞARKISI
                      TextField(
                        controller: trackController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Favori Sürüş Şarkın (Spotify)",
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.headphones, color: Colors.greenAccent),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 6. EGZOZ SESİ / MODELİ
                      TextField(
                        controller: exhaustController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Egzoz Modeli / Tınısı",
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.volume_up, color: Colors.amber),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 7. FAVORİ VİRAJLI ROTA
                      TextField(
                        controller: routeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "En Çok Sevdiğin Viraj Rotası",
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.alt_route, color: Colors.deepOrange),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 8. SÜRÜŞ FELSEFESİ / SLOGAN
                      TextField(
                        controller: mottoController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Sürüş Felsefen / Slogan",
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.format_quote, color: Colors.amber),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 9. GELECEK HEDEFİ
                      TextField(
                        controller: goalController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Motosikletle Gelecek Hedefin",
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.flag_outlined, color: Colors.deepOrange),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // KAYDET BUTONU
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            user.experienceLevel = selectedExp;
                            user.ridingStyle = selectedStyle;
                            user.bio = bioController.text.trim();
                            user.favoriteTrack = trackController.text.trim();
                            user.exhaustSoundName = exhaustController.text.trim();
                            user.favoriteRoute = routeController.text.trim();
                            user.ridingMotto = mottoController.text.trim();
                            user.nextGoal = goalController.text.trim();
                            user.hobbies = selectedHobbies;

                            await FirestoreService().updateUserSettings(
                              user.id,
                              experienceLevel: user.experienceLevel,
                              ridingStyle: user.ridingStyle,
                              bio: user.bio,
                              favoriteTrack: user.favoriteTrack,
                              exhaustSoundName: user.exhaustSoundName,
                              favoriteRoute: user.favoriteRoute,
                              ridingMotto: user.ridingMotto,
                              nextGoal: user.nextGoal,
                              hobbies: user.hobbies,
                            );

                            onSaved();
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Sürüş deneyimi ve kimliğin güncellendi! 🚀"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          child: const Text(
                            "Kaydet ve Profili Güncelle",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
