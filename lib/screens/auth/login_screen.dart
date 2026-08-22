import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/neumorphic_widgets.dart';
import '../../widgets/google_account_picker_sheet.dart';
import '../garage/legal_docs_sheet.dart';
import '../main_screen.dart';
import '../../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _selectedTabIndex = 0; // 0: Giriş Yap, 1: Kayıt Ol
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _anaEkranaGec(MotoUser user) {
    if (!mounted) return;
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainScreen(aktifKullanici: user)),
      (route) => false,
    );
  }

  // Google ile Giriş
  Future<void> _handleGoogleAuth() async {
    if (kIsWeb) {
      GoogleAccountPickerSheet.show(
        context,
        onAccountSelected: (user) => _anaEkranaGec(user),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await AuthService().signInWithGoogle();
      if (user != null) {
        _anaEkranaGec(user);
      } else {
        if (mounted) {
          GoogleAccountPickerSheet.show(
            context,
            onAccountSelected: (u) => _anaEkranaGec(u),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        GoogleAccountPickerSheet.show(
          context,
          onAccountSelected: (u) => _anaEkranaGec(u),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Gerçek Apple & Face ID ile Giriş
  Future<void> _handleAppleAuth() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService().signInWithApple();
      if (user != null) {
        _anaEkranaGec(user);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = "Apple ile giriş başarısız!";
        if (e.code == 'account-exists-with-different-credential') {
          msg = "Bu e-posta başka bir giriş yöntemiyle ilişkilendirilmiş.";
        } else if (e.code == 'network-request-failed') {
          msg = "İnternet bağlantınızı kontrol edin.";
        } else if (e.code != 'popup-closed-by-user' && e.code != 'canceled') {
          msg = "Apple giriş hatası: ${e.message ?? e.code}";
        }
        if (e.code != 'popup-closed-by-user' && e.code != 'canceled') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red[800]),
          );
        }
      }
    } catch (e) {
      final errStr = e.toString();
      if (!errStr.contains("canceled") && !errStr.contains("iptal")) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Apple ile giriş yapılamadı: $e"),
              backgroundColor: Colors.red[800],
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // E-Posta / Şifre Giriş veya Kayıt (Android / Fallback)
  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final nickname = _nicknameController.text.trim();
    final isLogin = _selectedTabIndex == 0;

    if (email.isEmpty || password.isEmpty || (!isLogin && nickname.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen tüm zorunlu alanları doldurun!"),
          backgroundColor: NeuColors.accentOrange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      MotoUser? user;
      if (isLogin) {
        user = await AuthService().signInWithEmail(email, password);
      } else {
        user = await AuthService().signUpWithEmail(email, password, nickname);
      }

      if (user != null) {
        _anaEkranaGec(user);
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Giriş işlemi başarısız!";
      if (e.code == 'user-not-found') msg = "Bu e-postaya ait kullanıcı bulunamadı.";
      if (e.code == 'wrong-password') msg = "Hatalı şifre girdiniz.";
      if (e.code == 'email-already-in-use') msg = "Bu e-posta zaten kullanımda.";
      if (e.code == 'weak-password') msg = "Şifreniz en az 6 karakter olmalıdır.";

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red[800]),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata oluştu: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeuColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. NEUMORPHIC LOGO & BAŞLIK
                Center(
                  child: NeuContainer(
                    width: 96,
                    height: 96,
                    borderRadius: 48,
                    depth: 6,
                    style: NeuStyle.raised,
                    color: NeuColors.surface,
                    child: const Center(
                      child: Icon(
                        Icons.two_wheeler,
                        size: 48,
                        color: NeuColors.accentOrange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'MotoConnect',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Motorcuların Sosyal & Canlı Radar Platformu',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: NeuColors.textSecondary),
                ),
                const SizedBox(height: 32),

                // 2. TEK TIKLA SOSYAL GİRİŞ ALANI (APPLE & GOOGLE)
                NeuContainer(
                  padding: const EdgeInsets.all(22),
                  borderRadius: 24,
                  depth: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Hızlı Giriş Yap",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Apple veya Google hesabınızla tek tıkla başlayın.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 20),

                      // Apple ile Giriş Butonu
                      NeuButton(
                        color: Colors.white,
                        textColor: Colors.black,
                        iconColor: Colors.black,
                        borderRadius: 16,
                        depth: 4,
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleAppleAuth,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.apple, color: Colors.black, size: 24),
                            SizedBox(width: 10),
                            Text(
                              "Apple ile Giriş Yap",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Google ile Giriş Butonu
                      NeuButton(
                        color: NeuColors.surfaceDark,
                        borderRadius: 16,
                        depth: 4,
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleGoogleAuth,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  "G",
                                  style: TextStyle(
                                    color: Color(0xFF4285F4),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Google ile Giriş Yap",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Neumorphic Ayırıcı Çizgi
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1.5,
                        color: NeuColors.lightShadow.withValues(alpha: 0.3),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.0),
                      child: Text(
                        "VEYA E-POSTA İLE",
                        style: TextStyle(
                          color: NeuColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1.5,
                        color: NeuColors.lightShadow.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                  // 2. Geleneksel E-Posta / Şifre Kartı
                  NeuContainer(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 24,
                    depth: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Giriş Yap / Kayıt Ol Sekme Değiştirici
                        NeuSegmentedTabs(
                          tabs: const ["Giriş Yap", "Kayıt Ol"],
                          selectedIndex: _selectedTabIndex,
                          onTabSelected: (idx) {
                            setState(() => _selectedTabIndex = idx);
                          },
                        ),
                        const SizedBox(height: 18),

                        // Kayıt Ol Modunda Nickname Alanı
                        if (_selectedTabIndex == 1) ...[
                          NeuTextField(
                            controller: _nicknameController,
                            labelText: "Sürücü Lakabı (Nickname)",
                            hintText: "Örn: GhostRider",
                            prefixIcon: Icons.person_outline,
                          ),
                          const SizedBox(height: 14),
                        ],

                        // E-Posta Alanı
                        NeuTextField(
                          controller: _emailController,
                          labelText: "E-Posta Adresi",
                          hintText: "surucu@motoconnect.app",
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),

                        // Şifre Alanı
                        NeuTextField(
                          controller: _passwordController,
                          labelText: "Şifre",
                          hintText: "••••••••",
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                        ),
                        const SizedBox(height: 22),

                        // Giriş / Kayıt Butonu
                        NeuButton(
                          isPrimary: true,
                          text: _selectedTabIndex == 0 ? "Giriş Yap 🏍️" : "Hesap Oluştur ve Gazla 🏁",
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _handleEmailAuth,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // 3. YASAL BİLGİ & GİZLİLİK LİNKLERİ
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => LegalDocsSheet.show(context, docType: LegalDocType.privacyPolicy),
                      child: const Text(
                        "Gizlilik Politikası",
                        style: TextStyle(color: NeuColors.textSecondary, fontSize: 11),
                      ),
                    ),
                    const Text("•", style: TextStyle(color: NeuColors.textMuted)),
                    TextButton(
                      onPressed: () => LegalDocsSheet.show(context, docType: LegalDocType.termsOfService),
                      child: const Text(
                        "Kullanım Şartları",
                        style: TextStyle(color: NeuColors.textSecondary, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
