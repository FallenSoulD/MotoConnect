import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/garage/legal_docs_sheet.dart';
import '../main.dart';

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
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.report_problem_outlined, color: Colors.redAccent, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "${targetUser.nickname} Kullanıcısını Şikayet Et",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "MotoConnect topluluk kurallarına uymayan davranışları lütfen bize bildir.",
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ...reasons.map((reason) {
                      final isSelected = selectedReason == reason;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedReason = reason),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.deepOrange.withValues(alpha: 0.2) : Colors.black26,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? Colors.deepOrange : Colors.white10,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? Colors.deepOrange : Colors.white38,
                                size: 20,
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
                    TextField(
                      controller: detailsController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Ek açıklama veya detay (Opsiyonel)",
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
                        child: const Text(
                          "Şikayeti Gönder",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
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
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.block, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text("${targetUser.nickname}'ı Engelle", style: const TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Text(
          "${targetUser.nickname} adlı kullanıcıyı engellemek istediğine emin misin?\n\nBu kullanıcı artık radarında, swipe ekranında ve sohbet listende görünmeyecek ve sana mesaj atamayacak.",
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
            child: const Text("Engelle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Apple & Google Zorunlu: Hesabımı ve Verilerimi Kalıcı Silme Penceresi
  static void showDeleteAccountDialog(BuildContext context, {required MotoUser currentUser}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text("Hesabımı Kalıcı Olarak Sil", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Bu işlem geri alınamaz!\n\nProfilin, garajındaki tüm motosikletler, fotoğrafların, sürüş geçmişin ve mesajların tamamen silinecektir. Devam etmek istiyor musun?",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Vazgeç", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);

              // 1. Yükleniyor diyaloğu göster
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingCtx) => const PopScope(
                  canPop: false,
                  child: AlertDialog(
                    backgroundColor: Color(0xFF1E1E1E),
                    content: Row(
                      children: [
                        CircularProgressIndicator(color: Colors.redAccent),
                        SizedBox(width: 20),
                        Expanded(
                          child: Text(
                            "Hesabınız ve tüm verileriniz siliniyor...",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              // 2. Firestore ve Auth verilerini eksiksiz silmeyi bekle
              await FirestoreService().deleteUserAccount(currentUser.id);

              // 3. LoginScreen'e yönlendir
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("Kalıcı Olarak Sil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
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
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.block, color: Colors.redAccent),
                      SizedBox(width: 10),
                      Text("Engellenen Kullanıcılar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
                      return ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.white12, child: Icon(Icons.person_off, color: Colors.redAccent)),
                        title: Text("Kullanıcı ($blockedId)", style: const TextStyle(color: Colors.white, fontSize: 14)),
                        trailing: TextButton(
                          onPressed: () async {
                            await FirestoreService().unblockUser(currentUser.id, blockedId);
                            currentUser.unblockUser(blockedId);
                            setSheetState(() {});
                            onUnblocked();
                          },
                          child: const Text("Engeli Kaldır", style: TextStyle(color: Colors.deepOrange)),
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
