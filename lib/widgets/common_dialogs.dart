import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../screens/auth/login_screen.dart';
import '../main.dart';

class CommonDialogs {
  /// Çıkış yapma onay diyaloğu
  static void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.deepOrange),
            SizedBox(width: 10),
            Text("Çıkış Yap", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Hesabından çıkış yapmak istediğine emin misin?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("İptal", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
              FirebaseAuth.instance.signOut();
            },
            child: const Text("Çıkış Yap", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
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
                    const Row(
                      children: [
                        Icon(Icons.two_wheeler, color: Colors.deepOrange),
                        SizedBox(width: 10),
                        Text(
                          'Yeni Motor Ekle',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: brandController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Marka (Örn: Yamaha, Honda)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.deepOrange),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: modelController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Model (Örn: MT-07, CBR650R)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.deepOrange),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: ccController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Motor Hacmi cc (Örn: 689)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.deepOrange),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      dropdownColor: const Color(0xFF2A2A2A),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Motor Tipi',
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: "Naked", child: Text("Naked")),
                        DropdownMenuItem(value: "Racing", child: Text("Racing / Supersport")),
                        DropdownMenuItem(value: "Enduro", child: Text("Enduro / Adventure")),
                        DropdownMenuItem(value: "Cruiser", child: Text("Cruiser / Chopper")),
                        DropdownMenuItem(value: "Touring", child: Text("Touring")),
                        DropdownMenuItem(value: "Scooter", child: Text("Scooter / Maxi")),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
                        child: const Text(
                          'Garaja Ekle',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
}
