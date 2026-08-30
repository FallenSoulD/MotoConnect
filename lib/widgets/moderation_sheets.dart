import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/garage/legal_docs_sheet.dart';
import '../main.dart';
import 'neumorphic_widgets.dart';

class ModerationSheets {
  /// Kullanıcı veya İçerik Şikayet Etme Modalı
  static void showReportSheet(
    BuildContext context, {
    required String currentUserId,
    required MotoUser targetUser,
  }) {
    String selectedReason = "Uygunsuz Profil Fotoğrafı";
    final detailsController = TextEditingController();

    final List<String> reasons = [
      "Uygunsuz Profil Fotoğrafı",
      "Taciz / Rahatsız Edici Mesajlaşma",
      "Sahte Profil / Başkasının Motoru",
      "Tehlikeli / Kural Dışı Sürüş Teşviki",
      "Diğer",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return NeuContainer(
              borderRadius: 28,
              color: NeuColors.surfaceDark,
              borderColor: Colors.redAccent.withValues(alpha: 0.4),
              borderWidth: 1.5,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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

                    Row(
                      children: [
                        const Icon(Icons.report_problem_outlined, color: Colors.redAccent, size: 26),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "${targetUser.nickname} Kullanıcısını Şikayet Et",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        NeuIconButton(
                          icon: Icons.close,
                          size: 36,
                          iconSize: 18,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "MotoConnect topluluk kurallarına uymayan davranışları lütfen bize bildir.",
                      style: TextStyle(color: Colors.white54, fontSize: 12.5),
                    ),
                    const SizedBox(height: 16),
                    ...reasons.map((reason) {
                      final isSelected = selectedReason == reason;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedReason = reason),
                        child: NeuContainer(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          borderRadius: 14,
                          style: isSelected ? NeuStyle.sunken : NeuStyle.raised,
                          color: isSelected ? NeuColors.accentOrange.withValues(alpha: 0.18) : NeuColors.surface,
                          borderColor: isSelected ? NeuColors.accentOrange : Colors.white.withValues(alpha: 0.05),
                          borderWidth: isSelected ? 1.5 : 1,
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? NeuColors.accentOrange : Colors.white38,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    NeuTextField(
                      controller: detailsController,
                      maxLines: 2,
                      hintText: "Ek açıklama veya detay (Opsiyonel)",
                      prefixIcon: Icons.edit_note,
                    ),
                    const SizedBox(height: 20),
                    NeuButton(
                      text: "Şikayeti Gönder",
                      icon: Icons.send,
                      color: Colors.red[900],
                      textColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      onPressed: () {
                        final details = detailsController.text.trim();
                        Navigator.pop(context);
                        FirestoreService().reportUser(
                          reporterId: currentUserId,
                          reportedUserId: targetUser.id,
                          reportedNickname: targetUser.nickname,
                          reason: selectedReason,
                          details: details,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("✅ Şikayetiniz moderasyon ekibimize iletildi. İnceleme başlatıldı."),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Kullanıcı Engelleme Onay Penceresi
  static void showBlockDialog(
    BuildContext context, {
    required String currentUserId,
    required MotoUser targetUser,
    required VoidCallback onBlocked,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: NeuContainer(
          padding: const EdgeInsets.all(22),
          borderRadius: 22,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.block, color: Colors.redAccent, size: 24),
                  const SizedBox(width: 10),
                  Text("${targetUser.nickname}'ı Engelle", style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                "${targetUser.nickname} adlı kullanıcıyı engellemek istediğine emin misin?\n\nBu kullanıcı artık radarında, swipe ekranında ve sohbet listende görünmeyecek.",
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: NeuButton(
                      text: "İptal",
                      color: NeuColors.surfaceDark,
                      textColor: Colors.white60,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeuButton(
                      text: "Engelle",
                      color: Colors.red[800],
                      textColor: Colors.white,
                      onPressed: () async {
                        Navigator.pop(context);
                        await FirestoreService().blockUser(currentUserId, targetUser.id);
                        onBlocked();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${targetUser.nickname} engellendi."),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      },
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

  /// Hesabımı ve Verilerimi Kalıcı Silme Penceresi
  static void showDeleteAccountDialog(BuildContext context, {required MotoUser currentUser}) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: NeuContainer(
          padding: const EdgeInsets.all(22),
          borderRadius: 22,
          borderColor: Colors.redAccent.withValues(alpha: 0.6),
          borderWidth: 1.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.delete_forever, color: Colors.redAccent, size: 26),
                  SizedBox(width: 10),
                  Text("Hesabı Kalıcı Olarak Sil", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                "Bu işlem geri alınamaz!\n\nProfilin, garajındaki tüm motosikletler, fotoğrafların, sürüş geçmişin ve mesajların tamamen silinecektir.",
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: NeuButton(
                      text: "Vazgeç",
                      color: NeuColors.surfaceDark,
                      textColor: Colors.white60,
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeuButton(
                      text: "Kalıcı Sil",
                      color: Colors.red[900],
                      textColor: Colors.white,
                      onPressed: () async {
                        Navigator.pop(dialogContext);

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (loadingCtx) => const PopScope(
                            canPop: false,
                            child: Dialog(
                              backgroundColor: Colors.transparent,
                              child: NeuContainer(
                                padding: EdgeInsets.all(20),
                                borderRadius: 16,
                                child: Row(
                                  children: [
                                    CircularProgressIndicator(color: Colors.redAccent),
                                    SizedBox(width: 18),
                                    Expanded(
                                      child: Text(
                                        "Hesabınız ve verileriniz siliniyor...",
                                        style: TextStyle(color: Colors.white, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );

                        await FirestoreService().deleteUserAccount(currentUser.id);

                        navigatorKey.currentState?.pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
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

  /// Gizlilik Politikası & Kullanım Koşulları Modalı
  static void showPrivacyPolicySheet(BuildContext context) {
    LegalDocsSheet.show(context, docType: LegalDocType.privacyPolicy);
  }

  /// Engellenen Kullanıcılar Listesi Modalı
  static void showBlockedUsersSheet(
    BuildContext context, {
    required MotoUser currentUser,
    required VoidCallback onUnblocked,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return NeuContainer(
              borderRadius: 28,
              color: NeuColors.surfaceDark,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.block, color: Colors.redAccent, size: 22),
                          SizedBox(width: 10),
                          Text("Engellenen Kullanıcılar", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
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
                  const SizedBox(height: 16),
                  if (currentUser.blockedUserIds.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text("Engellediğin herhangi bir kullanıcı yok.", style: TextStyle(color: Colors.white54)),
                      ),
                    )
                  else
                    ...currentUser.blockedUserIds.map((blockedId) {
                      return NeuContainer(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        borderRadius: 14,
                        child: Row(
                          children: [
                            const Icon(Icons.person_off, color: Colors.redAccent, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text("Kullanıcı ($blockedId)", style: const TextStyle(color: Colors.white, fontSize: 13.5)),
                            ),
                            NeuButton(
                              text: "Kaldır",
                              color: NeuColors.surfaceDark,
                              textColor: NeuColors.accentOrange,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              borderRadius: 10,
                              onPressed: () async {
                                await FirestoreService().unblockUser(currentUser.id, blockedId);
                                currentUser.unblockUser(blockedId);
                                setSheetState(() {});
                                onUnblocked();
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
