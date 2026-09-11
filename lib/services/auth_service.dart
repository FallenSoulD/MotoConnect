import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/user_model.dart';
import 'firestore_service.dart';
import 'purchase_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/userinfo.profile'],
    serverClientId: '331540286697-buf8pil3a75ee8s0c1eib3n2ftf0c830.apps.googleusercontent.com',
  );

  /// 1. GOOGLE SİGN-IN (Android, iOS & Web Desteği)
  Future<MotoUser?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // Web için doğrudan Firebase Auth Popup akışı
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Android & iOS için yerel Google Hesabı Seçici
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;
      final email = firebaseUser.email ?? "";

      // Aynı e-postanın başka bir hesapta olup olmadığını kontrol et
      if (email.isNotEmpty) {
        final isTaken = await FirestoreService().isEmailTakenByOtherUser(
          firebaseUser.uid,
          email,
        );
        if (isTaken) {
          // Başka bir hesap var, bu yüzden bu yeni auth hesabını da silebiliriz ki auth çöplük olmasın
          await firebaseUser.delete();
          throw Exception(
            "Bu e-posta adresi başka bir kayıt yöntemi ile zaten kullanılıyor. Lütfen doğru yöntemle giriş yapın.",
          );
        }
      }

      // RevenueCat'e Firebase UID'sini tanımla ve aboneliği senkronize et
      try {
        await PurchaseService().loginUser(firebaseUser.uid);
      } catch (_) {}

      // Kullanıcının Firestore Profilini Getir veya Yeni Oluştur
      var userProfile = await FirestoreService().getUserProfile(
        firebaseUser.uid,
      );
      if (userProfile == null) {
        final nickname =
            (firebaseUser.displayName != null &&
                firebaseUser.displayName!.isNotEmpty)
            ? firebaseUser.displayName!
            : (email.isNotEmpty ? email.split('@').first : "Google Sürücüsü");
        final photoUrl = firebaseUser.photoURL ?? "";

        userProfile = MotoUser(
          id: firebaseUser.uid,
          nickname: nickname,
          email: email,
          bio: "",
          gender: "Belirtmek İstemiyorum",
          ridingStyle: "Şehir İçi ve Manzara",
          experienceLevel: "1 Yıl",
          nextGoal: "Yeni rotalar keşfetmek",
          garage: [],
          imageUrls: photoUrl.isNotEmpty ? [photoUrl] : [],
          hobbies: ["☕ Gece Kahvesi", "🎧 Intercom Muhabbeti"],
        );

        await FirestoreService().createUserProfile(userProfile, email: email);
      }

      return userProfile;
    } catch (e) {
      debugPrint("AuthService signInWithGoogle error: $e");
      return null;
    }
  }

  /// 2. GERÇEK APPLE & FACE ID SİGN-IN (iOS Native Face ID/Touch ID, Web Popup & Android OAuth)
  Future<MotoUser?> signInWithApple() async {
    try {
      UserCredential userCredential;
      String? appleGivenName;
      String? appleFamilyName;

      if (kIsWeb) {
        // Web: Resmi Firebase Apple Auth Popup
        final AppleAuthProvider appleProvider = AppleAuthProvider();
        appleProvider.addScope('email');
        appleProvider.addScope('name');
        userCredential = await _auth.signInWithPopup(appleProvider);
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        // iOS & macOS: Yerel Face ID / Touch ID / Apple ID ile Güvenli Giriş
        final rawNonce = _generateNonce();
        final nonce = _sha256ofString(rawNonce);

        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        );

        if (appleCredential.givenName != null ||
            appleCredential.familyName != null) {
          appleGivenName = appleCredential.givenName;
          appleFamilyName = appleCredential.familyName;
        }

        final OAuthCredential credential = OAuthProvider('apple.com')
            .credential(
              idToken: appleCredential.identityToken,
              rawNonce: rawNonce,
            );

        userCredential = await _auth.signInWithCredential(credential);
      } else {
        // Android & Diğer Platformlar: Standart Apple OAuth Provider
        final AppleAuthProvider appleProvider = AppleAuthProvider();
        appleProvider.addScope('email');
        appleProvider.addScope('name');
        userCredential = await _auth.signInWithProvider(appleProvider);
      }

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;

      final email = firebaseUser.email ?? "";

      // Kullanıcı Adını Belirle (Apple'ın sağladığı Ad Soyad, Firebase DisplayName veya E-Posta ön eki)
      String nickname = "";
      if (appleGivenName != null && appleGivenName.isNotEmpty) {
        nickname = "$appleGivenName ${appleFamilyName ?? ''}".trim();
      } else if (firebaseUser.displayName != null &&
          firebaseUser.displayName!.isNotEmpty) {
        nickname = firebaseUser.displayName!;
      } else if (email.isNotEmpty) {
        nickname = email.split('@').first;
      } else {
        nickname = "Apple Sürücüsü";
      }
      // Aynı e-postanın başka bir hesapta olup olmadığını kontrol et
      if (email.isNotEmpty) {
        final isTaken = await FirestoreService().isEmailTakenByOtherUser(
          firebaseUser.uid,
          email,
        );
        if (isTaken) {
          await firebaseUser.delete();
          throw Exception(
            "Bu e-posta adresi başka bir kayıt yöntemi ile zaten kullanılıyor. Lütfen doğru yöntemle giriş yapın.",
          );
        }
      }

      // RevenueCat senkronizasyonu
      try {
        await PurchaseService().loginUser(firebaseUser.uid);
      } catch (_) {}

      // Kullanıcının Firestore Profilini Getir veya Yeni Oluştur
      var userProfile = await FirestoreService().getUserProfile(
        firebaseUser.uid,
      );
      if (userProfile == null) {
        userProfile = MotoUser(
          id: firebaseUser.uid,
          nickname: nickname,
          email: email,
          bio: "Apple Kimliği ile bağlandı. 🏍️ ",
          gender: "Belirtmek İstemiyorum",
          ridingStyle: "Şehir İçi ve Manzara",
          experienceLevel: "1 Yıl",
          nextGoal: "Yeni rotalar keşfetmek",
          garage: [],
          imageUrls:
              (firebaseUser.photoURL != null &&
                  firebaseUser.photoURL!.isNotEmpty)
              ? [firebaseUser.photoURL!]
              : [],
          hobbies: ["☕ Gece Kahvesi", "🎧 Intercom Muhabbeti"],
        );

        await FirestoreService().createUserProfile(userProfile, email: email);
      } else {
        if (nickname.isNotEmpty &&
            (userProfile.nickname.isEmpty ||
                userProfile.nickname == "Apple Sürücüsü")) {
          userProfile.nickname = nickname;
          if (email.isNotEmpty && userProfile.email.isEmpty) {
            userProfile.email = email;
          }
          await FirestoreService().updateUserProfile(userProfile);
        }
      }

      return userProfile;
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint("Apple Authorization Exception: ${e.code} - ${e.message}");
      if (e.code == AuthorizationErrorCode.canceled ||
          e.code == AuthorizationErrorCode.unknown) {
        return null;
      }
      rethrow;
    } on FirebaseAuthException catch (e) {
      debugPrint("Apple FirebaseAuthException: ${e.code} - ${e.message}");
      if (e.code == 'canceled' ||
          e.code == 'popup-closed-by-user' ||
          e.code == 'user-cancelled') {
        return null;
      }
      rethrow;
    } catch (e) {
      debugPrint("AuthService signInWithApple error: $e");
      rethrow;
    }
  }

  /// Güvenli Apple Nonce Üreticisi
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// SHA256 Şifreleyici
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 3. E-POSTA & ŞİFRE GİRİŞİ VEYA KAYIT
  Future<MotoUser?> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;

    await PurchaseService().loginUser(user.uid);
    return await FirestoreService().getUserProfile(user.uid);
  }

  Future<MotoUser?> signUpWithEmail(
    String email,
    String password,
    String nickname, {
    String gender = "Belirtmek İstemiyorum",
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;

    await user.updateDisplayName(nickname);
    await PurchaseService().loginUser(user.uid);

    final userProfile = MotoUser(
      id: user.uid,
      nickname: nickname.isNotEmpty
          ? nickname
          : (user.email?.split('@').first ?? "Sürücü"),
      email: email,
      bio: "Merhaba! MotoConnect'e katıldım. Tekerin düz bassın! 🏍️",
      gender: gender,
      ridingStyle: "Şehir İçi ve Manzara",
      experienceLevel: "1 Yıl",
      nextGoal: "Yeni rotalar keşfetmek",
      garage: [],
      imageUrls: [],
      favoriteTrack: "",
      exhaustSoundName: "",
      favoriteRoute: "",
      ridingMotto: "Tekerin her zaman düz bassın!",
      hobbies: ["☕ Gece Kahvesi", "🎧 Intercom Muhabbeti"],
    );

    await FirestoreService().createUserProfile(userProfile, email: email);
    return userProfile;
  }

  // ---------------- PHONE AUTHENTICATION ----------------
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(FirebaseAuthException e) verificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Otomatik doğrulama Android'de bazen desteklenir
      },
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<MotoUser?> signInWithPhoneOTP({
    required String verificationId,
    required String smsCode,
    String? nickname,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) return null;

    var userProfile = await FirestoreService().getUserProfile(user.uid);
    if (userProfile == null) {
      userProfile = MotoUser(
        id: user.uid,
        nickname: (nickname != null && nickname.isNotEmpty) ? nickname : "Sürücü",
        email: "",
        phoneNumber: user.phoneNumber ?? "",
        bio: "Merhaba! MotoConnect'e katıldım. Tekerin düz bassın! 🏍️",
        gender: "Belirtmek İstemiyorum",
        ridingStyle: "Şehir İçi ve Manzara",
        experienceLevel: "Yeni Başlayan",
        nextGoal: "Yeni rotalar keşfetmek",
        garage: [],
        imageUrls: [],
        hobbies: ["🏍️ Sürüş", "☕ Gece Kahvesi"],
      );
      await FirestoreService().createUserProfile(userProfile);
    }
    return userProfile;
  }

  /// 4. ÇIKIŞ YAP (Oturumu Kapat)
  Future<void> signOut() async {
    try {
      await PurchaseService().logoutUser();
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
