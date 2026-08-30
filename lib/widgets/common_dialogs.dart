import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../screens/auth/login_screen.dart';
import '../main.dart';
import 'neumorphic_widgets.dart';

class CommonDialogs {
  /// Çıkış yapma onay diyaloğu
  static void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: NeuContainer(
          padding: const EdgeInsets.all(22),
          borderRadius: 22,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.logout, color: NeuColors.accentOrange, size: 24),
                  SizedBox(width: 10),
                  Text("Çıkış Yap", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                "Hesabından çıkış yapmak istediğine emin misin?",
                style: TextStyle(color: Colors.white70, fontSize: 13.5),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: NeuButton(
                      text: "İptal",
                      color: NeuColors.surfaceDark,
                      textColor: Colors.white60,
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeuButton(
                      text: "Çıkış Yap",
                      isPrimary: true,
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        navigatorKey.currentState?.pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                        FirebaseAuth.instance.signOut();
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

  /// Garaja yeni motor ekleme modal sayfası
  static void showAddMotorcycleSheet(
    BuildContext context, {
    required MotoUser user,
    required VoidCallback onAdded,
  }) {
    final brandController = TextEditingController();
    final modelController = TextEditingController();
    final ccController = TextEditingController();
    String selectedType = "Naked";

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
              borderColor: NeuColors.accentOrange.withValues(alpha: 0.4),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.two_wheeler, color: NeuColors.accentOrange, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'Yeni Motor Ekle',
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
                    const SizedBox(height: 18),

                    NeuTextField(
                      controller: brandController,
                      labelText: 'Marka',
                      hintText: 'Örn: Yamaha, Honda, Ducati',
                      prefixIcon: Icons.business,
                    ),
                    const SizedBox(height: 12),

                    NeuTextField(
                      controller: modelController,
                      labelText: 'Model',
                      hintText: 'Örn: MT-07, CBR650R',
                      prefixIcon: Icons.two_wheeler,
                    ),
                    const SizedBox(height: 12),

                    NeuTextField(
                      controller: ccController,
                      keyboardType: TextInputType.number,
                      labelText: 'Motor Hacmi cc',
                      hintText: 'Örn: 689',
                      prefixIcon: Icons.speed,
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      "Motor Tipi:",
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ["Naked", "Racing", "Enduro", "Cruiser", "Touring", "Scooter"].map((type) {
                        final isSelected = selectedType == type;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedType = type),
                          child: NeuContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            borderRadius: 12,
                            style: isSelected ? NeuStyle.sunken : NeuStyle.raised,
                            color: isSelected ? NeuColors.accentOrange.withValues(alpha: 0.2) : NeuColors.surface,
                            borderColor: isSelected ? NeuColors.accentOrange : Colors.white.withValues(alpha: 0.05),
                            borderWidth: isSelected ? 1.5 : 1,
                            child: Text(
                              type,
                              style: TextStyle(
                                color: isSelected ? NeuColors.accentOrange : Colors.white70,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 22),

                    NeuButton(
                      text: 'Garaja Ekle',
                      icon: Icons.check,
                      isPrimary: true,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      onPressed: () {
                        if (brandController.text.trim().isNotEmpty &&
                            modelController.text.trim().isNotEmpty) {
                          final newMotor = Motorcycle(
                            brand: brandController.text.trim(),
                            model: modelController.text.trim(),
                            engineCc: int.tryParse(ccController.text.trim()) ?? 0,
                            type: selectedType,
                          );
                          user.garage.add(newMotor);
                          FirestoreService().addMotorcycle(user.id, newMotor);
                          onAdded();
                          Navigator.pop(context);
                        }
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
}
