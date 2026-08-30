import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/admin_config.dart';
import 'screens/auth/auth_gate.dart';
import 'services/purchase_service.dart';
import 'services/firestore_service.dart';
import 'widgets/neumorphic_widgets.dart';

import 'services/ad_helper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await AdHelper.initialize();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  try {
    AdminConfig.init();
  } catch (e) {
    debugPrint("AdminConfig init error: $e");
  }
  
  // RevenueCat satın alımları ve abonelikleri yapılandır
  try {
    await PurchaseService().initRevenueCat();
  } catch (e) {
    debugPrint("RevenueCat init error: $e");
  }

  // Sahte botları ve eski mükerrer test hesaplarını kalıcı olarak temizle
  try {
    FirestoreService().purgeAllTestUsers();
  } catch (e) {
    debugPrint("Bot temizleme hatası: $e");
  }



  runApp(const MotoConnectApp());
}

class MotoConnectApp extends StatelessWidget {
  const MotoConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'MotoConnect',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: NeuColors.accentOrange,
        scaffoldBackgroundColor: NeuColors.background,
        colorScheme: const ColorScheme.dark(
          primary: NeuColors.accentOrange,
          secondary: NeuColors.accentAmber,
          surface: NeuColors.surface,
          error: NeuColors.accentRed,
        ),
        cardTheme: CardThemeData(
          color: NeuColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0x14FFFFFF), width: 1),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: NeuColors.surfaceDark,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: NeuColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0x18FFFFFF), width: 1),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: NeuColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          elevation: 8,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0x12FFFFFF),
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: NeuColors.surfaceLight,
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0x1AFFFFFF), width: 1),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const AuthGate(),
    );
  }
}