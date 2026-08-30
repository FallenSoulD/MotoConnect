import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/neumorphic_widgets.dart';

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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.90,
              maxChildSize: 0.96,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return NeuContainer(
                  borderRadius: 28,
                  color: NeuColors.surfaceDark,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    left: 20,
                    right: 20,
                    top: 16,
                  ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Başlık
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.tune, color: NeuColors.accentOrange, size: 24),
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
                          NeuIconButton(
                            icon: Icons.close,
                            size: 36,
                            iconSize: 18,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Motosiklet sürüş tecrübeni, tarzını ve ilgi alanlarını diğer motorcuların görebileceği şekilde güncelle.",
                        style: TextStyle(color: Colors.white54, fontSize: 12.5),
                      ),
                      const SizedBox(height: 20),

                      // 1. MOTOR SÜRÜŞ DENEYİMİ
                      const Row(
                        children: [
                          Icon(Icons.history_edu, color: NeuColors.accentAmber, size: 18),
                          SizedBox(width: 6),
                          Text(
                            "SÜRÜCÜ MOTOR DENEYİM SÜRESİ",
                            style: TextStyle(color: NeuColors.accentAmber, fontWeight: FontWeight.bold, fontSize: 11.5, letterSpacing: 1),
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
                            child: NeuContainer(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              borderRadius: 14,
                              style: isSelected ? NeuStyle.sunken : NeuStyle.raised,
                              color: isSelected ? NeuColors.accentAmber.withValues(alpha: 0.2) : NeuColors.surface,
                              borderColor: isSelected ? NeuColors.accentAmber : Colors.white.withValues(alpha: 0.05),
                              borderWidth: isSelected ? 1.5 : 1,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    exp,
                                    style: TextStyle(
                                      color: isSelected ? NeuColors.accentAmber : Colors.white70,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.check_circle, color: NeuColors.accentAmber, size: 15),
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
                          Icon(Icons.two_wheeler, color: NeuColors.accentOrange, size: 18),
                          SizedBox(width: 6),
                          Text(
                            "BİRİNCİL SÜRÜŞ TARZI",
                            style: TextStyle(color: NeuColors.accentOrange, fontWeight: FontWeight.bold, fontSize: 11.5, letterSpacing: 1),
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
                            child: NeuContainer(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              borderRadius: 14,
                              style: isSelected ? NeuStyle.sunken : NeuStyle.raised,
                              color: isSelected ? NeuColors.accentOrange.withValues(alpha: 0.2) : NeuColors.surface,
                              borderColor: isSelected ? NeuColors.accentOrange : Colors.white.withValues(alpha: 0.05),
                              borderWidth: isSelected ? 1.5 : 1,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    style,
                                    style: TextStyle(
                                      color: isSelected ? NeuColors.accentOrange : Colors.white70,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.check, color: NeuColors.accentOrange, size: 15),
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
                        style: TextStyle(color: NeuColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 11.5, letterSpacing: 1),
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
                            child: NeuContainer(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              borderRadius: 14,
                              style: isSelected ? NeuStyle.sunken : NeuStyle.raised,
                              color: isSelected ? NeuColors.accentCyan.withValues(alpha: 0.2) : NeuColors.surface,
                              borderColor: isSelected ? NeuColors.accentCyan : Colors.white.withValues(alpha: 0.05),
                              borderWidth: isSelected ? 1.5 : 1,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    hobby,
                                    style: TextStyle(
                                      color: isSelected ? NeuColors.accentCyan : Colors.white70,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.check, color: NeuColors.accentCyan, size: 14),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 22),

                      // 4. BİYOGRAFİ
                      NeuTextField(
                        controller: bioController,
                        labelText: "Hakkında / Biyografi",
                        hintText: "Kendini ve sürüş tutkunu anlat...",
                        prefixIcon: Icons.badge_outlined,
                        maxLines: 3,
                        minLines: 2,
                      ),

                      const SizedBox(height: 14),

                      // 5. FAVORİ SÜRÜŞ ŞARKISI
                      NeuTextField(
                        controller: trackController,
                        labelText: "Favori Sürüş Şarkın",
                        hintText: "Şarkı ve sanatçı adı...",
                        prefixIcon: Icons.headphones,
                      ),

                      const SizedBox(height: 14),

                      // 6. EGZOZ SESİ / MODELİ
                      NeuTextField(
                        controller: exhaustController,
                        labelText: "Egzoz Modeli / Tınısı",
                        hintText: "Akrapovic, Yoshimura, SC Project vb.",
                        prefixIcon: Icons.volume_up,
                      ),

                      const SizedBox(height: 14),

                      // 7. FAVORİ VİRAJLI ROTA
                      NeuTextField(
                        controller: routeController,
                        labelText: "En Çok Sevdiğin Viraj Rotası",
                        hintText: "Şile Virajları, Riva Yolu vb.",
                        prefixIcon: Icons.alt_route,
                      ),

                      const SizedBox(height: 14),

                      // 8. SÜRÜŞ FELSEFESİ / SLOGAN
                      NeuTextField(
                        controller: mottoController,
                        labelText: "Sürüş Felsefen / Slogan",
                        hintText: "Kısa bir motorcu sözü...",
                        prefixIcon: Icons.format_quote,
                      ),

                      const SizedBox(height: 14),

                      // 9. GELECEK HEDEFİ
                      NeuTextField(
                        controller: goalController,
                        labelText: "Motosikletle Gelecek Hedefin",
                        hintText: "Balkan Turu, Pist Derecesi vb.",
                        prefixIcon: Icons.flag_outlined,
                      ),

                      const SizedBox(height: 26),

                      // KAYDET BUTONU
                      NeuButton(
                        text: "Kaydet ve Profili Güncelle",
                        icon: Icons.check_circle_outline,
                        isPrimary: true,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
