import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/purchase_service.dart';
import '../../widgets/neumorphic_widgets.dart';
import '../main_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: NeuColors.background,
            body: Center(
              child: NeuContainer(
                width: 70,
                height: 70,
                borderRadius: 35,
                depth: 4,
                child: Center(
                  child: CircularProgressIndicator(color: NeuColors.accentOrange),
                ),
              ),
            ),
          );
        }

        final firebaseUser = authSnapshot.data;
        if (firebaseUser != null) {
          // RevenueCat oturumunu ve aktif abonelik durumunu arka planda kontrol et
          PurchaseService().loginUser(firebaseUser.uid);

          return StreamBuilder<MotoUser?>(
            stream: FirestoreService().streamUserProfile(firebaseUser.uid),
            builder: (context, userSnapshot) {
              // 1. Profil Firestore'dan yüklendiyse ban kontrolü yap
              if (userSnapshot.hasData && userSnapshot.data != null) {
                final profile = userSnapshot.data!;
                // BANLI KULLANICI KONTROLÜ
                if (profile.isBanned) {
                  return Scaffold(
                    backgroundColor: NeuColors.background,
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: NeuContainer(
                          padding: const EdgeInsets.all(28),
                          borderRadius: 24,
                          depth: 6,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.block, color: Colors.redAccent, size: 64),
                              const SizedBox(height: 16),
                              const Text(
                                "Hesabınız Askıya Alındı",
                                style: TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Topluluk kurallarını ihlal ettiğiniz tespit edilmiştir. Hesabınız moderasyon ekibi tarafından askıya alınmıştır.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                              ),
                              const SizedBox(height: 24),
                              NeuButton(
                                color: Colors.red[900],
                                text: "Çıkış Yap",
                                onPressed: () => FirebaseAuth.instance.signOut(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return MainScreen(aktifKullanici: profile);
              }

              // 2. Profil yüklenirken veya yeni hesapsa bekletmeden anında aç
              final nickname = (firebaseUser.displayName != null && firebaseUser.displayName!.isNotEmpty)
                  ? firebaseUser.displayName!
                  : (firebaseUser.email?.split('@').first ?? "Sürücü");

              final initialUser = MotoUser(
                id: firebaseUser.uid,
                nickname: nickname,
                email: firebaseUser.email ?? "",
                bio: "Merhaba! MotoConnect'e katıldım. Tekerin düz bassın! 🏍️",
                ridingStyle: "Şehir İçi ve Manzara",
                experienceLevel: "1 Yıl",
                nextGoal: "Yeni rotalar keşfetmek",
                garage: [],
                imageUrls: firebaseUser.photoURL != null ? [firebaseUser.photoURL!] : [],
                favoriteTrack: "Moda - Bostancı Sahil Yolu",
                exhaustSoundName: "Akrapovič Tok Ton",
                favoriteRoute: "Şile - Ağva Virajları",
                ridingMotto: "Tekerin her zaman düz bassın!",
                hobbies: ["☕ Gece Kahvesi", "🎧 Intercom Muhabbeti"],
              );

              return MainScreen(aktifKullanici: initialUser);
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}
