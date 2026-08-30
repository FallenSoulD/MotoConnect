import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'neumorphic_widgets.dart';

class GoogleAccountPickerSheet extends StatefulWidget {
  final Function(MotoUser) onAccountSelected;

  const GoogleAccountPickerSheet({
    super.key,
    required this.onAccountSelected,
  });

  static void show(BuildContext context, {required Function(MotoUser) onAccountSelected}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: GoogleAccountPickerSheet(onAccountSelected: onAccountSelected),
      ),
    );
  }

  @override
  State<GoogleAccountPickerSheet> createState() => _GoogleAccountPickerSheetState();
}

class _GoogleAccountPickerSheetState extends State<GoogleAccountPickerSheet> {
  bool _isLoading = false;

  Future<void> _handleDeviceGoogleLogin() async {
    final nav = Navigator.of(context);
    setState(() => _isLoading = true);

    try {
      final user = await AuthService().signInWithGoogle();

      if (user != null && mounted) {
        nav.pop();
        widget.onAccountSelected(user);
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Google ile giriş tamamlanamadı veya iptal edildi."),
            backgroundColor: NeuColors.surface,
          ),
        );
      }
    } catch (e) {
      debugPrint("Google Sign-In error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Google giriş hatası: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      width: 360,
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      depth: 6,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        "G",
                        style: TextStyle(
                          color: Color(0xFF4285F4),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Google",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            "Google ile Oturum Açın",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "MotoConnect uygulamasına devam etmek için Google hesabınızı kullanın.",
            style: TextStyle(color: Colors.white60, fontSize: 12.5),
          ),
          const SizedBox(height: 24),

          NeuButton(
            color: const Color(0xFF4285F4),
            textColor: Colors.white,
            borderRadius: 16,
            depth: 4,
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _handleDeviceGoogleLogin,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_circle, size: 22, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  "Google Hesabımla Bağlan",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          const Text(
            "MotoConnect ile devam etmek için Google, adınızı ve e-posta adresinizi güvenle paylaşır.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 10.5, height: 1.3),
          ),
        ],
      ),
    );
  }
}
