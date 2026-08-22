import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AppleAccountPickerSheet extends StatelessWidget {
  final Function(MotoUser) onAccountSelected;

  const AppleAccountPickerSheet({
    super.key,
    required this.onAccountSelected,
  });

  static Future<void> show(BuildContext context, {required Function(MotoUser) onAccountSelected}) async {
    try {
      final user = await AuthService().signInWithApple();
      if (user != null) {
        onAccountSelected(user);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Apple ile giriş hatası: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

