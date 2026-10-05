import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/neumorphic_widgets.dart';
import '../main_screen.dart';

class SetupProfileScreen extends StatefulWidget {
  final MotoUser user;

  const SetupProfileScreen({super.key, required this.user});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen bir sürücü lakabı belirleyin."),
          backgroundColor: NeuColors.accentOrange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      widget.user.nickname = nickname;
      await FirestoreService().updateUserProfile(widget.user);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainScreen(aktifKullanici: widget.user)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kaydedilirken hata oluştu: $e"),
          backgroundColor: Colors.red[800],
        ),
      );
      setState(() => _isLoading = false);
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
                // 1. İKON
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: NeuColors.surfaceLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: NeuColors.accentOrange.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: NeuColors.accentOrange.withValues(alpha: 0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.sports_motorsports,
                        size: 42,
                        color: NeuColors.accentOrange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // 2. BAŞLIK VE AÇIKLAMA
                const Text(
                  'MotoConnect\'e\nHoş Geldin! 🏍️',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Yollara çıkmadan önce diğer sürücülerin\nseni radarda tanıyabilmesi için\nbir lakap belirlemelisin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: NeuColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                
                // 3. FORM
                NeuContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      NeuTextField(
                        controller: _nicknameController,
                        labelText: "Sürücü Lakabı (Nickname)",
                        hintText: "Örn: GhostRider",
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 24),
                      NeuButton(
                        isPrimary: true,
                        text: "Kaydet ve Gazla 🏁",
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _saveProfile,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
