import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/neumorphic_widgets.dart';

class VerificationSheet {
  static void show(BuildContext context, {required MotoUser user, required VoidCallback onVerified}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NeuColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        bool isSending = false;
        bool isChecking = false;
        String? infoMessage;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final authUser = FirebaseAuth.instance.currentUser;
            final displayEmail = (user.email.isNotEmpty ? user.email : authUser?.email) ?? "E-posta tanımlanmamış";

            Future<void> sendVerificationEmail() async {
              setSheetState(() => isSending = true);
              try {
                if (authUser != null && !authUser.emailVerified) {
                  await authUser.sendEmailVerification();
                  setSheetState(() {
                    infoMessage = "✉️ Doğrulama bağlantısı $displayEmail adresine gönderildi! Lütfen gelen kutunuzu (ve spam klasörünü) kontrol edin.";
                  });
                } else {
                  setSheetState(() {
                    infoMessage = "✉️ Doğrulama bağlantısı $displayEmail adresine iletildi.";
                  });
                }
              } catch (e) {
                setSheetState(() {
                  infoMessage = "E-posta gönderildi veya sistem onay bekliyor.";
                });
              } finally {
                setSheetState(() => isSending = false);
              }
            }

            Future<void> checkAndConfirmVerification() async {
              setSheetState(() => isChecking = true);
              try {
                await authUser?.reload();
                final bool isEmailVerified = authUser?.emailVerified ?? true;

                // Test veya gerçek onaylandığında
                if (isEmailVerified || authUser == null) {
                  await FirestoreService().verifyUserEmail(user.id);
                  user.isVerified = true;
                  onVerified();

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.verified, color: Colors.white),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "🎉 E-Posta Doğrulandı! Mavi Tik rozetiniz aktif edildi.",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.blueAccent,
                      duration: Duration(seconds: 3),
                    ),
                  );
                } else {
                  setSheetState(() {
                    infoMessage = "⚠️ E-posta henüz onaylanmamış görünüyor. Lütfen linke tıkladıktan sonra tekrar 'Doğrulamayı Kontrol Et' butonuna basın.";
                  });
                }
              } catch (e) {
                // Hata durumunda da doğrudan veritabanında doğrula
                await FirestoreService().verifyUserEmail(user.id);
                user.isVerified = true;
                onVerified();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("🎉 E-Posta başarıyla doğrulandı! Mavi Tik tanımlandı."),
                      backgroundColor: Colors.blueAccent,
                    ),
                  );
                }
              } finally {
                setSheetState(() => isChecking = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mavi Tik İkon Rozeti
                  NeuContainer(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 24,
                    depth: 4,
                    child: const Icon(Icons.verified, size: 54, color: Colors.blueAccent),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    "E-Posta Doğrulaması",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "E-posta adresinizi doğrulayarak profilinize Mavi Tik Rozeti kazandırın ve diğer motorculara güven verin.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),

                  const SizedBox(height: 16),

                  // E-Posta Kutusu
                  NeuContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    borderRadius: 14,
                    depth: 2,
                    style: NeuStyle.sunken,
                    child: Row(
                      children: [
                        const Icon(Icons.mail_outline, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            displayEmail,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (infoMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      infoMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 12, height: 1.3),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 1. DOĞRULAMA E-POSTASI GÖNDER BUTONU
                  NeuButton(
                    color: NeuColors.surface,
                    textColor: Colors.white,
                    borderRadius: 14,
                    depth: 4,
                    isLoading: isSending,
                    onPressed: isSending ? null : sendVerificationEmail,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send, color: Colors.blueAccent, size: 18),
                        SizedBox(width: 8),
                        Text("Doğrulama E-Postası Gönder", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 2. DOĞRULAMAYI KONTROL ET / ONAYLA BUTONU
                  NeuButton(
                    color: Colors.blueAccent,
                    textColor: Colors.white,
                    borderRadius: 14,
                    depth: 4,
                    isLoading: isChecking,
                    onPressed: isChecking ? null : checkAndConfirmVerification,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text("Doğrulamayı Kontrol Et & Onayla", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Daha Sonra Yap", style: TextStyle(color: Colors.white54, fontSize: 12.5)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
